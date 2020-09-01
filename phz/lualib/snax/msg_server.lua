local skynet = require "skynet"
require "skynet.manager"
local gateserver = require "snax.gateserver"
local netpack = require "netpack"
local crypt = require "crypt"
local socketdriver = require "socketdriver"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

local server = {}
 
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local user_online = {}	-- username -> u
local handshake = {}	-- 需要握手的连接列表
local connection = {}	-- fd -> u
local pool_resize

function server.userid(username)
	-- base64(uid)@base64(server)#base64(subid)
	local uid, servername, subid = username:match "([^@]*)@([^#]*)#(.*)"
	return b64decode(uid), b64decode(subid), b64decode(servername)
end

function server.username(uid, subid, servername)
	return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
end

function server.logout(username)
	local u = user_online[username]
	user_online[username] = nil
	if u and u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(username, secret)
	assert(user_online[username] == nil)
	user_online[username] = {
		secret = secret,
		version = 0,
		index = 0,
		username = username,
		response = {},	-- response cache
	}
end

function server.ip(username)
	local u = user_online[username]
	if u and u.fd then
		return u.ip
	end
end

function server.poolResize()
	return pool_resize
end

function server.start(conf)
	local expired_number = conf.expired_number or 128

	local handler = {}

	local CMD = {
		login = assert(conf.login_handler),
		logout = assert(conf.logout_handler),
		kick = assert(conf.kick_handler),
	}

	-- 内部命令处理
	function handler.command(cmd, source, ...)
		local f = assert(CMD[cmd])
		return f(...)
	end

	-- 网关服务器open（打开监听）回调
	function handler.open(source, gateconf)
		local servername = assert(gateconf.servername)
		local netinfo = assert(gateconf.netinfo)
		pool_resize = gateconf.resize or 30
		return conf.register_handler(servername, netinfo)
	end

	-- 新连接到来回调
	function handler.connect(fd, addr)
		handshake[fd] = addr
		gateserver.openclient(fd)
	end

	-- 连接断开回调
	function handler.disconnect(fd)
		handshake[fd] = nil
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if conf.disconnect_handler then
				conf.disconnect_handler(c.username)
			end
		end
	end

	function handler.error(fd,msg)
		print("-------------------gggggggggggggggg------------socket error %d, %s", fd,msg)
		handler.disconnect(fd)
	end

	-- socket发生错误时回调
--	handler.error = handler.disconnect

	-- atomic , no yield
	local function do_auth(fd, message, addr)
		local username, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")
		local u = user_online[username]
		if u == nil then
			LOG_ERROR("%s do_auth 404", username)
			return 404
		end
		local idx = assert(tonumber(index))
		hmac = b64decode(hmac)

		if idx <= u.version then
			LOG_ERROR("%s do_auth 403", username)
			return 403
		end

		local text = string.format("%s:%s", username, index)
		local v = crypt.hmac64(crypt.hashkey(text), u.secret)
		if v ~= hmac then
			LOG_ERROR("%s do_auth 402", username)
			return 402
		end

		LOG_INFO("%s do_auth ok add to connection", username)

		u.version = idx
		u.fd = fd
		u.ip = addr
		connection[fd] = u
		-- 保存fd到agent
		if conf.connect_handler then
			conf.connect_handler(username, fd)
		end
	end

	local function auth(fd, addr, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, result = pcall(do_auth, fd, message, addr)
		if not ok then
			skynet.error(result)
			result = 401
		end

		local close = result ~= nil

		if result == nil then
			result = 200
		end

		socketdriver.send(fd, netpack.pack(string.pack(">I2", result)))
		--socketdriver.send(fd, string.pack(">I2", 3)..result)
		if close then
			gateserver.closeclient(fd)
		end
	end

	local request_handler = assert(conf.request_handler)

	-- u.response is a struct { return_fd , response, version, index }
	local function retire_response(u)
		if u.index >= expired_number * 2 then
			local max = 0
			local response = u.response
			for k,p in pairs(response) do
				if p[1] == nil then
					-- request complete, check expired
					if p[4] < expired_number then
						response[k] = nil
					else
						p[4] = p[4] - expired_number
						if p[4] > max then
							max = p[4]
						end
					end
				end
			end
			u.index = max + 1
		end
	end

	local function do_request(fd, message)
		-- message数据 [消息数据 + 4字节session + 12字节hmac]
		local u = assert(connection[fd], "invalid fd")
		-- 解析数据尾部的16字节session+base64(hmac)
		local tail_data = message:sub(-16)
		local session = tail_data:sub(1,4)
		local hmac = b64decode(tail_data:sub(5))
		local p = u.response[session]
		if p then
			-- session can be reuse in the same connection
			if p[3] == u.version then
				local last = u.response[session]
				u.response[session] = nil
				p = nil
				if last[2] == nil then
					local error_msg = string.format("Conflict session %s", crypt.hexencode(session))
					skynet.error(error_msg)
					error(error_msg)
				end
			end
		end

		if p == nil then
			p = { fd }
			u.response[session] = p
			local ret = nil
			local hmac_data = message:sub(1,-13)
			local v = crypt.hmac64(crypt.hashkey(hmac_data), u.secret)
			if v ~= hmac then
				LOG_ERROR("do_request hmac error")
				ret = string.pack(">I2", 400) .. session
			else
				message = message:sub(1,-17)
				local ok, result = pcall(conf.request_handler, u.username, message)
				ret = result or ""
				-- NOTICE: YIELD here, socket may close.
				if not ok then
					skynet.error(ret)
					ret = string.pack(">I2", 400) .. session
				else
					ret = ret .. session
				end
			end
			-- 带上校验码
			ret = ret..b64encode(crypt.hmac64(crypt.hashkey(ret), u.secret))

			p[2] = string.pack(">s2",ret)
			p[3] = u.version
			p[4] = u.index
		else
			-- update version/index, change return fd.
			-- resend response.
			p[1] = fd
			p[3] = u.version
			p[4] = u.index
			if p[2] == nil then
				-- already request, but response is not ready
				return
			end
		end
		u.index = u.index + 1
		-- the return fd is p[1] (fd may change by multi request) check connect
		fd = p[1]
		if connection[fd] then
			socketdriver.send(fd, p[2])
		end
		p[1] = nil
		retire_response(u)
	end

	local function request(fd, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, err = pcall(do_request, fd, message)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s : %s", err, message))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end

	-- socket消息到来时回调，新连接的第一条消息是握手消息
	function handler.message(fd, msg, sz)
		local addr = handshake[fd]
		if addr then
			auth(fd,addr,msg,sz)
			handshake[fd] = nil
		else
			request(fd, msg, sz)
		end
	end

	return gateserver.start(handler)
end

return server
