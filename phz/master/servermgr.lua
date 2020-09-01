--
-- Author: mz
-- Date: 2019-02-16
-- 服务器管理
local skynet  = require "skynet"
local snax    = require "snax"
local cluster = require "cluster"
local cjson   = require "cjson"
local queue = require "skynet.queue"
require "skynet.manager"
local CMD = {}
local ServerList = {} --服务器列表 服务器名字为建值
local WatchServer_Table = {} --关注列表 设置我关注哪些服务器的动态
local WatchTag_Table = {} --关注列表 设置我关注哪些tag服务器的动态
local SERVER_TIMEOUT = 5 --超时时间
local SERVER_STATUS = PDEFINE.SERVER_STATUS --服务器状态定义
local SERVER_EVENTS =PDEFINE.SERVER_EVENTS --服务器事件定义
local oldclustercfg = nil --之前的cluster配置
local cs = queue() 

--事件通知
--@param server 变化的服务器
--@param event 事件类型
local function notifyWatcher( server,event )
    LOG_INFO("notifyWatcher server:", server, "event:", event, "WatchServer_Table:", WatchServer_Table, "WatchTag_Table:", WatchTag_Table)
    --sname重新注册了
    local notify_server = {} --暂时不去重复 按名字设置关心的和按tag设置的应该不会重复
    for k,v in pairs(WatchServer_Table) do
        for _,m in pairs(v) do
            if m == server.name then
                table.insert(notify_server,k)
                break
            end
        end
    end

    for k,v in pairs(WatchTag_Table) do
        for _,m in pairs(v) do
            if m == server.tag then
                table.insert(notify_server,k)
                break
            end
        end
    end
    
    LOG_INFO("notifyWatcher notify_server:", notify_server)
    for _,v in pairs(notify_server) do
        local servercall = ServerList[v]
        if servercall ~= nil and servercall.status < SERVER_STATUS.stop then
            local isok = pcall(cluster.call, servercall.name, ".servernode", "serverEventCall", server, event)
            LOG_INFO("notifyWatcher notify_server isok:", isok, "servercall:", servercall, "server:", server, "event:", event)
        end
    end
end

--重新加载cluster
local function reloadCluster( ... )
    LOG_INFO("reloadCluster")
    local clusterpath = skynet.getenv("cluster")
    local cfg = load_config(clusterpath)
    cluster.reload(cfg)

    --通知大家都重新加载一下
    oldclustercfg = cfg
    LOG_INFO("notifyAllreloadcluster cfg:", cfg, "clusterpath:", clusterpath)
    for nodename,netinfo in pairs(cfg) do
        if nodename ~= "master" then
            pcall(cluster.call, nodename, ".servernode", "reloadCluster")
        end
    end
end

--服务器关闭
--@param servername 服务器名称
local function shutdownServer( servername )
    LOG_DEBUG("shutdown_server servername:", servername, "ServerList:", ServerList)
    if ServerList[servername] == nil then
        LOG_DEBUG("shutdown_server server nil servername:", servername, "ServerList:", ServerList)
        return
    end
    if ServerList[servername].status == SERVER_STATUS.stop then
        --已经关了的
        LOG_DEBUG("shutdown_server server stoped servername:", servername, "ServerList:", ServerList)
        return
    end
    ServerList[servername].status = SERVER_STATUS.stop
    notifyWatcher(ServerList[servername], SERVER_EVENTS.stop)
    notifyWatcher(ServerList[servername], SERVER_EVENTS.changestatus)

    ServerList[servername] = nil
    LOG_INFO("shutdown_server server %s", servername)
end

--指定修改一些服务器的状态 master不能在这里维护
--@param servers 指定维护的服务器
--@param status 修改的服务器状态
--@return PDEFINE.RET.SUCCESS
function CMD.apiChangeStatus( servers, status )
    LOG_DEBUG("apiChangeStatus servers:", servers, "status:", status)
    for _,servername in pairs(servers) do
        if servername == "master" then
            LOG_INFO("weihuserver error,servername is master")
        else
            local serverinfo = ServerList[servername]
            LOG_DEBUG("apiChangeStatus servername:", servername, "serverinfo:", serverinfo)
            if serverinfo ~= nil then
                pcall(cluster.send, servername, ".servernode", "changeStatus", status)
            end
        end
    end
    return PDEFINE.RET.SUCCESS
end

--api关整个服
--@param game_swl 白名单
function CMD.apiCloseServer( game_swl,game_swl_content )
    --不让登录了
    pcall(skynet.call, ".loginmaster", "lua", "apiCloseServer", game_swl)
    --关闭
    pcall(skynet.call, ".mgrdesk", "lua", "apiCloseServer",game_swl_content)
    --T人下线
    pcall(skynet.call, ".userCenter", "lua", "ApiPushAll2Login",game_swl_content)
