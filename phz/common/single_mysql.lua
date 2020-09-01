local skynet = require "skynet"
require "skynet.manager"
local mysql = require "mysql"

local CMD = {}
local connect = nil

function CMD.start(config)
	if connect then return end
	local function on_connect(db)
		db:query("set charset utf8");
	end
	connect = mysql.connect({
		host = config.host,
		port = config.port,
		database = config.database,
		user = config.user,
		password = config.password,
		max_packet_size = 1024 * 1024,
		on_connect = on_connect
	})
	if connect then
		skynet.register("."..config.servicename)
	else
		skynet.error("mysql connect error")
	end
end

function CMD.execute(sql)
	return connect:query(sql)
end

function CMD.stop()
	connect:disconnect()
	connect = nil
end

function CMD.keepalive()
	connect:query("select 1")
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)
end)
