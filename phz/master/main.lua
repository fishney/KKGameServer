local skynet = require "skynet"
local cluster = require "cluster"

skynet.start(function()
	LOG_INFO("Server start")
	local nodename  = skynet.getenv("nodename")
    assert(nodename)
    
	local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")
	
	local name = skynet.getenv("mastername")
	cluster.open(name)

	skynet.uniqueservice("agentdesk")

	local mysqlpool = skynet.uniqueservice("mysqlpool")
	skynet.call(mysqlpool, "lua", "start")
	
	local redispool = skynet.newservice("redispool")
    skynet.call(redispool, "lua", "start")

	local mgrdesk = skynet.uniqueservice("mgrdesk")

	skynet.uniqueservice("servermgr")
		-- 中心节点玩家地址管理服务
	skynet.uniqueservice("agentmgr")
	-- 用户集合服务
	local userCenter = skynet.uniqueservice("userCenter")
	skynet.call(userCenter, "lua", "start")
	

	local servernode = skynet.uniqueservice("servernode", "true")
    local info={
        servername=nodename,
        tag="master",
        watchtaglist={"game","node"}
    }
    skynet.call(".servernode", "lua", "setMyInfo", info)

    skynet.uniqueservice("loginmaster")
	--
	
	skynet.exit()
end)
