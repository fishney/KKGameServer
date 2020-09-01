local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local snax = require "snax"
local CMD = {}

local account_dc

function CMD.get_account_dc(username)
	if nil == account_dc then
		account_dc = snax.queryservice("accountdc")
	end
	local account = account_dc.req.get(username)
	return account
end

function CMD.set_account_item(id, field, data)
	if nil == account_dc then
		account_dc = snax.queryservice("accountdc")
	end

	return account_dc.req.setValue(id, field, data)
end

function CMD.set_account_data(id, row)
	if nil == account_dc then
		account_dc = snax.queryservice("accountdc")
	end
	for k, v in pairs(row) do
		account_dc.req.setValue(id, k, v)
	end
end

--重新才从db加载单条数据
function CMD.reload(uid)
	local sql = string.format("select * from d_account where id=%d", uid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs > 0 then
		if not account_dc then
			account_dc = snax.uniqueservice("accountdc")
		end
		uid = tonumber(uid)
		local account = account_dc.req.get(uid)
		if account == nil or table.empty(account) then
			account_dc.req.add(rs[1], true)
		else
			for _, row in pairs(rs) do
				for field, value in pairs(row) do
					if value ~= account[field] then
						account_dc.req.setValue(row.id, field, value)
					end
				end
			end
		end
	end
end

---zremUserAccount 游客绑定第3方账号后，清理之前关系
---@param playername 游客账号
---@param uid uid
function CMD.zremUserAccount(playername, uid)
	do_redis({"zrem", "d_account:index:" .. playername, tostring(uid)}, 0)
end

function CMD.addUserAccount(playername, uid)
	do_redis({ "zadd", "d_account:index:" .. tostring(playername), 0, tostring(uid) }, uid)
end

--test账号保存nickname，node服协议2需返回test昵称
function CMD.addNickName(uid, nickname)
	local key = "user_"..uid..'_nick'
	do_redis({"setex", key, nickname, 3600}, uid) --只保存1小时
end

function CMD.getNickName(uid)
	local key = "user_"..uid..'_nick'
	local nickname = do_redis({"get",key }, uid)
	print("从redis中获取昵称：key ", key, " value:", nickname)
	if nickname ~= nil or nickname ~= "" then
		return nickname
	end
	return nil
end

function CMD.addAppId(appid, uid, nickname)
	do_redis({"set","user_"..uid.."_appid", appid}, uid)

	print("设置昵称到redis:", nickname)
	if nil ~=nickname and (string.match(nickname, '^test%d%d%d%d$') or string.match(nickname, '^demo%d%d%d%d$') ) then
		print("设置昵称到redis222:", nickname)
		CMD.addNickName(uid, nickname)
	end
end

function CMD.getAppId(uid)
	local appid = do_redis({"get","user_"..uid.."_appid"}, uid)
	if appid == nil then
		appid = 0
	end
	appid = math.floor(appid)
	return appid
end

function CMD.apiReleaseAccount(uid, pid)

	local row = {}
	row["deled"] = 1
	row["pid"] = 'del'..tostring(uid)
	CMD.set_account_data(uid, row)

	do_redis({"del", "d_account:index:" .. pid})
	do_redis({"del", "d_account:" .. uid})
end

--根据indexkey值获取account数量
function CMD.get_account_by_indexkey(pid)
	local ids = do_redis({"zrange", "d_account:index:"..pid, 0, -1}, 0)
	if #ids > 0 then
		return #ids
	end
	return 0
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.retpack(f(...))
	end)
	skynet.register(".accountdata")
end)
