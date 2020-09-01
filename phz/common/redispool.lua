local skynet = require "skynet"
require "skynet.manager"
local redis = require "redis"

local ENV = skynet.getenv("env") or "test"

local CMD = {}
local pool = {}
local redis_prename = ... or ""

local maxconn
local function getconn(uid)
	local db
	if not uid or maxconn == 1 then
		db = pool[1]
	else
		db = pool[uid % (maxconn - 1) + 2]
	end
	return db
end

function CMD.start()
	maxconn = tonumber(skynet.getenv(redis_prename.."redis_maxinst")) or 2
	local host
	local port
	local auth
	host = skynet.getenv(redis_prename.."redis_host1")
	port = skynet.getenv(redis_prename.."redis_port1")
	auth = skynet.getenv(redis_prename.."redis_auth1")
	for i = 1, maxconn do

		local db = nil
		if ENV == "prod" then
			db = redis.connect{
				host = skynet.getenv(redis_prename.."redis_host" .. i),
				port = skynet.getenv(redis_prename.."redis_port" .. i),
				db = skynet.getenv(redis_prename.."redis_db" .. i),
				-- auth = skynet.getenv(redis_prename.."redis_auth" .. i),
			}
		else 
			db = redis.connect{
				host = skynet.getenv(redis_prename.."redis_host" .. i),
				port = skynet.getenv(redis_prename.."redis_port" .. i),
				db = skynet.getenv(redis_prename.."redis_db" .. i),
				auth = skynet.getenv(redis_prename.."redis_auth" .. i),
			}
		end
		
		if db then
	--		 db:flushdb() --测试期，清理redis数据
			table.insert(pool, db)
		else
			skynet.error("redis connect error")
		end
	end
end

-- key
function CMD.del(uid, key)
	local db = getconn(uid)
	local result = db:del(key)

	return result
end

-- string
function CMD.set(uid, key, value)
	local db = getconn(uid)
	local retsult = db:set(key,value)

	return retsult
end

function CMD.llen(uid, key)
	local db = getconn(uid)
	local result = db:llen(key)
	return result
end

function CMD.setex(uid, key, value, seconds)
	local db = getconn(uid)
	local retsult = db:setex(key, seconds, value)

	return retsult
end

function CMD.setkeyex(uid, key, seconds)
	local db = getconn(uid)
	local retsult = db:expire(key, seconds)

	return retsult
end

function CMD.setnx( uid, key, value, minueseconds )
	local db = getconn(uid)
	local retsult = db:set(key, value, "NX", "PX", minueseconds )

	return retsult
end

function CMD.get(uid, key)
	local db = getconn(uid)
	local retsult = db:get(key)
	return retsult
end

function CMD.srandmember(uid, key)
	local db = getconn(uid)
	local retsult = db:srandmember(key)
	return retsult
end

function CMD.smembers(uid, key)
	local db = getconn(uid)
	local retsult = db:smembers(key)
	return retsult
end



function CMD.incr(uid, key)
	local db = getconn(uid)
	local result = db:incr(key)

	return result
end

function CMD.incrby(uid, key, increment)
	local db = getconn(uid)
	local result = db:incrby(key, increment)

	return result
end

function CMD.incrbyfloat(uid, key, increment)
	local db = getconn(uid)
	local result = db:incrbyfloat(key, increment)

	return result
end

-- set
function CMD.sadd(uid, key, value)
	local db = getconn(uid)
	local result = db:sadd(key, value)

	return result
end

function CMD.sismember(uid, key, value)
	local db = getconn(uid)
	local result = db:sismember(key, value)

	return result
end

-- list
function CMD.keys(uid, key)
	local db = getconn(uid)
	local result = db:keys(key)

	return result

end

function CMD.lrange(uid, key, sindex, eindex)
	local db = getconn(uid)
	local result = db:lrange(key, sindex, eindex)

	return result
end

function CMD.lpop(uid, key)
	local db = getconn(uid)
	local result = db:lpop(key)

	return result
end

function CMD.lpush(uid, key,value)
	local db = getconn(uid)
	local result = db:lpush(key, value)

	return result
end

function CMD.rpush(uid, key, value)
	local db = getconn(uid)
	local result = db:rpush(key, value)

	return result
end

