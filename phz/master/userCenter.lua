local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local queuemgr = require "queuemgr"()
local loginshutdownFlag = false --登录服关闭状态 true维护中；维护状态不让发广播
local CMD = {}

function CMD.getAgent(uid)
	return skynet.call(".agentmgr", "lua", "getPlayer", uid)
end

-- 各聊天频道存放的是agent地址
local world_channel = {}


-------- 改变登录服维护状态 --------
function CMD.changeLoginState(state) 
	if math.floor(state) == 2 then
		loginshutdownFlag = true
	else
		loginshutdownFlag = false
	end
end

function CMD.joinPlayer(cluster_info, data)
	local uid = data.uid
	-- 全局队列
	world_channel[uid] = cluster_info
end

function CMD.removePlayer(data)
	local uid = data.uid
	world_channel[uid]=nil
end

local function sendChat(cluster_info, msg)
	pcall(cluster.call, cluster_info.server, cluster_info.address, "sendToClient", msg)
end

local function pushMsg(msg)
	for _,cluster_info in pairs(world_channel) do
		sendChat(cluster_info, msg)
	end
end

local function get_msg()
	local pushList = {}
	local sql = "select * FROM push_msg"
	local rs = do_mysql_direct(sql)
	if #rs > 0 then
		for _, row in pairs(rs) do
			table.insert(pushList,row.msg)
		end
	end
	local retobj = {}
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	retobj.response.noityInfo = {}
	retobj.opCode = "NOTIFY_NOITY_INFO"
	retobj.response.noityInfo.noity = pushList
	pushMsg(retobj)
end

function CMD.noityUserMessage(uid,msg,isNotline)
	local agent = world_channel[uid]
	if nil ~= agent then
		--在线
		print("noityUserMessage uid=>",uid," msg===>",msg)
		pcall(cluster.call, world_channel[uid].server, world_channel[uid].address, "sendToClient", msg)
	-- else
	-- 	if isNotline then
	-- 		--不在线
	-- 		OFFLINE_CMD(uid, "updateQuest", {questid, count}, true)
	-- 	end
	end
end

function CMD.addItemInfo(uid,itemInfo,waresid)
	if waresid then
		local sql = string.format("select * from point where waresid = %d and uid = %d",waresid,uid)
		local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
		if #rs == 0 then
			sql = string.format("insert into point(uid,waresid)values(%d,%d)",uid,waresid)
			skynet.call(".mysqlpool", "lua", "execute", sql)
		end
	end
	
	if world_channel[uid] then
		pcall(cluster.call, world_channel[uid].server, world_channel[uid].address, "addItemInfo", itemInfo, flg)
	else
		OFFLINE_CMD(uid, "addItemInfo", {itemInfo.type,itemInfo.count}, true)
	end
end

local function authIpayOrder()
	local sql = "select * FROM web_ipay_order where state !=1"
	local rs = do_mysql_direct(sql)
	if #rs > 0 then
		for _, row in pairs(rs) do
			if row.state == 0 then
				--校验
				local sql = "update web_ipay_order set state = 1 where orderid = '"..row.orderid.."'"
				skynet.call(".mysqlpool", "lua", "execute", sql)

				local sql = "update ipay_order set state = 1 where orderid = '"..row.orderid.."'"
				skynet.call(".mysqlpool", "lua", "execute", sql)
				local itemInfo = CfgShop.getIpayShopInfo(row.waresid)
				if itemInfo then
					CMD.addItemInfo(row.uid,itemInfo,row.waresid)
				end
			end
		end
	end
end

