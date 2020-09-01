local skynet = require "skynet"
require "skynet.manager"
local socket = require "socket"
local crypt = require "crypt"
local table = table
local string = string
local assert = assert

local socket_error = {}
local function assert_socket(v, fd)
	if v then
		return v
	else
		LOG_ERROR(string.format("auth failed: socket (fd = %d) closed", fd))
		error(socket_error)
	end
end

local function write(fd, text)
	-- 每次write 2字节数据长度(大端编码) + 数据
	LOG_DEBUG("write text size=%d",#text)
	local package = string.pack(">s2", text)
	assert_socket(socket.write(fd, package), fd)
end

local function read(fd)
	-- 每次read 2字节数据长度(大端编码) + 数据
	local len = socket.read(fd, 2)
	local s = len:byte(1) * 256 + len:byte(2)
	local data = socket.read(fd, s)
	LOG_DEBUG("read text [%d/%d]",#data, s)
	return data:sub(1,s)
end

local function launch_slave(auth_handler)
	local function auth(fd, addr)
		fd = assert(tonumber(fd))
		LOG_INFO(string.format("connect from %s (fd = %d)", addr, fd))
		socket.start(fd)
		-- set socket buffer limit (8K)
		-- If the attacker send large package, close the socket
		socket.limit(fd, 8192)
		-- 1. S2C : base64(8bytes random challenge)随机串，用于后序的握手验证
		local challenge = crypt.randomkey()
		write(fd, crypt.base64encode(challenge))
		-- 2. C2S : base64(8bytes handshake client key)由客户端发送过来随机串，用于交换 secret 的 key
		local handshake = assert_socket(read(fd), fd)
		local clientkey = crypt.base64decode(handshake)
		if #clientkey ~= 8 then
			LOG_ERROR("Invalid client key")
			error "Invalid client key"
		end
		-- 3. S: Gen a 8bytes handshake server key生成一个用户交换 secret 的 key
		-- 4. S2C : base64(DH-Exchange(server key))利用 DH 密钥交换算法，发送交换过的 server key
		local serverkey = crypt.randomkey()
		write(fd, crypt.base64encode(crypt.dhexchange(serverkey)))
		-- 5. S/C secret := DH-Secret(client key/server key)服务器和客户端都可以计算出同一个 8 字节的 secret
		local secret = crypt.dhsecret(clientkey, serverkey)
		-- 6. C2S : base64(HMAC(challenge, secret))回应服务器第一步握手的挑战码，确认握手正常
		local response = assert_socket(read(fd), fd)
		local hmac = crypt.hmac64(challenge, secret)

		if hmac ~= crypt.base64decode(response) then
			write(fd, string.pack(">I2", 401))
			LOG_ERROR("challenge failed")
			error "challenge failed"
		end
		-- 7. C2S : DES(secret, base64(token))使用 DES 算法，以 secret 做 key 加密传输 token
		local etoken = assert_socket(read(fd),fd)
		local token = crypt.desdecode(secret, crypt.base64decode(etoken))
		-- 8. S : call auth_handler(token) -> server, uid
		local ok, server, uid, version, errorCode =  pcall(auth_handler,token)
		socket.abandon(fd)
		return ok, server, uid, secret, version, errorCode
	end

	local function ret_pack(ok, err, ...)
		if ok then
			skynet.ret(skynet.pack(err, ...))
		else
			if err == socket_error then
				skynet.ret(skynet.pack(nil, "socket error"))
			else
				skynet.ret(skynet.pack(false, err))
			end
		end
	end

	skynet.dispatch("lua", function(_,_,...)
		ret_pack(pcall(auth, ...))
	end)
end

local user_login = {}	-- key:uid value:true 表示玩家登录记录

local function accept(conf, s, fd, addr)
	-- call slave auth
	local ok, server, uid, secret, version, errorCode = skynet.call(s, "lua", fd, addr)
	socket.start(fd)
	if errorCode ~= 200 then
		write(fd, string.pack(">I2", errorCode))
		error(server)
	end

	if not ok then
		LOG_DEBUG("402 Unauthorized")
		write(fd, string.pack(">I2", 402))
		error(server)
	end

	if not uid then
		LOG_ERROR("auth failed")
		error("auth failed")
	end

	if not conf.multilogin then
		if user_login[uid] then
			write(fd, string.pack(">I2", 406))
			LOG_ERROR("406 Not Acceptable uid=%d", uid)
			error(string.format("User %s is already login", uid))
		end

		user_login[uid] = true
	end
	-- 9. S : call login_handler(server, uid, secret) ->subid，netinfo
	local ok, err, netinfo = pcall(conf.login_handler, server, uid, secret)
	-- unlock login
	user_login[uid] = nil

	if ok then
		err = err or ""
		-- 登录成功 err 是 subid
		local sql =  string.format("select name from tools where id = 2 ")
		local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
		local updataFlag = 0
		if #rs ~= 0 then
			if rs[1]["name"] ~= version then
				updataFlag = 1
			end
		end

		sql =  string.format("select name from tools where id = 3 ")
		rs = skynet.call(".mysqlpool", "lua", "execute", sql)
		local url = ""
		if #rs ~= 0 then
			url = rs[1]["name"]
		end

		write(fd,  string.pack(">I2", 200)..crypt.base64encode(uid..":"..err).."@"..crypt.base64encode(server).."#"..crypt.base64encode(netinfo).."#"..crypt.base64encode(updataFlag).."#"..crypt.base64encode(url).."#"..crypt.base64encode(addr))
	else
		write(fd,  string.pack(">I2", 405))
		LOG_DEBUG("405 Forbidden uid=%d", uid)
		error(err)
	end
end

local function launch_master(conf)
	local instance = conf.instance or 8
	assert(instance > 0)
	local host = conf.host or "0.0.0.0"
	local port = assert(tonumber(conf.port))
	local slave = {}
	local balance = 1

	skynet.dispatch("lua", function(_,source,command, ...)
		skynet.ret(skynet.pack(conf.command_handler(command, ...)))
	end)

	for i=1,instance do
		table.insert(slave, skynet.newservice(SERVICE_NAME))
	end

	skynet.error(string.format("login server listen at : %s %d", host, port))
	local id = socket.listen(host, port)
	socket.start(id , function(fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > #slave then
			balance = 1
		end
		local ok, err = pcall(accept, conf, s, fd, addr)
		if not ok then
			if err ~= socket_error then
				LOG_DEBUG(string.format("invalid client (fd = %d) error = %s", fd, err))
			end
			socket.start(fd)
		end
		socket.close(fd)
	end)
end

local function login(conf)
	local name = "." .. (conf.name or "login")
	skynet.start(function()
		local loginmaster = skynet.localname(name)
		if loginmaster then
			local auth_handler = assert(conf.auth_handler)
			launch_master = nil
			conf = nil
			launch_slave(auth_handler)
		else
			launch_slave = nil
			conf.auth_handler = nil
			assert(conf.login_handler)
			assert(conf.command_handler)
			skynet.register(name)
			launch_master(conf)
		end
	end)
end

return login
