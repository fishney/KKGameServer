local skynet = require "skynet"
require "skynet.manager"
local logger = require "log.core"

local cjson = require "cjson"

local log2redis = skynet.getenv('log2redis')
local is_logrelease = skynet.getenv('logrelease')

local LOGLEVEL = 
{
	["DEBUG"] = 0,
	["INFO"] = 1,
	["WARNNING"] = 2,
	["ERROR"] = 3,
	["FATAL"] = 4,
}

local log_basename = skynet.getenv("log_basename") or "test"

-- local queue = string.format("%s:%s","queue", "log")
local redis_queue = "queue:log:"..log_basename

local CMD = {}

function CMD.start()
	logger.init(tonumber(skynet.getenv("log_level")) or 0,
		tonumber(skynet.getenv("log_rollsize")) or 1024,
		tonumber(skynet.getenv("log_flushinterval")) or 5,
		skynet.getenv("log_dirname") or "log",
		skynet.getenv("log_basename") or "test")
end

function CMD.stop()
	logger.exit()
end

--将日志转换成json格式
--@param modname 日志打印的mod
--@param lev 日志等级
--@param msg 日志内容
--@return json数据
local function change2json( modname, lev, msg )
	local logtime = os.date("%Y-%m-%d %H:%M:%S")
	local log = {}
	log.time = logtime
	-- log.servername = log_basename
	log.modname = modname
	log.lev = lev
	log.msg = msg

	local json = cjson.encode(log)
	return json
end

local function push_redisqueue(modname, lev, msg)
	-- if lev < release_loglevel then
	-- 	return
	-- end
	if modname == nil or modname == "" then
		return
	end
	if msg == nil then
		return
	end
	local json = change2json(modname, lev, msg)
	do_redis_withprename("log_", {"rpush", redis_queue, json})
	-- do_redis({"rpush", redis_queue, json})
end

function CMD.debug(name, msg)
	if not is_logrelease then
		logger.debug(string.format("%s %s %s", os.date("%Y-%m-%d %H:%M:%S"), name, msg))
		return
	end
	if log2redis then
		push_redisqueue(name, LOGLEVEL.DEBUG, msg)
		return
	end
	local json = change2json(name, LOGLEVEL.DEBUG, msg)
	logger.debug(json)
end

function CMD.info(name, msg)
	if not is_logrelease then
		logger.info(string.format("%s %s %s", os.date("%Y-%m-%d %H:%M:%S"), name, msg))
		return
	end
	if log2redis then
		push_redisqueue(name, LOGLEVEL.INFO, msg)
		return
	end
	local json = change2json(name, LOGLEVEL.INFO, msg)
	logger.info(json)
end

function CMD.warning(name, msg)
	if not is_logrelease then
		logger.warning(string.format("%s %s %s", os.date("%Y-%m-%d %H:%M:%S"), name, msg))
		return
	end
	if log2redis then
		push_redisqueue(name, LOGLEVEL.WARNNING, msg)
		return
	end
	local json = change2json(name, LOGLEVEL.WARNNING, msg)
	logger.warning(json)
end

function CMD.error(name, msg)
	if not is_logrelease then
		logger.error(string.format("%s %s %s", os.date("%Y-%m-%d %H:%M:%S"), name, msg))
		return
	end
	if log2redis then
		push_redisqueue(name, LOGLEVEL.ERROR, msg)
		return
	end
	local json = change2json(name, LOGLEVEL.ERROR, msg)
	logger.error(json)
end

function CMD.fatal(name, msg)
	if not is_logrelease then
		logger.fatal(string.format("%s %s %s", os.date("%Y-%m-%d %H:%M:%S"), name, msg))
		return
	end
	if log2redis then
		push_redisqueue(name, LOGLEVEL.FATAL, msg)
		return
	end
	local json = change2json(name, LOGLEVEL.FATAL, msg)
	logger.fatal(json)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		if cmd == "start" or cmd == "stop" then
			skynet.retpack(f(...))
		else
			f(...)
		end
	end)

	--如果是release 启动log的redis连接
	if log2redis then
		local log_redispool = skynet.newservice("redispool","log_")
    	skynet.call(log_redispool, "lua", "start")
	end

	skynet.register("."..SERVICE_NAME)
end)
