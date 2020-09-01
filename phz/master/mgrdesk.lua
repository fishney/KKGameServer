local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"

local CMD = {}
-- 管理玩家所在节点信息
local dsmgr = {}

function CMD.joinDsmgr(dsmgrname)
	dsmgr[dsmgrname] = {}
end

--负载均衡取出一个房间服务的名字
function CMD.getGameName()
	for gamename,gameVlue in pairs(dsmgr) do
		if #gameVlue < 200 then
			return gamename
		end
	end
end


skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		print("-----cmd-------",cmd)
		local f = CMD[cmd]
		skynet.retpack(f(...))
	end)
	skynet.register(".mgrdesk")
end)
