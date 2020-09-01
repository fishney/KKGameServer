local skynet = require "skynet"
local cluster = require "cluster"


skynet.start(function()
	LOG_INFO("Server start")

	-- 日志服务
	local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")
	
	local name = skynet.getenv("gamename") or "game"
	cluster.open(name)

	-- 数据库服务
	local mysqlpool = skynet.uniqueservice("mysqlpool")
	skynet.call(mysqlpool, "lua", "start")
	
	local redispool = skynet.newservice("redispool")
    skynet.call(redispool, "lua", "start")


	--创建桌子agent
	local dsmgr = skynet.uniqueservice("dsmgr")
	skynet.call(dsmgr, "lua", "start")
	skynet.exit()
end)
