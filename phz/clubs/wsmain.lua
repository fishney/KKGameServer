local skynet = require "skynet"
local cluster = require "cluster"
local sharedata = require "sharedata"

skynet.start(function()
	LOG_INFO("Server start")

	-- 日志服务
	local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")
	
	local name = skynet.getenv("nodename") or "club"
	cluster.open(name)

	-- 数据库服务
	local mysqlpool = skynet.uniqueservice("mysqlpool")
	skynet.call(mysqlpool, "lua", "start")

	-- 俱乐部逻辑服务
	skynet.uniqueservice("clubsaction")

	-- 俱乐部管理服务
	local clubsmgr = skynet.uniqueservice("clubsmgr")
	skynet.call(clubsmgr, "lua", "start")
	skynet.exit()
end)
