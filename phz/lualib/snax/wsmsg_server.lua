local skynet = require "skynet"
require "skynet.manager"
local gateserver = require "snax.wsgateserver"
local netpack = require "netpack"
local crypt = require "crypt"
local cjson = require "cjson"

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
    --print("uid= ",uid,"subid= ",subid, "servername= ",servername)
    return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
end

function server.logout(username)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time())," node server.logout User logout haha:", username, "即将关闭 fd")
    local u = user_online[username]

    user_online[username] = nil
    if u and u.fd then
        gateserver.closeclient(u.fd)
        connection[u.fd] = nil
    end
end

function server.login(username, secret, token)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time())," node server.login:", username, secret, token)
    assert(user_online[username] == nil)
    user_online[username] = {
        secret = secret,
        version = 0,
        index = 0,
        username = username,
        token = token, --自己加的token
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
        brodcast = assert(conf.brodcast_handler),
        resetloginstarttime = assert(conf.resetloginstarttime),
        start_init = assert(conf.start_init),
        onserverchange = assert(conf.onserverchange),
        otherhandler = assert(conf.otherhandler),
        --deskback = assert(conf.deskback_handler), --回收桌子
    }

    -- 内部命令处理
    function handler.command(cmd, source, ...)
        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " handler.command cmd", cmd)
        local f = CMD[cmd]
        if f == nil then
            return CMD["otherhandler"](cmd, ...)
        else
            return f(...)
        end
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
        print(os.date("%Y-%m-%d %H:%M:%S", os.time()), "-------------------gggggggggggggggg------------socket error %d, %s", fd,msg)
        handler.disconnect(fd)
    end

    -- atomic , no yield
    local function do_auth(fd, message, addr)
        --print("登录授权：", message)
        if nil == message.subid then
            LOG_ERROR("%s do_auth 401")
            return 404
        end
        local username = server.username(math.floor(message.uid), math.floor(message.subid), message.server)

        local token = message.token

        local u = user_online[username]
        if u == nil then
            LOG_ERROR("%s do_auth 404", username)
            return 404
        end

        if nil == u.token or u.token ~= token then
            LOG_ERROR("%s do_auth 402", username)
            return 402
        end

        LOG_INFO("%s do_auth ok add to connection", username)

        u.version = 1
        u.fd = fd
        u.ip = addr
        connection[fd] = u
        -- 保存fd到agent
        if conf.connect_handler then
            conf.connect_handler(username, fd)
        end
    end

    local function auth(fd, addr, message)
        local msg = cjson.decode(message)
        local ok, result = pcall(do_auth, fd, msg, addr)
        if not ok then
            skynet.error(result)
            result = 401
        end

        if result == nil then
            result = 200
        end
    end

    local function do_request(fd, message)
        LOG_DEBUG(" wsmsg_server do_request ", fd, " message:", message)
        local u = assert(connection[fd], "invalid fd")
        local ok, result = pcall(conf.request_handler, u.username, message)
        local ret = result or "" --result是个json str
        if not ok then
            skynet.error(ret)
            local msgobj = cjson.decode(message)
            ret = cjson.encode({c=msgobj.c, code= 400})
        end

        if connection[fd] then
            gateserver.send_msg(fd, ret)
        end
    end

    local function request(fd, message_in_json)
        local msgobj = cjson.decode(message_in_json)
        if nil == msgobj.c then
            LOG_ERROR("What's the fuck ?", message_in_json)
            return
        end

        local ok, err = pcall(do_request, fd, message_in_json)
        -- not atomic, may yield
        if not ok then
            skynet.error(string.format("Invalid package %s : %s", err, message_in_json))
            local ret = cjson.encode({c=msgobj.c, code= PDEFINE.RET.ERROR.CALL_FAIL})
            gateserver.send_msg(fd, ret)
            --if connection[fd] then
            gateserver.closeclient(fd)
            --end
        end
    end

    -- socket消息到来时回调，新连接的第一条消息是握手消息
    function handler.message(fd, msg, sz)
        local message1 = netpack.tostring(msg, sz)
        if #message1 < 9 then
            return
        end
        local jsonstr = pack_decode(message1)

        local addr = handshake[fd]
        if addr then
            auth(fd,addr,jsonstr)
            handshake[fd] = nil
            request(fd, jsonstr)
        else
            request(fd, jsonstr)
        end
    end

    return gateserver.start(handler)
end

return server
