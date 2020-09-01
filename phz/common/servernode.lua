--
-- Author: mz
-- Date: 2019-02-16
--1，保存本服的相关信息
--2，负责把本服信息注册到master
--3，负责发送心跳给master
--4，负责保存master对本服的监控
--5，处理master发过来的事件

local skynet  = require "skynet"
local snax    = require "snax"
local cluster = require "cluster"
local cjson   = require "cjson"
local queue = require "skynet.queue"
require "skynet.manager"
local CMD = {}
local serverinfo = {} --服务器信息
local eventtable = {} --事件列表
local status = PDEFINE.SERVER_STATUS.run --当前服务器状态
local isautorun = ... --是启动的时候服务器状态自动变成run
local infofun_table = {}--debug模式下info函数列表
local cs = queue() 

--设置自己的服务器信息
--@param info服务器信息
--[[
info={
    servername=xx,
    tag=xx,
    watchlist={xx,xx},--可以不传 监听的服务器列表(服务器名称)
    watchtaglist={xx,xx},--可以不传 监听的服务器tag列表(服务器tag)
    netinfo=xx,--可以不传
}
]]
function CMD.setMyInfo( info )
    LOG_DEBUG("CMD.setmyinfo info:", info)
    assert(info.servername)
    assert(info.tag)

    serverinfo = {}
    serverinfo = table.copy(info)
    status = PDEFINE.SERVER_STATUS.start
    LOG_DEBUG("CMD.setmyinfo serverinfo:", serverinfo)
end

--接收servermgr发过来的连接 不返回,直接挂机 如果返回出去了 servermgr会认为这个服务器关闭 会将服务器状态变成关服
function CMD.link()
    LOG_DEBUG("CMD.LINK")
    skynet.wait()
    status = PDEFINE.SERVER_STATUS.stop
    skynet.error("return from LINK")
    return 0
end

--执行注册到servermgr
function doreg()
    LOG_DEBUG("doreg serverinfo:", serverinfo)
    if table.empty(serverinfo) then
        skynet.timeout(200,doreg) --还没有数据 等2秒再试
        return
    end

    local isok = pcall(cluster.call, "master", ".servermgr", "registerServer", serverinfo)
    LOG_DEBUG("doreg isok:", isok, "serverinfo:", serverinfo)
    if not isok then
        skynet.timeout(200,doreg) --注册失败 等2秒再试
    else
        if isautorun then
            CMD.run()
        end
    end
end

--收到需要注册的通知
function CMD.reg2Master()
    LOG_DEBUG("CMD.reg2master delay 0.1s. serverinfo:", serverinfo)
    skynet.timeout(10,doreg)
end

--心跳
function CMD.heartBeat()
    -- local serverinfo = {}

    local isok = pcall(cluster.call, "master", ".servermgr", "heartBeat", serverinfo, status)
    -- LOG_DEBUG("heartbeat ok:", isok, "serverinfo:", serverinfo)
    skynet.timeout(200,CMD.heartBeat) --2秒一次同步
end

--修改服务器状态
--@param status_p 状态
function CMD.changeStatus(status_p)
    status = status_p
    pcall(cluster.call, "master", ".servermgr", "changeStatus", serverinfo.servername, status)
end

--服务器开始运行
function CMD.run()
    CMD.changeStatus(PDEFINE.SERVER_STATUS.run)
    skynet.timeout(200,CMD.heartBeat) --2秒一次同步
end

--刷新服务器信息 
--@param serverinfo_p 新的服务器信息
--@param callmaster true表示立即同步到master
function CMD.freshServerInfo( serverinfo_p, callmaster )
    serverinfo = serverinfo_p
    if callmaster then
        CMD.heartBeat()
    end
end

--注册事件回调函数
--@param event 事件
--@param fun 回调函数
--[[
fun:
{
    "method"=xx,--back的函数
    "address"=xx --服务地址
}
]]
function CMD.regEventFun( event, fun )
    assert(fun.address)
    assert(fun.method)
    LOG_DEBUG("reg_eventfun event:", event)
    if eventtable[event] == nil then
        eventtable[event] = {}
    end
    table.insert(eventtable[event], fun)
end

--servermgr事件通知
--@param server发生变化的服
--@param event发生的事件
--[[
server的结构
server = {
    name = xx,
    status = xx,
    tag = xx,
    freshtime = xx,
    netinfo = xx
}
]]
function CMD.serverEventCall( server, event )
    cs(
        function()
           LOG_DEBUG("server_eventcall server:", server, "event:", event, "eventtable:", eventtable)
            if eventtable[event] ~= nil then
                for _,fun in pairs(eventtable[event]) do
                    local isok = pcall( skynet.call, fun.address, "lua", fun.method, server )
                    LOG_DEBUG("server_eventcall server:", server, "event:", event, "isok:", isok, "fun:", fun)
                end
            end
        end
    )
end

--重新加载cluster配置
function CMD.reloadCluster(  )
    LOG_INFO("reloadCluster")
    local clusterpath = skynet.getenv("cluster")
    local cfg = load_config(clusterpath)
    cluster.reload(cfg)
end

--注册info的信息打印函数,一个服务地址 只允许注册一个函数
--@param fun 回调函数,回调函数返回一个字符串或者字符串的table
--[[
fun:
{
    "method"=xx,--back的函数
    "address"=xx --服务地址
}
]]
function CMD.regInfoFunction( fun )
    assert(fun.address)
    assert(fun.method)
    local slist = skynet.call(".launcher", "lua", "LIST")
    for k,v in pairs(slist) do
        if k == skynet.address(fun.address) then
            local isnext =false
            local servicename
            local addressinfo_table = string.split(v," ")
            for _,sname in ipairs(addressinfo_table) do
                if sname == "snlua" then
                    --一下个元素就是名字了
                    isnext = true
                else
                    if sname ~= "" then
                        if isnext then
                            servicename = sname
                            break
                        end
                    end
                end
            end
            fun.servicename = servicename
            break
        end
    end
    infofun_table[fun.address] = fun
end

--打印info信息
local function dump_info(filter, ...)
    LOG_INFO("dump_info filter:", filter, "param:", ...)
    local service_table = {}
    if filter ~= nil then
        service_table = string.split(filter, ',')
    end

    local info = {}
    for _,fun in pairs(infofun_table) do
        local iscall = true
        if filter == nil or filter == "all" then
            iscall = true
        else
            if checkInTable(service_table, fun.servicename) then
                iscall = true
            else
                iscall = false
            end
        end

        if iscall then
            table.insert(info, string.format("=========%s:%s=========", fun.servicename, fun.method))
            local isok,str = pcall( skynet.call, fun.address, "lua", fun.method, ... )
            if isok then
                table.insert(info, "====call success====")
                if str ~= nil then
                    if type(str) == "table" then
                        for k,v in pairs(str) do
                            if v ~= nil then
                                table.insert(info, v)
                            end
                        end
                    else
                        table.insert(info, str)
                    end
                end
            else
                table.insert(info, "====call fail====")
            end
            table.insert(info, "====call end====")
            table.insert(info, "\t\n")
        end
    end

    local ret = table.concat(info, "\t\n")
    return info
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)
    CMD.reg2Master()

    skynet.info_func(dump_info)

    skynet.register(".servernode")
end)