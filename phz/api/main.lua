local skynet = require "skynet"
local cluster = require "cluster"

skynet.start(function()
    LOG_INFO("Server start")
    local nodename = skynet.getenv("nodename")
    assert(nodename)
    
    local log = skynet.uniqueservice("log")
    skynet.call(log, "lua", "start")
    cluster.open(nodename)
    local mysqlpool = skynet.uniqueservice("mysqlpool")
    skynet.call(mysqlpool, "lua", "start")

    skynet.uniqueservice("apiweb")

    skynet.exit()
end)