local function giveRoomCard(opuid,uid,number,id,itype)
	local ok,ret
	local itemInfo = {}
	itemInfo.type = itype
	itemInfo.count = number
	
	if itype == 1 then
		local sql = string.format("select rcard from api_user_data where uid = %d",opuid)
		local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
		if #rs ~= 0 then
			local b_roomcard = rs[1]["rcard"]
			if  b_roomcard >= number then
				local sql = string.format("update api_user_data set rcard = %d where uid=%d",b_roomcard-number,opuid)
				skynet.call(".mysqlpool", "lua", "execute", sql)

				sql = string.format("update cardhistory set status = 1 where id=%d",id)
				skynet.call(".mysqlpool", "lua", "execute", sql)

				sql = string.format("update cardhistory set onumber_before = %d,onumber_after = %d  where id=%d",b_roomcard,b_roomcard-number,id)
				skynet.call(".mysqlpool", "lua", "execute", sql)
				ret = true
			end
		end
	elseif itype == 2 then
		local sql = string.format("select coin from api_user_data where uid = %d",opuid)
		local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
		if #rs ~= 0 then
			local b_gold = rs[1]["coin"]
			if  b_gold >= number then
				local sql = string.format("update api_user_data set coin = %d where uid=%d",b_gold-number,opuid)
				skynet.call(".mysqlpool", "lua", "execute", sql)
				sql = string.format("update cardhistory set status = 1 where id=%d",id)
				skynet.call(".mysqlpool", "lua", "execute", sql)

				sql = string.format("update cardhistory set onumber_before = %d,onumber_after = %d  where id=%d",b_gold,b_gold-number,id)
				skynet.call(".mysqlpool", "lua", "execute", sql)
				ret = true
			end
		end
	end
	
	
	if ret then
		local client_agent = world_channel[uid]
		local sql = string.format("select roomcard,gold from d_user where uid = %d",uid)
		local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
		local b_roomcard = rs[1]["roomcard"]
		local b_gold = rs[1]["gold"]
		
		CMD.addItemInfo(uid,itemInfo)
		if itype == 1 then
			if not client_agent then
				sql = string.format("update d_user set roomcard = %d where uid=%d",b_roomcard+number,uid)
				skynet.call(".mysqlpool", "lua", "execute", sql)
			end
			sql = string.format("update cardhistory set snumber = %d,enumber = %d  where id=%d",b_roomcard,b_roomcard+number,id)
			skynet.call(".mysqlpool", "lua", "execute", sql)
			return true
		elseif itype == 2 then
			if not client_agent then
				sql = string.format("update d_user set gold = %d where uid=%d",b_gold+number,uid)
				skynet.call(".mysqlpool", "lua", "execute", sql)
			end
			sql = string.format("update cardhistory set snumber = %d,enumber = %d  where id=%d",b_gold,b_gold+number,id)
			skynet.call(".mysqlpool", "lua", "execute", sql)
			return true
		end
	end
end

local function eventGiveRoomCard()

	local sql = string.format("select * from cardhistory where status = 0 and type = 1")
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	
	if #rs > 0 then
		for _,row in pairs(rs) do
			sql = string.format("select * from d_user where uid = %d",row.uid)
			local desuid = skynet.call(".mysqlpool", "lua", "execute", sql)
			if #desuid > 0 then
				sql = string.format("update cardhistory set status = 1,ptime = %d where id=%d",os.time(),row.id)
				skynet.call(".mysqlpool", "lua", "execute", sql)
				local id = row.id
				local uid = row.uid
				local number = row.number
				local opuid = row.opuid
				local itype = row.itype
				local ret = giveRoomCard(opuid,uid,number,id,itype)
				if ret then
					sql = string.format("update cardhistory set status = 2,ptime = %d where id=%d",os.time(),row.id)
				else
					sql = string.format("update cardhistory set status = -1,ptime = %d where id=%d",os.time(),row.id)
				end
				skynet.call(".mysqlpool", "lua", "execute", sql)
			end
		end
	end
end

-- 定时执行循环
local function update()
	local time_now = os.time()
	local time_info = os.date("*t", time_now)
	-- 每秒判定
	if last_check_sec ~= time_info.sec then
		authIpayOrder()
		eventGiveRoomCard()
		last_check_sec = time_info.sec
		-- 每5秒处理
		if last_check_sec % 5 == 0 then
			local param = {}
			
			-- 外部定时任务
		end
		-- 每10秒处理
		if last_check_sec % 10 == 0 then
		end

		-- 每分钟判定
		if last_check_min ~= time_info.min then
			last_check_min = time_info.min
			-- 每5分钟处理
			if last_check_min % 2 == 0 then
				--get_msg()
			end

			-- 每小时判定
			if last_check_hour ~= time_info.hour then
				local change_hour = false
				if last_check_hour ~= -1 then
					change_hour = true
				end
				last_check_hour = time_info.hour
				-- 小时变动
				if change_hour then
					-- 每4小时处理
					if last_check_hour % 4 == 0 then
		
					end
				end
			end
		end
	end
end

--获取加载用户信息权限
--@param uid
--@param func = {iscluster = true, node = NODE_NAME, addr = skynet.self(), fuc_name="loaduser"}
--@param ...其他参数
--@return func的返回
function CMD.alterUserQueue( uid, func, ... )
    --TODO MZH这里应该去控制user_dc.load(uid) 而不是控制登录事件和修改金币事件 但是考虑到修改量问题 先简单控制
    LOG_DEBUG("alterUserQueue uid:", uid, "func:", func, ...)
    local queue = queuemgr.getQueue("alteruser"..math.floor(uid))
    local param = {func, ...}
    local ret
    queue(
        function()
            LOG_DEBUG("alterUserQueue queue func:", func, param)
            if func ~= nil then
                if func.iscluster then
                    ret = {pcall(cluster.call, func.node, func.addr, func.fuc_name, table.unpack(param))}
                else
                    ret = {pcall(skynet.call, func.addr, "lua", func.fuc_name, table.unpack(param))}
                end
            end
        end
    )
    return table.unpack(ret)
end

local function gameLoop()
	while true do
		update()
		skynet.sleep(100)
	end
end

function CMD.start()
	skynet.fork(gameLoop)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		print("--------cmd------",cmd)
		local f = CMD[cmd]
		skynet.retpack(f(...))
	end)
	skynet.register(".userCenter")
end)