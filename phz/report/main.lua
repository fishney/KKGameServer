local skynet = require "skynet"
local cluster = require "cluster"

skynet.start(function()
    LOG_INFO("Server start")

    local debug_port = skynet.getenv("debug_port")
    if debug_port then 
        skynet.newservice("debug_console",debug_port)
    end

    local log = skynet.uniqueservice("log")
    skynet.call(log, "lua", "start")
    
    local report_redispool = skynet.newservice("redispool","report_")
    skynet.call(report_redispool, "lua", "start")

    skynet.uniqueservice("report")
    
    cluster.open("report")

    skynet.exit()
end)
