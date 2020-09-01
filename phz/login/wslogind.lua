local login = require "snax.wslogin_server"
local crypt = require "crypt"
local skynet  = require "skynet"
local snax    = require "snax"
local cluster = require "cluster"
local cjson   = require "cjson"
local MsgParser = require("MsgParser")
local md5     = require "md5"
local TESTTING = false
local api_service = require "api_service"
local report_service = require "report_service"
local evo_service = require "evo_service"
local isbigbang = skynet.getenv("isbigbang")

local server = {
    host = "0.0.0.0",
    port = tonumber(skynet.getenv("port")),
    multilogin = false, -- disallow multilogin
    name = "login_master", --内部服务名.login_master
    instance = 8,
}

local APP = skynet.getenv("app") or 1
APP = tonumber(APP)


local user_online = {} -- 记录玩家所登录的服务器

--只支持用.隔开的4位版本号，例如 1.0.0.4
local function getVersionNum(version)
    local resultStrList = {}
    string.gsub(version,'[^.]+',function (w)
        table.insert(resultStrList,w)
    end)

    local vernum = 0
    for k, item in pairs(resultStrList) do
        if k == 1 then
            vernum = vernum + item * 100000000
        elseif k == 2 then
            vernum = vernum + item * 1000000
        elseif k == 3 then
            vernum = vernum + item * 10000
        elseif k == 4 then
            vernum = vernum + item * 100
        end
    end

    return vernum
end

local function checkVersion(v, keyprefix)
    local ok, res = pcall(cluster.call, "master", ".configmgr", "get", "version")
    if not ok then 
        return true
    end

    local dbvernum = getVersionNum(res.v)
    
    local version = string.gsub(v, "v", "")
    local clientvernum = getVersionNum(version)

    -- if dbvernum < clientvernum then 
    --     --服务端必须去更新
    --     local function t()
    --         pcall(api_service.callAPIMod, "reflush", keyprefix)
    --     end
    --     skynet.timeout(100, t)
    -- end
    -- if dbvernum > clientvernum then 
    --     return false
    -- end
    return true 
