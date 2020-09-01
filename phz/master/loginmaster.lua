--
-- Author: mz
-- Date: 2019-02-16
-- 登录路由
local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local snax = require "snax"
local cjson   = require "cjson"
local CMD = {}
local APP = skynet.getenv("app") or 1
APP = tonumber(APP)

local shutdownflag    = true --停服标记
local server_balance = {} --每个服现在有哪些人
local game_swl --白名单

local balance_strategy = require "balance_strategy"

--玩家uid是否在维护白名单中
--@param uid 玩家uid
--@return true表示在白名单中  false不在白名单
local function isInWhiteList(uid)
    local result = false

    local filterList = string.split(game_swl, ',')
    for _, setuid in pairs(filterList) do
        if tonumber(setuid) == tonumber(uid) then
            result = true
            break
        end
    end
    return result
end

local function isInIpBlackList(ip)
    local result = false
    local strT = string.split(ip, ':')
    if strT then
        ip = strT[1]
        local balckIpList = do_redis({"get", "{bigbang}:system:banip:setting"})
        if balckIpList then
            local filterList = string.split(balckIpList, ',')
            for _, setip in pairs(filterList) do
                if setip == ip then
                    result = true
                    break
                end
            end
        end
    end
    return result
end


-- --注册节点
-- local function register_node(server)
--     server_list[server.name] = server.serverinfo.address
--     server_balance[server.name] = 0
--     server_netinfo[server.name] = server.serverinfo.netinfo
-- end

-- --关闭节点
-- local function close_node( server )
--     if server_list[server.name] ~= nil then
--         server_list[server.name] = nil
--     end
--     if server_balance[server.name] ~= nil then
--         server_balance[server.name] = nil
--     end
--     if server_netinfo[server.name] ~= nil then
--         server_netinfo[server.name] = nil
--     end
-- end

--维护所有服务器了
local function shutdown(  )
    shutdownflag = true
    pcall(skynet.call, ".userCenter", "lua", "changeLoginState", 2)
end

--打开所有服务器了
local function start(  )
    shutdownflag = false
    pcall(skynet.call, ".userCenter", "lua", "changeLoginState", 1)
end

--均衡运算
--@param userinfo 玩家信息
--[[
     local userinfo = {}
    userinfo.uid = uid
    userinfo.version = version
    userinfo.unionid = auth_info.unionid
    userinfo.playercoin = auth_info.playercoin
    userinfo.access_token = auth_info.access_token
    userinfo.language = language
    userinfo.client_uuid = client_uuid
    userinfo.account = auth_info.account
    userinfo.ip = addr
    userinfo.vip = auth_info.vip
]]
--@return 选中的code,server
function CMD.balance( userinfo )
    local uid = userinfo.uid
    LOG_DEBUG("loginmaster balance shutdownFlag:", shutdownflag, "userinfo:", userinfo, "game_swl:", game_swl)
    --是不是已停服
    if shutdownflag then
        if uid == nil or uid == -1 or not isInWhiteList(uid) then
            LOG_INFO("login is shutdown", uid)
            return PDEFINE.RET.ERROR.ERROR_GAME_FIXING --停服维护中
        end
    end
    if userinfo.ip then
        if isInIpBlackList(userinfo.ip) then
            LOG_INFO("login is userinfo.ip", userinfo.ip)
            return PDEFINE.RET.ERROR.ERROR_LOGIN --停服维护中
        end
    end
    local server
    local agent = skynet.call(".userCenter", "lua", "getAgent", uid)
    if agent ~= nil then
        --local cluster_info = { server = NODE_NAME, address = skynet.self()}
        LOG_DEBUG("loginmaster balance agent:", agent)
        local servername = agent.server
        server = skynet.call(".servermgr", "lua", "getServerByName", servername)
        if server == nil then
            --没有合适的服务器
            return PDEFINE.RET.ERROR.REGISTER_FAIL
        end
    else
        --暂时简单处理 直接去拿 以后如果master拿出去 看是否要改成通知模式
        local servertable = skynet.call(".servermgr", "lua", "getServerByTag", "node")
        server = balance_strategy.balance( userinfo,servertable )
        if server == nil then
            --没有合适的服务器
            return PDEFINE.RET.ERROR.REGISTER_FAIL
        end
    end

    return PDEFINE.RET.SUCCESS,server
end

--初始化状态 先将服务器状态变成关闭然后根据真实状态设置服务器是开启还是关闭
function CMD.initStatus( )
    -- --先不让服务启动
    -- shutdownflag = true

    -- local ok, game_switch, game_swl_p = pcall(cluster.call, "api", ".you9apisdk", "getgameswitch")
    -- LOG_DEBUG( "initstatus ok:", ok, " game_switch:", game_switch, " game_swl:", game_swl_p )
    -- if ok == false then
    --     --启动一个定时服务
    --     local function t()
    --         CMD.initStatus()
    --     end
    --     --1秒之后再请求一次
    --     skynet.timeout(100, t)
    --     return
    -- end

    -- game_swl = game_swl_p
    -- if tonumber(game_switch) == 0 then
    --     LOG_DEBUG("ready  shutdown")
    --     --关闭
    --     shutdown()
    -- else
    --     start()
    -- end
    shutdownflag = true
    start()
end

--节点修改回调
--@param server
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
local function onNodeChange( server )
    LOG_DEBUG("onnodechange start server:", server)
    if server.status == PDEFINE.SERVER_STATUS.stop or server.status == PDEFINE.SERVER_STATUS.weihu then
        -- close_node(server)
    else
        -- register_node(server)
    end

    LOG_DEBUG("onnodechange end server:", server)
end

--服务器修改回调
--@param server
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
function CMD.onServerChange( server )
    LOG_DEBUG("onserverchange server:",server)
    if server.tag == "node" then
        onNodeChange(server)
    end
end

--系统启动完成后的通知
function CMD.startInit(  )
    local callback = {}
    callback.method = "onServerChange"
    callback.address = skynet.self()

    skynet.call(".servernode", "lua", "regEventFun", PDEFINE.SERVER_EVENTS.changestatus, callback)
end

--api关服
--@param game_swl_p 白名单
function CMD.apiCloseServer( game_swl_p )
    shutdown()
    game_swl = game_swl_p
end

--api开服
--@param game_swl_p 白名单
function CMD.apiStartServer( game_swl_p )
    start()
    game_swl = game_swl_p
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)

    pcall(CMD.initStatus)

    skynet.register(".loginmaster")
end)