end

--api开服
--@param game_swl 白名单
function CMD.apiStartServer( game_swl )
    pcall(skynet.call, ".loginmaster", "lua", "apiStartServer", game_swl)
    pcall(skynet.call, ".mgrdesk", "lua", "apiStartServer")
end

--获取服务器列表
--@return 服务器列表
--[[
            serverlist = 
            {
                "node1"={
                    "name" = "node1"
                    "status" = xx
                    "tag" = xxx
                    "freshtime" = xxxx
                    "serverinfo" = serverinfo
                }
            }
        ]]
function CMD.getServerList()
    return table.copy(ServerList)
end

--根据指定tag获取服务器列表
--@param tag 指定tag
--@return 服务器列表
function CMD.getServerByTag( tag )
    local servers = {}
    for servername,servertable in pairs(ServerList) do
        if servertable.tag == tag then
            table.insert(servers, servertable)
        end
    end
    return servers
end

--根据名字拿server
--@param sname 服务器名字
--@return server
--[[
    {
        "name" = "node1"
        "status" = xx
        "tag" = xxx
        "freshtime" = xxxx
        "serverinfo" = serverinfo
    }
]]
function CMD.getServerByName( sname )
    return ServerList[sname]
end

--注册服务器,会填充关注列表。如果服务器是之前cluster配置里面没有的会触发cluster的重新加载，最后会保持与serverinfo服务的一个连接
--@param serverinfo 服务器信息 必须包含 servername,tag属性
function CMD.registerServer( serverinfo )
    LOG_INFO("register_server start serverinfo:", serverinfo, "ServerList:", ServerList)
    assert(serverinfo.servername)
    assert(serverinfo.tag)

    if ServerList[serverinfo.servername] ~= nil then
        --先触发关服事件
        shutdownServer(serverinfo.servername)
    end

    local servertable = {}
    servertable.name = serverinfo.servername
    servertable.status = SERVER_STATUS.start
    servertable.tag = serverinfo.tag
    servertable.freshtime = os.time()
    servertable.serverinfo = serverinfo
    ServerList[serverinfo.servername] = servertable

    --触发启动事件
    notifyWatcher(servertable, SERVER_EVENTS.start)
    --设置关注列表
    CMD.setMyWatch( serverinfo.servername, serverinfo.watchlist, serverinfo.watchtaglist )

    LOG_INFO("register_server end serverinfo:", serverinfo, "ServerList:", ServerList)

    --告诉自己server自己关注的那些服务器状态变化了
    local seachtable = CMD.getMyWatchServer(serverinfo.servername)
    if seachtable ~= nil then
        for _,server in pairs(seachtable) do
            pcall(cluster.call, serverinfo.servername, ".servernode", "serverEventCall", server, SERVER_EVENTS.changestatus)
        end
    end

    --检测是否触发cluster的重新加载
    if oldclustercfg ~= nil then
        local clusterpath = skynet.getenv("cluster")
        local cfg = load_config(clusterpath)
        local isnewnode = false
        for sname,v in pairs(cfg) do
            if oldclustercfg[sname] == nil then
                --有新节点加入
                isnewnode = true
                break
            end
        end
        if isnewnode then
            reloadCluster()
        end
    end

    -- skynet.fork(CMD.setLink,serverinfo.servername)
    
end

--建立连接 实质上是发一个消息给对应的服务器 并且协定好对方一直挂起这个协议，如果这边收到了返回说明对方服务器出问题了，会触发关服
--@param servername 建立连接的对端服务器名字
-- function CMD.setLink(servername)
--     LOG_INFO("hold the server", servername)
--     pcall(cluster.call, servername, ".servernode", "link")
--     LOG_ERROR("disconnect the server", servername)
--     CMD.shutdownServer(servername)
-- end

--心跳 会检测服务器状态是否发生变化 如果发生变化会通知相关的服务器.之后更新最新的服务器信息
--@param serverinfo 服务器最新信息
--@status 服务器当前状态
function CMD.heartBeat(serverinfo, status)
    -- LOG_DEBUG("heartbeat serverinfo:", serverinfo)
    local server = ServerList[serverinfo.servername]
    if server == nil then
        LOG_WARNING("heartbeat servernil server:", serverinfo, "status:", status)
        --重新挂起来
        pcall(cluster.call, serverinfo.servername, ".servernode", "reg2Master")
        return
    end

    -- LOG_DEBUG("heartbeat serverinfo:", serverinfo, "status:", status, "server:", server)
    server.freshtime = os.time()

    if server.status == SERVER_STATUS.stop and status < SERVER_STATUS.stop then
        server.status = SERVER_STATUS.start
        notifyWatcher(server, SERVER_EVENTS.start)
    end
    if server.status ~= status then
        server.status = status
        notifyWatcher(server, SERVER_EVENTS.changestatus)
    end

    --更新最新的服务器信息
    ServerList[serverinfo.servername].serverinfo = serverinfo