function CMD.ltrim(uid, key, sindex, eindex)
	local db = getconn(uid)
	local result = db:ltrim(key, sindex, eindex)

	return result
end

-- hash
function CMD.hmset(uid, key, t)
	local data = {}
	for k, v in pairs(t) do
		table.insert(data, k)
		table.insert(data, v)
	end

	local db = getconn(uid)
	local result = db:hmset(key, table.unpack(data))

	return result
end

function CMD.hmget(uid, key, ...)
	if not key then return end

	local db = getconn(uid)
	local result = db:hmget(key, ...)

	return result
end

function CMD.hset(uid, key, filed, value)
	local db = getconn(uid)
	local result = db:hset(key,filed,value)

	return result
end

function CMD.hget(uid, key, filed)
	local db = getconn(uid)
	local result = db:hget(key, filed)

	return result
end

function CMD.hgetall(uid, key)
	local db = getconn(uid)
	local result = db:hgetall(key)

	return result
end

function CMD.hexists(uid, key, field)
	local db = getconn(uid)
	return db:hexists(key, field) == 1
end

function CMD.hdel(uid, key, field)
	local db = getconn(uid)
	local result = db:hdel(key, field)

	return result
end

function CMD.hlen(uid, key)
	local db = getconn(uid)
	local result = db:hlen(key)

	return result
end
-- zset
function CMD.zadd(uid, key, score, member)
	local db = getconn(uid)
	assert(db, "redis db is nil")
	local result = db:zadd(key, score, member)

	return result
end

function CMD.zincrby(uid, key, score, member)
	local db = getconn(uid)
	local result = db:zincrby(key, score, member)
	return result
end


function CMD.zrange(uid, key, from, to)
	local db = getconn(uid)
	local result = db:zrange(key, from, to)

	return result
end

function CMD.zrevrange(uid, key, from, to ,scores)
	local result
	local db = getconn(uid)
	if not scores then
		result = db:zrevrange(key,from,to)
	else
		result = db:zrevrange(key,from,to,scores)
	end

	return result
end

function CMD.zrank(uid, key, member)
	local db = getconn(uid)
	local result = db:zrank(key,member)

	return result
end

function CMD.zrevrank(uid, key, member)
	local db = getconn(uid)
	local result = db:zrevrank(key,member)

	return result
end

function CMD.zscore(uid, key, score)
	local db = getconn(uid)
	local result = db:zscore(key,score)

	return result
end

function CMD.zcount(uid, key, from, to)
	local db = getconn(uid)
	local result = db:zcount(key,from,to)

	return result
end

function CMD.zcard(uid, key)
	local db = getconn(uid)
	local result = db:zcard(key)

	return result
end

function CMD.zrem(uid, key, member)
	local db = getconn(uid)
	local result = db:zrem(key, member)

	return result
end

function CMD.zrangebyscore(uid, key, limit, type, minscore, maxscore)
	local db = getconn(uid)
	local result = {}
	if maxscore == nil then
		maxscore = "+inf"
	end
	if minscore == nil then
		minscore = "-inf"
	end
	if type ~= nil and type == 1 then
		result = db:zrangebyscore(key, minscore, maxscore, "WITHSCORES", "limit", 0, limit)
	else
		result = db:zrangebyscore(key, minscore, maxscore, "limit", 0, limit)
	end
	return result
end

function CMD.zrevrangebyscore(uid, key, limit, type)
	local db = getconn(uid)
	local result = {}
	if type ~= nil and type == 1 then
		result = db:zrevrangebyscore(key, "+inf", "-inf", "WITHSCORES", "limit", 0, limit)
	else
		result = db:zrevrangebyscore(key, "+inf", "-inf", "limit", 0, limit)
	end
	return result
end

function CMD.zrevrangebyscorewithmaxmin(uid, key, limit, type, maxscore, minscore)
	local db = getconn(uid)
	local result = {}
	if maxscore == nil then
		maxscore = "+inf"
	end
	if minscore == nil then
		minscore = "-inf"
	end
	if type ~= nil and type == 1 then
		result = db:zrevrangebyscore(key, maxscore, minscore, "WITHSCORES", "limit", 0, limit)
	else
		result = db:zrevrangebyscore(key, maxscore, minscore, "limit", 0, limit)
	end
	return result
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)
	skynet.register("."..redis_prename..SERVICE_NAME)
end)