end
--[[
认证token并且返回登录的游戏服务地址和游戏内的玩家id
如果验证不能通过，可以通过 error 抛出异常。如果验证通过，需要返回用户希望进入的登陆点以及用户名。（登陆点可以是包含在token内由用户自行决定,也可以在这里实现一个负载均衡器来选择）
token包含sdk提供的用户标识user

400 Bad Request --握手失败
401 Unauthorized --自定义的 auth_handler 不认可 token
403 Forbidden --自定义的 login_handler 执行失败
406 Not Acceptable --该用户已经在登陆中。（只发生在 multilogin 关闭时）
]]
function server.auth_handler(token, addr)
    if TESTTING then
        token.user="7235-9319-5370"
        token.passwd="111111"
        token.t = "4"
    end
    print("-----token--------",token)
    --TODO 版本是否低了等, 是否必须重启
    local appversion = token.av or "" --app version
    local resversion = token.v or "" --resource version, 客户端版本低于此值会提示更新
    local channel = token.platform or "" -- iOS,Android,Windows,Marmalade,Linux,Bada,Blackberry,OS X
    if channel == 'iOS' or channel=='Android' then 
        if not checkVersion(resversion,  "res") then 
            return PDEFINE.RET.ERROR.RES_VERSION_ERR
        end
    end

    local code = token.code or ""
    local passwd = token.passwd or "Aa123456"
    local fbid = token.fbid or ""
    local onepasswd = token.onepasswd or ""
    local twopasswd = token.twopasswd or ""
    local nickname  = token.nickname or token.user
    local invituid  = token.valueid or 0
    local invitcode = token.invitcode or 0
    local sex = token.sex or math.random(0,1)
    sex = math.floor(sex)
    local appid     = token.appid or 0 --同个App下区分不同开发者账号，展示不同的苹果IAP内购商品使用
    appid = math.floor(appid)
    local client_uuid = token.client_uuid or "" --设备id
    local platform = 3 --其他web
    local login_token = token.token --玩家身上的token app=4使用
    local LoginExData = token.LoginExData
    local language = token.language --1：中文  2：英文
    local checkcode = token.checkcode
    local email  = token.email or "test@qq.com"

    if channel == "iOS" then
        platform = 2
    elseif channel == "Android" then
        platform = 1
    else
        LOG_INFO(token.user .. "玩家登录渠道未知:", channel)
    end

    local user, version, logintype = token.user, token.v, tonumber(token.t)
    if logintype == 10 or logintype == 11 then
        passwd = "Aa123456"
    end
    if user ~= nil then
        user = string.gsub(user, " ", "")
    end
    local accesstoken = token.accessToken or ""
    LOG_INFO(string.format("Auth_handler user %s version %s logintype %d token.client_uuid %s login_token %s", token.user, token.v, tonumber(token.t), token.client_uuid, login_token))
    local ip = ""
    if addr ~= nil then
        local addrarr = string.split(addr, ':')
        if #addrarr > 0 then
            ip = addrarr[1]
        end
    end

    local coin = nil
    local uid = nil
    local oldPasswd = nil
    local playername = user
    local usericon = math.random(1,10)
    local sex = math.random(0,1)
    local para = {
        login_token=login_token,
        client_uuid=client_uuid,
        ip=ip,
        account=user,
        passwd=passwd,
        logintype = logintype,
        otherpara = token,
        code = code,
        invitcode = invitcode,
        accesstoken = accesstoken,
        email = email,
    }
    local openId

    if logintype == 10 then
        local ok, access_token, openid = skynet.call(".wechat", "lua", "getAccessToken", accesstoken)
        if ok ~= 200 then
            LOG_ERROR("wechat get userinfo register account failed", user)
            return PDEFINE.RET.ERROR.ACCOUNT_HAD_EXIST
        end
        user = openid
        openId = openid
        local ok, userinfo = skynet.call(".wechat", "lua", "getUserInfo", access_token,openid)
        playername = userinfo.nickname
        usericon = userinfo.headimgurl
        sex = userinfo.sex
    end
    local isHave = false
    local sql = string.format("select * from d_account where user = '%s'",user)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
   print("--------------------rs-----------",rs)
    if #rs == 1 then
        isHave = true
        uid = rs[1].uid
        sql = string.format("select * from d_user where uid = %d",uid)
        rs = skynet.call(".mysqlpool", "lua", "execute", sql)
        coin = rs[1].coin
        oldPasswd  = rs[1].passwd
        playername = rs[1].playername
        usericon = rs[1].usericon
        sex      = rs[1].sex
    end
    if logintype == 9 then
        if not isHave then
            return PDEFINE.RET.ERROR.LOGIN_FAIL
        else
            sql = string.format("select * from s_user_code where user = '%s' and state = 0",user)
            rs = skynet.call(".mysqlpool", "lua", "execute", sql)
            if not rs or rs[1].code ~= code then
                return PDEFINE.RET.ERROR.INVAlID_CODE_FAIL --验证码错误
            end
            sql = string.format("update s_user_code set state = 1 where user = '%s' and code = '%s' ",user,code)
            rs = skynet.call(".mysqlpool", "lua", "execute", sql)
        end
    end

    --weixin_login
    if logintype == 10 then
        if not isHave then
            uid = getUid()
            local sql = string.format("insert into d_account( user,uid,type)  values ('%s',%d, 1)",user,uid)
            local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

            sql = string.format("insert into d_user( uid, coin, create_time, playername, usericon, red_envelope, passwd, roomcard, sex)  values (%d, %0.4f, %d, '%s','%s', %0.4f, '%s', %d, %d)", uid, 1000, os.time(), playername, usericon, 0, passwd, 20, sex)
            skynet.call(".mysqlpool", "lua", "execute", sql)
            coin = 1000
        end
    end
    if logintype == 11 then
        if not isHave then
            --return PDEFINE.RET.ERROR.ACCOUNT_HAD_EXIST
             uid = getUid()
            local sql = string.format("insert into d_account( user,uid,type)  values ('%s',%d, 2)",user,uid)
            local rs = skynet.call(".mysqlpool", "lua", "execute", sql)


            sql = string.format("insert into d_user( uid, coin, create_time, playername, usericon, red_envelope, roomcard, sex)  values (%d, %0.4f, %d, '%s','%s', %0.4f, %d, %d)", uid, 1000, os.time(), playername, usericon, 0, 20, sex)
            skynet.call(".mysqlpool", "lua", "execute", sql)
            coin = 1000
        end
    end
   
    if logintype == 14 then
        if not isHave then
            return PDEFINE.RET.ERROR.PASSWD_ERR
        else
            print("-------oldPasswd-------",oldPasswd)
            passwd = "Aa123456"
            if passwd ~= oldPasswd then
                return PDEFINE.RET.ERROR.PASSWD_ERR
            end
        end
    end
    
    local userinfo = {}
    userinfo.uid = uid
    userinfo.version = version
    userinfo.openid = openId
    userinfo.unionid = nil
    userinfo.playercoin = coin
    userinfo.access_token = accesstoken
    userinfo.language = language
    userinfo.client_uuid = client_uuid
    userinfo.account = user
    userinfo.ip = addr
    userinfo.vip = 0
    userinfo.checkcode = nil
    userinfo.playername = playername
    userinfo.usericon = usericon
    userinfo.sex = sex
    userinfo.passwd = passwd
    print("auth end ", userinfo)
    return PDEFINE.RET.SUCCESS, userinfo
end

--生成token
function genToken(uid, secret)
    local token = crypt.hashkey(uid .. ":" .. skynet.now() .. ":" .. secret)
    return crypt.hexencode(token)
end

