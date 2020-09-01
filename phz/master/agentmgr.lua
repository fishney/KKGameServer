local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"

local CMD = {}
-- 管理玩家所在节点信息
local client_agents = {}

function CMD.joinPlayer(cluster_info, uid)
	client_agents[uid] = cluster_info;
end

function CMD.removePlayer(uid)
	client_agents[uid] = nil
end

function CMD.getPlayer(uid)
	return client_agents[uid]
end

function CMD.getAllAgent()
	return client_agents
end

function CMD.callAgentFun(uid, fun, ...)
	local client_agent = assert(client_agents[uid])
	if client_agent then
		return cluster.call(client_agent.server, client_agent.address, fun, ...)
	end
	return nil
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.retpack(f(...))
	end)
	skynet.register(".agentmgr")
end)
