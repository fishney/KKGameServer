local skynet = require "skynet"
local cluster = require "cluster"
local sharedata = require "sharedata"

local config = {
}


skynet.start(function()
    LOG_INFO("Server start")
    local ip = skynet.getenv "ip"
    assert(ip)
    local cport = tonumber(skynet.getenv("port"))
    assert(cport)
    local nodename  = skynet.getenv("nodename")
    assert(nodename)

    local debug_port = skynet.getenv("debug_port")

    -- 日志服务
    local log = skynet.uniqueservice("log")
    skynet.call(log, "lua", "start")

    if debug_port then 
        skynet.newservice("debug_console",debug_port)
    end

    local gate  = skynet.uniqueservice("wsgated")
    skynet.call(gate, "lua", "open" , {
        port = cport,
        maxclient  = tonumber(skynet.getenv("maxclient")) or 1024, -- 允许客户端最大连接数
        resize     = 30, -- agent扩容参数
        servername = nodename,
        netinfo    = ip..":"..cport
    })
    cluster.open(nodename)

        -- 数据库服务
    local mysqlpool = skynet.uniqueservice("mysqlpool")
    skynet.call(mysqlpool, "lua", "start")

    local redispool = skynet.newservice("redispool")
    skynet.call(redispool, "lua", "start")

    local servernode = skynet.uniqueservice("servernode", "true")
    local info = {
        servername = nodename,
        tag = "node",
        netinfo = ip..":"..cport,
        address = gate,
        onlinenum = 0,--在线人数
        watchtaglist = {"game"},
        watchlist = {nodename}, --监听自己的事件
    }
    skynet.call(".servernode", "lua", "setMyInfo", info)

    skynet.call(gate, "lua", "start_init", info)

    skynet.exit()
end)