--[[
 登录操作，通知具体游戏服，登录状态简单管理
 处理当用户已经验证通过后，该如何通知具体的登陆点（server ）。框架会交给你用户名（uid）和已经安全交换到的通讯密钥。你需要把它们交给登陆点，并得到确认（等待登陆点准备好后）才可以返回。
]]
function server.login_handler( secret, bwss, userinfo)
    LOG_DEBUG("login_handler userinfo:", userinfo)
    local uid = userinfo.uid
    local playercoin = userinfo.playercoin
    local access_token = userinfo.access_token
    local language = userinfo.language
    local clientid = userinfo.client_uuid
    local  vip = userinfo.vip

    --获取server
    --[[
    server={
            name=xx,
            status=xx,
            tag=xx,
            freshtime=xx，
            serverinfo = {
                "address":
                "netinfo":"xxx:xx"
            }
        }
    ]]
    local ok, errcode, server = pcall(cluster.call, "master", ".loginmaster", "balance", userinfo)
    if not ok then
        return PDEFINE.RET.ERROR.REGISTER_FAIL
    end
    if errcode ~= PDEFINE.RET.SUCCESS then
        return errcode
    end

    LOG_INFO(
        os.date("%Y-%m-%d %H:%M:%S", os.time()),
        string.format("login_handler %s@%s@%s is login, secret is %s", uid, server.name, server.serverinfo.address, crypt.hexencode(secret)))
    -- if server_list[server] == nil then
    --     return PDEFINE.RET.ERROR.SERVER_NOTREADY
    -- end
    -- local gameserver = assert(server_list[server], "Unknown server")
    -- local clientid = do_redis({"get", "client_uuid_"..uid})

    local last = user_online[uid]
    if last and last.clientuuid == clientid then
        --如果是一个设备 可以踢号
        -- LOG_ERROR("user %d is already online", uid, " kick kick kick", clientid)
        -- local ok = pcall(cluster.call, last.server, last.address, "kick", uid, last.subid, clientid.."")
        -- if ok then
        --     user_online[uid] = nil
        -- end
        -- LOG_INFO("kick uuid ", uid, " from cache:", clientid, 'user_online[uid]:', user_online[uid])
    end

    local token = ""
    token = access_token
    do_redis({"set", "t_"..token, uid})

    -- local ok, errcode, subid = pcall(cluster.call, server, gameserver, "login", uid, secret, token, clientid, playercoin)
    local ok, errcode, subid = pcall(cluster.call, server.name, server.serverinfo.address, "login", userinfo, secret)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),string.format("node login result %s, subid is %s", ok, subid))
    if not ok then
        LOG_ERROR(string.format("uid:%d login agent faield, %s, token:%s", uid, secret, token))
        return PDEFINE.RET.ERROR.CALL_FAIL
    end

    if errcode ~= PDEFINE.RET.SUCCESS then
        return errcode
    end

    if type(subid) == "string" then
        --肯定执行错误了
        LOG_ERROR(string.format("uid:%d login node faield, %s, token:%s, subid:%s", uid, secret, token, subid))
    else
        user_online[uid] = { address = server.serverinfo.address, subid = subid, server = server.name, clientuuid = clientid }
    end

    --wss处理
    local servernetinfo = server.serverinfo.netinfo
    if bwss == 1 then
        local tmpserver = string.split(servernetinfo, ':')
        servernetinfo = tmpserver[1]
    end
    
    local data = {}
    data.c = 1
    data.account = userinfo.account
    data.uid = uid
    data.subid = subid
    data.ip = userinfo.ip

    report_service.Report( PDEFINE.REPORTMOD.login_c1, data )
    LOG_INFO("login_handler subid:", subid, "servernetinfo:", servernetinfo, "server.name:", server.name)
    return PDEFINE.RET.SUCCESS, subid, servernetinfo, server.name
end

local CMD = {}

--检测玩家是否在线
function CMD.useronline( uid )
    LOG_INFO("user_online uid:", uid, "v:", user_online[uid])
    local last = user_online[uid]
    if last then
        return true
    else
        return false
    end
end

function CMD.logout(uid, subid)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),"uid:",uid, " node 服 通知 登录服要退出了 uid:", uid)
    local u = user_online[uid]
    if u then
        LOG_INFO(string.format("%s@%s is logout", uid, u.server))
        user_online[uid] = nil
    end
end

-- function CMD.getUid(user, sdkid)
--     if not account_dc then
--         account_dc = snax.uniqueservice("accountdc")
--     end
--     local account = account_dc.req.get(sdkid, user)
--     local uid = nil
--     if not table.empty(account) then
--         uid = account.id
--     end
--     return uid
-- end

function CMD.onserverchange( server )
    LOG_DEBUG("onserverchange server:",server)
    --[[
        server的结构
        server={
            name=xx,
            status=xx,
            tag=xx,
            freshtime=xx，
            serverinfo = {}
        }
    ]]
    if server.tag == "api" then
        --暂时没需求
    end
end

--系统启动完成后的通知
function CMD.start_init( ... )
    local callback = {}
    callback.method = "onserverchange"
    callback.address = skynet.self()

    skynet.call(".servernode", "lua", "regEventFun", PDEFINE.SERVER_EVENTS.changestatus, callback)
end


--实现command_handler，必须要实现，用来处理lua消息
function server.command_handler(command, ...)
    LOG_DEBUG("get command %s", command)
    local f = assert(CMD[command])
    return f(...)
end

login(server)