end

--修改服务器状态
--@param servername 服务器名称
--@param status 状态
function CMD.changeStatus(servername,status)
    LOG_DEBUG("changestatus servername:", servername, "status:", status, "ServerList:", ServerList)
    if status == SERVER_STATUS.stop then
        shutdownServer( servername )
        return
    end
    local server = ServerList[servername]
    if server == nil then
        LOG_DEBUG("changestatus server nil servername:", servername, "status:", status, "ServerList:", ServerList)
        return
    end
    if server.status ~= status then
        server.status = status
        notifyWatcher(server, SERVER_EVENTS.changestatus)
    end
end


--设置我关心的服务器列表
--@param myserver_name 服务器名称
--@param watchlist 关注的服务器列表(服务器名称)
--@param watchtaglist 关注的服务器列表(服务器tag)
function CMD.setMyWatch( myserver_name, watchlist, watchtaglist )
    LOG_DEBUG("setmywatch myserver_name:", myserver_name, "watchlist:", watchlist, "watchtaglist:", watchtaglist)
    if watchlist ~= nil then
        WatchServer_Table[myserver_name] = watchlist
    end
    if watchtaglist ~= nil then
        WatchTag_Table[myserver_name] = watchtaglist
    end
end

--获取我关心的列表
--@param myserver_name 我的服务器名字
--@return 服务器列表
--[[
{
    [1]={
        "name" = "node1"
        "status" = xx
        "tag" = xxx
        "freshtime" = xxxx
        "serverinfo" = serverinfo
    }
}
]]
function CMD.getMyWatchServer(myserver_name)
    LOG_INFO("get_mywatchserver myserver_name:", myserver_name, "ServerList:", ServerList, "WatchServer_Table:", WatchServer_Table, "WatchTag_Table:", WatchTag_Table)
    local seachtable = {}
    if WatchServer_Table[myserver_name] ~= nil then
        for k,v in pairs(WatchServer_Table[myserver_name]) do
            if ServerList[v] ~= nil then
                table.insert(seachtable,ServerList[v])
            end
        end
    end

    if WatchTag_Table[myserver_name] ~= nil then
        for _,tag in pairs(WatchTag_Table[myserver_name]) do
            for _,v in pairs(ServerList) do
                if v.tag == tag then
                    table.insert(seachtable,v)
                end
            end
        end
    end
    return seachtable
end

--通知所有节点来注册
function notifyAllReg( )
    LOG_INFO("notifyAllReg")
    local clusterpath = skynet.getenv("cluster")
    local cfg = load_config(clusterpath)
    oldclustercfg = cfg
    LOG_INFO("notifyAllReg cfg:", cfg, "clusterpath:", clusterpath)
    for nodename,netinfo in pairs(cfg) do
        if nodename ~= "master" then
            pcall(cluster.call, nodename, ".servernode", "reg2Master")
        end
    end
end

--超时判断
--@param server 需要判断的server
--@return true超时 false没超时
function timeout( server )
    if server.status == SERVER_STATUS.stop then
        --已经关了的 不算超时了
        return false
    end
    if server.freshtime + SERVER_TIMEOUT < os.time() then
        LOG_INFO("timeout server:", server)
        --超时了
        return true
    end
    return false
end

--检测超时 1S一次
function update( ... )
    -- LOG_DEBUG("servermgrupdate", os.time())
    local timeout_server = {}
    for k,server in pairs(ServerList) do
        if timeout(server) then
            table.insert(timeout_server,server)
        end
    end

    for k,server in pairs(timeout_server) do
        pcall( shutdownServer, server.name )
    end
    -- LOG_DEBUG("servermgrupdate settimeout", os.time())
    skynet.timeout(100, update)
end

skynet.start(function()
    skynet.dispatch("lua", 
        function(session, address, cmd, ...)
            -- print("servermgr call cmd:", cmd)
            local param = {...}
            local ret 
            -- cs(
            --     function()
                    local f = CMD[cmd]
                    if f then
                        ret = {f(table.unpack(param))}
                    end
                --end
            -- )
            skynet.retpack(table.unpack(ret))
        end
    )

    --通知所有节点进行注册
    notifyAllReg()
    skynet.fork(update)
    skynet.register(".servermgr")
end)