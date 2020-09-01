local skynet  = require "skynet"
local cluster = require "cluster"

local config = {
}

local user = {
}

local common = {
    --{ name = "d_account", key = "id", indexkey = "pid"},
}

skynet.start(function()
    LOG_INFO("Server start")
    -- 服务开启端口
    local cport = tonumber(skynet.getenv("port"))
    assert(cport)
    local nodename  = skynet.getenv("nodename")
    assert(nodename)

    print(os.date("%Y-%m-%d %H:%M:%S", os.time()), " start login server")

    local debug_port = skynet.getenv("debug_port")
    if debug_port then 
        skynet.newservice("debug_console",debug_port)
    end

    -- 日志服务
    local log = skynet.uniqueservice("log")
    skynet.call(log, "lua", "start")

    skynet.uniqueservice("wslogind")

    cluster.open(nodename)
    -- skynet.call(".login_master", "lua", "onstart")

    skynet.uniqueservice("webservice", cport)

    skynet.uniqueservice("accountdata")
        -- 数据库服务
    local mysqlpool = skynet.uniqueservice("mysqlpool")
    skynet.call(mysqlpool, "lua", "start")
    local redispool = skynet.newservice("redispool")
    skynet.call(redispool, "lua", "start")


    local servernode = skynet.uniqueservice("servernode", "true")
    local info={
        servername=nodename,
        tag="login",
        watchtaglist={""}
    }
    skynet.call(".servernode", "lua", "setMyInfo", info)
    
    --TODO 以后改成注册形式
    skynet.call(".login_master", "lua", "start_init")
    --skynet.uniqueservice("facebook") --facebook
    skynet.uniqueservice("wechat") --wechat

    skynet.exit()
end)
