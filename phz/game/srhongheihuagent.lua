local skynet = require "skynet"
local netpack = require "netpack"
local crypt = require "crypt"
local socket = require "socket"
local cluster = require "cluster"
local socketdriver = require "socketdriver"
local random = require "random"
local cjson   = require "cjson"
local hongheitool = require "hongheitool"
local queue = require "skynet.queue"
local cs = queue() 
local find = 0
cjson.encode_sparse_array(true)
cjson.encode_empty_table_as_object(false)
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
}
local GAME_NAME = skynet.getenv("gamename") or "game"
-- game节点的全局服务 红中麻将
-- 桌子用户信息
local deskInfo = 
{
	users = {},
	smallState = 0,
	bigState = 0,
	gameid = PDEFINE.GAME_TYPE.ZIPAI_HONGHEIHU_SR
}

local new_card = {}
local state = 0
local curTime
local usersAutoFuc = {}
local deskAutoFuc
local beginTime = ""
local timeout = {120,90,60,120,3,120} 
-- 接口函数组
local CMD = {}
local existSeatIdList = {}
local waitAction = {}

local function resp(retobj)
    return PDEFINE.RET.SUCCESS, cjson.encode(retobj)
end

-- 查找用户信息
local function seleteUserInfo(value,tag)
	if tag == "uid" then
		for _, user in pairs(deskInfo.users) do
			if user.uid == value then
				return user
			end
		end
	elseif tag == "seat" then
		for _, user in pairs(deskInfo.users) do
			if user.seat == value then
				return user
			end
		end
	end
	return nil
end

local function closeAllTimer()
	for _,user in pairs(deskInfo.users) do
		if usersAutoFuc[user.seat] then 
			usersAutoFuc[user.seat](user.seat)
		end
	end
end
local function initDissolveInfo()
	deskInfo.dissolveInfo = {distimeoutBeginTime = 0,distimeoutIntervel = 0,iStart = 0,startUid = 0,startPlayername = nil, time = timeout[4],agreeUsers = {}}
	for _, user in pairs(deskInfo.users) do
		local agreeUser = {uid = user.uid, seat = user.seat, usericon = user.usericon, playername = user.playername,isargee = -1}
		table.insert(deskInfo.dissolveInfo.agreeUsers,agreeUser)
	end
end

function CMD.initDeskConfig(_, gameInfo, deskId)
	deskInfo.conf = gameInfo
	deskInfo.conf.deskId = deskId
	deskInfo.conf.curseat = 0
	deskInfo.smallState = 0
	deskInfo.bigState = 0
	deskInfo.smallBeginTime = ""
	deskInfo.round = 0
	deskInfo.locatingList = {}
	deskInfo.bankerInfo = {uid = 0, count = 0, seat = 0}
	deskInfo.actionInfo = {iswait = 0,prioritySeat = 0, waitList = {},curaction = {seat = 0, type = 0, card = 0, source = 0},nextaction = {seat = 0, type = 0}}
	initDissolveInfo()
	local seat = deskInfo.conf.seat
	for i =1, seat do
		table.insert(existSeatIdList,i)
	end
end



local function initBankerInfo()
	if deskInfo.bankerInfo.uid == 0 then
		deskInfo.bankerInfo.seat = math.random(1,deskInfo.conf.seat)
		local user = seleteUserInfo(deskInfo.bankerInfo.seat,"seat")
		deskInfo.bankerInfo.uid = user.uid
		--deskInfo.bankerInfo.count = 1
	end
end

local function modifBankerInfo(uid,seat)
	deskInfo.bankerInfo.uid = uid
	--deskInfo.bankerInfo.count = count
	deskInfo.bankerInfo.seat = seat
end

local function getActionInfo()
	deskInfo.actionInfo.nextaction.seat = deskInfo.bankerInfo.seat
	deskInfo.actionInfo.nextaction.type =  hongheitool.cardType.put
end

local function setNextActionInfo(nextaction)
	deskInfo.actionInfo.nextaction = nextaction
end

local function addTgTime()
	if deskInfo.conf.trustee == 1 then
		deskInfo.actionInfo.curaction.time = timeout[1]
	end
end

--设置延时
local function setTimeOut()
	if deskInfo.conf.speed == 1 then
		skynet.sleep(timeout[3])
	else
		skynet.sleep(timeout[2])	
	end
end

local function descutActionInfo()
	if deskInfo.actionInfo.iswait == 1 then
		local tmpActionInfo = table.copy(deskInfo.actionInfo)
		local waitList = {}
		for _,  waitInfo in pairs(tmpActionInfo.waitList) do
			table.insert(waitList,waitInfo)
		end
		tmpActionInfo.waitList = waitList
		return tmpActionInfo
	end
	return deskInfo.actionInfo
end

local function notyTingPaiInfo(user)
	local notify_retobj = {}
	notify_retobj.c      = 1401
	notify_retobj.code  = PDEFINE.RET.SUCCESS
	notify_retobj.tingPaiInfo = hongheitool.getTingPaiInfo(user)
	if user.ofline == 0 then
		pcall(cluster.call, user.cluster_info.server, user.cluster_info.address, "sendToClient", cjson.encode(notify_retobj))
	end
end

local function updateActionInfo(actionType)
	if actionType == hongheitool.cardType.put then
		if deskInfo.actionInfo.iswait == 0 then
			deskInfo.actionInfo.nextaction.seat = getNextSeat(deskInfo.actionInfo.curaction.seat)
			deskInfo.actionInfo.nextaction.type = hongheitool.cardType.draw
		end
	else
		if deskInfo.actionInfo.iswait == 0 then
			deskInfo.actionInfo.curaction.seat = deskInfo.actionInfo.nextaction.seat
			deskInfo.actionInfo.nextaction.type = hongheitool.cardType.draw
		end
	end
end

--初始化座位号
local function initSeat(seat)
	for i =1 ,seat do
		table.insert(existSeatIdList,i)
	end
end

-- 分配座位号
local function getSeatId()
	return table.remove(existSeatIdList)
end

-- 重置房间座位号
local function setSeatId(seat)
	if seat then
		deskInfo.conf.curseat = deskInfo.conf.curseat - 1
		table.insert(existSeatIdList,seat)
	end
end


local function setBuck(buck)
	if buck > 2 then
		buck = 1
	end
	deskInfo.buck = buck
end

local function delteHandIncards(user,card)
	for i,cards in pairs(user.handInCards) do
		if card then
			if card == cards then
				table.remove(user.handInCards,i)
				return true
			end
		else
			return table.remove(user.handInCards)
		end
	end
end

-- 广播给玩家
local function getOherMemzi(duser)
	local otherUserMenzi = {}
	for _,info in pairs(duser.menzi) do
		if info.type == hongheitool.cardType.kan or info.type == hongheitool.cardType.long then
			local otherInfo = {}
			otherInfo.type = info.type
			otherInfo.card = 0
			table.insert(otherUserMenzi,otherInfo)
		else
			table.insert(otherUserMenzi,info)
		end
	end
	return otherUserMenzi
end

-- 广播给房间里的所有人
local function broadcastDesk(retobj)
	for _, muser in pairs(deskInfo.users) do
        if muser.cluster_info and muser.ofline == 0 then
            pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", retobj)
        end
    end
end

local function notyGpsColour()
	deskInfo.locatingList,gpsColour = hongheitool.jisuanXY(deskInfo.users)
	local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTIFY_GPS_UPDATE
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.gpsColour  = gpsColour
	broadcastDesk(cjson.encode(noty_retobj))
end

local function gameRecord(bigmall)
	if bigmall == 1 then
		local recordData = {}
		for _,user in pairs(deskInfo.users) do
			local info = {}
			info.uid = user.uid
			info.playername = user.playername
			info.usericon = user.usericon
			info.roundScore = user.roundScore
			table.insert(recordData,info)
		end
		for _,user in pairs(deskInfo.users) do
			local sql = string.format("insert into s_small_record (clubid,gameid,uid,data,deskid,beginTime,endTime,selectTime,time)values(%d,%d,%d,'%s',%d,'%s','%s','%s', %d)",0,deskInfo.conf.gameid,user.uid,cjson.encode(recordData),deskInfo.conf.deskId,deskInfo.smallBeginTime,os.date("%Y-%m-%d %H:%M:%S", os.time()), os.date("%Y-%m-%d", os.time()),os.time())
			skynet.call(".mysqlpool", "lua", "execute", sql)
		end
	else
		local recordData = {}
		local bigWinUid = 0
		local maxScore = 0
		for _,user in pairs(deskInfo.users) do
			local info = {}
			info.uid = user.uid
			info.playername = user.playername
			info.usericon = user.usericon
			info.score = user.score
			table.insert(recordData,info)
			if user.score > maxScore then
				maxScore = user.score
				bigWinUid = user.uid
			end
		end
		for _,user in pairs(deskInfo.users) do
			local isBigWin = 0
			if user.uid == bigWinUid then
				isBigWin = 1
			end
			local sql = string.format("insert into s_big_record (clubid,gameid,uid,score,data,deskid,beginTime,endTime,selectTime,presonNum,gameNum,houseOwner,time,houseOwnerUid,isBigWin)values(%d,%d,%d,%d,'%s',%d,'%s','%s','%s', %d, '%s', '%s',%d,%d,%d)",0, deskInfo.conf.gameid, user.uid, user.score, cjson.encode(recordData), deskInfo.conf.deskId, beginTime, os.date("%m-%d %H:%M:%S", os.time()), os.date("%Y-%m-%d", os.time()), deskInfo.conf.seat, deskInfo.conf.gamenum, deskInfo.conf.createUserInfo.playername, os.time(),deskInfo.conf.createUserInfo.uid,isBigWin)
			skynet.call(".mysqlpool", "lua", "execute", sql)
		end
	end
end



-- 给该桌子放置一副已经打乱的牌
local function setDeskBase()
	local paiLib =
	{
	    101,102,103,104,105,106,107,108,109,110,
	    201,202,203,204,205,206,207,208,209,210,
	    101,102,103,104,105,106,107,108,109,110,
	    201,202,203,204,205,206,207,208,209,210,
	    101,102,103,104,105,106,107,108,109,110,
	    201,202,203,204,205,206,207,208,209,210,
	    101,102,103,104,105,106,107,108,109,110,
	    201,202,203,204,205,206,207,208,209,210
	}

	new_card = table.copy(paiLib)
	local value = 1
	local swap = 1
	local l = #new_card
	for i = 1,l do
		local x = l - i
		local rv = random_value(x)
		if x == 0 then
			rv = 0
		end
		value = i + rv
		swap = new_card[i]
		new_card[i] = new_card[value]
		new_card[value] = swap
	end
end



local function getNextSeat(seat)
	local nseat = seat + 1
	if nseat > deskInfo.conf.curseat then
		nseat = 1
	end
	return nseat
end

local function getShangSeat(seat)
	local nseat = seat - 1
	if nseat == 0 then
		nseat = deskInfo.conf.curseat
	end
	return nseat
end

local function getNextUser(seat)
	local seat = getNextSeat(seat)
	local user = seleteUserInfo(seat,"seat")
	return user
end

local function restartTime(time)
	deskInfo.time = time
	curTime = os.time()
end

local function restartUserTime(user,time)
	user.time = time
	user.curTime = os.time() + time
end

local function getSyTime(time)
	local syTime = time - (os.time() - curTime)
	deskInfo.time = syTime
end

local function getUserSyTime(uid,time)
	local user = seleteUserInfo(uid,"uid")
	local syTime = user.curTime - os.time()
	user.time = syTime
end

-- 统计相同牌的值
function getXtCardVluse(cards)
    local valurNum = {}
    for _,card in pairs(cards) do
        if not valurNum[card] then
            valurNum[card] = 0
        end
    end
    --可能不是有序的重新排序
    local tmp_cards1 = {}
    local tmpCards = table.copy(cards)
    for _,card in pairs(tmpCards) do
        table.insert(tmp_cards1,card)
    end
    local tmp_cards = table.copy(tmp_cards1)
    for i = 1,#tmp_cards do         
         for j = 1,#tmp_cards1 do
            if tmp_cards[i] == tmp_cards1[j] then
                tmp_cards[i] = 0
                local value = tmp_cards1[i]          
                valurNum[value] = valurNum[value] + 1
            end
         end
    end
    return valurNum
end


-- 当把游戏结束
local function global_over()
	deskInfo.smallState = 0
	deskInfo.smallBeginTime = ""
	deskInfo.actionInfo = {iswait = 0,prioritySeat = 0, waitList = {},curaction = {seat = 0, type = 0, card = 0, source = 0},nextaction = {seat = 0, type = 0}}
	for _,user in pairs(deskInfo.users) do
		if usersAutoFuc[user.seat] then 
			usersAutoFuc[user.seat](user.seat)
		end
		user.handInCards = {}
		user.qipai = {}
		user.tingPaiInfo = {}
		user.notChiPai = {}
		user.notPengPai = {}
		user.menzi = {}
		user.state = 0
		user.roundScore = 0
		user.roundHuXi = 0
		user.ohterRoundHuXi = 0
		CMD.userSetAutoState("autoReady",timeout[1]*100,user.seat)
	end
	waitAction = {}
end

-- 当把游戏结束
local function big_over()
	for _,user in pairs(deskInfo.users) do
		pcall(cluster.call, user.cluster_info.server, user.cluster_info.address, "deskBack", PDEFINE.GAME_TYPE.ZIPAI_HONGHEIHU_SR) --释放桌子对象
	end
	deskInfo.users = {}
	deskInfo.smallState = 0
	deskInfo.bigState = 0
	deskInfo.bankerInfo = {uid = 0, count = 1, seat = 0}
	deskInfo.actionInfo = {iswait = 0,prioritySeat = 0, waitList = {},curaction = {seat = 0, type = 0, card = 0, source = 0},nextaction = {seat = 0, type = 0}}
	pcall(cluster.call, "game", ".dsmgr", "recycleAgent", skynet.self(), deskInfo.conf.deskId)
end

local function getMenziPaoOrlongOrShe(user)
	for _,info in pairs(user.menzi) do
		if info.type >= hongheitool.cardType.pao then
			return true
		end
	end
	return hongheitool.checkHandShe(user.handInCards) ---校验手中是否有蛇
end

local function getChekHuPaiList(user,isAdd) --把下面的牌都放到牌堆里算胡牌
	local checkHuCards = {}
	for i = 1, #user.handInCards do
		table.insert(checkHuCards,user.handInCards[i])
	end
	if isAdd then
		for _, info in pairs(user.menzi) do
			if info.type == hongheitool.cardType.kan or info.type == hongheitool.cardType.peng then
				for  i = 1, 3 do
					table.insert(checkHuCards,info.card)
				end
			end
			if info.type == hongheitool.cardType.pao or info.type == hongheitool.cardType.long then
				for  i = 1, 4 do
					table.insert(checkHuCards,info.card)
				end
			end
			if info.type == hongheitool.cardType.chi then
				table.insert(checkHuCards,info.data[1])
				table.insert(checkHuCards,info.data[2])
				table.insert(checkHuCards,info.data[3])
			end
		end
	end
	return checkHuCards
end

local function hupaiBance(hseat,hcard,huXi,isdissolve,huCards,isZimo)
	closeAllTimer()
	local huser = seleteUserInfo(hseat,"seat")
	local noty_retobj  = {}
	noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_HUPAI
	noty_retobj.code   = PDEFINE.RET.SUCCESS
	noty_retobj.gameid = deskInfo.gameid
	noty_retobj.seat = hseat
	noty_retobj.huxi = huXi --如果是-1就是流局 > 0才是胡了
	noty_retobj.diPai = new_card
	noty_retobj.hcard = hcard
	noty_retobj.buck = deskInfo.bankerInfo.uid
	noty_retobj.huCards = huCards or {}
	
	if huXi > 0 then
		huser.huPaiCount = huser.huPaiCount + 1
		local cards = getChekHuPaiList(huser,true)
		
		local roundScore,mingTang = hongheitool.checkScore(cards,huXi,deskInfo.conf.param1,deskInfo.conf.score,hcard)
		for _, muser in pairs(deskInfo.users) do
			if huser.uid == muser.uid then
				muser.roundScore = roundScore*(deskInfo.conf.seat - 1) 
				muser.totalHuXi = muser.totalHuXi + huXi
				muser.roundHuXi = huXi
				if mingTang > 0 then
					muser.mingTangCount = muser.mingTangCount + 1
				end
				muser.score = muser.score + muser.roundScore
			else
				muser.roundScore = -roundScore
				muser.score = muser.score + muser.roundScore
			end
		end
		modifBankerInfo(huser.uid,huser.seat,1)
		noty_retobj.users   = deskInfo.users
		noty_retobj.roundScore  = roundScore
		noty_retobj.roundHuxi   = huXi
		noty_retobj.isZimo   = isZimo --是否自摸
		noty_retobj.mingTangType  = mingTang --名堂类型
		noty_retobj.hupaiType = hongheitool.HUPAI_TYPE.normal
		gameRecord(1)
	else--流局
		if not isdissolve then
			local nextSeat = getNextSeat(deskInfo.bankerInfo.seat)
			local nextUser = seleteUserInfo(nextSeat,"seat")
			modifBankerInfo(nextUser.uid,nextUser.seat,1)
		end
		noty_retobj.users   = deskInfo.users
		gameRecord(1)
	end
	skynet.sleep(30)
	broadcastDesk(cjson.encode(noty_retobj))
	if deskInfo.round == deskInfo.conf.gamenum or isdissolve then
		local userList = {}
		for _,user in pairs(deskInfo.users) do
			local info = {}
			info.uid = user.uid
			info.playername = user.playername
			info.usericon = user.usericon
			info.huPaiCount = user.huPaiCount
			info.totalHuXi = user.totalHuXi
			info.mingTangCount = user.mingTangCount
			info.score = user.score
			table.insert(userList,info)
		end
		local noty_retobj  = {}
		noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_OVER
		noty_retobj.code   = PDEFINE.RET.SUCCESS
		noty_retobj.gameid = deskInfo.gameid
		noty_retobj.overTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
		noty_retobj.createUser = deskInfo.conf.createUserInfo
		noty_retobj.users   = userList
		broadcastDesk(cjson.encode(noty_retobj))

		if deskInfo.smallState == 1 then
			gameRecord(2)
		end
		big_over()
		--通知桌子结束--TODO
	else
		global_over()
	end
	
end




-- 出牌检测其它玩家是否能碰跟杠
local function checkPengGangHu(card,uid,putType)
	local ownuser = seleteUserInfo(uid,"uid")
	--校验自己
	if putType == hongheitool.lpType.draw then
		local checkHuCards = getChekHuPaiList(ownuser)
		local ok,huXi,huCards = hongheitool.checkPaoHuZiHu(ownuser,checkHuCards,card,uid)
		if huXi then
			-- if not ok then
			-- 	if hongheitool.getValueCount(checkHuCards,card) == 2 then
			-- 		return hongheitool.cardType.kan,ownuser.seat
			-- 	end
			-- 	return hongheitool.cardType.hupai,ownuser.seat,huXi,huCards
			-- else
			-- 	return hongheitool.cardType.hupai,ownuser.seat,huXi,huCards
			-- end
			return hongheitool.cardType.hupai,ownuser.seat,huXi,huCards
		end
		--自己摸得牌,
		--1.校验自己是不是踢龙,
		local ok,tiLongType = hongheitool.checkTiLong(ownuser,card)
		if ok then
			return tiLongType,ownuser.seat
		end

		--2.校验自己是不是喂牌
		if hongheitool.checkSao(ownuser,card) then
			return hongheitool.cardType.kan,ownuser.seat
		end
		
		local nextSeat = getNextSeat(ownuser.seat)
		local nextUser = seleteUserInfo(nextSeat,"seat")
		local checkHuCards = getChekHuPaiList(nextUser)

		local ok,huxi,huCards = hongheitool.checkPaoHuZiHu(nextUser,checkHuCards,card,uid)
		if huxi then
			return hongheitool.cardType.hupai,nextUser.seat,huxi,huCards
		end
		for i = 1,#deskInfo.users - 2 do
			nextSeat = getNextSeat(nextUser.seat)
			nextUser = seleteUserInfo(nextSeat,"seat")
			local checkHuCards = getChekHuPaiList(nextUser)
			local ok,huXi,huCards = hongheitool.checkPaoHuZiHu(nextUser,checkHuCards,card,uid)
			if huXi then
				return hongheitool.cardType.hupai,nextUser.seat,huXi,huCards
			end
		end
		--1.校验自己是不是碰跑
		if hongheitool.checkPengPao(ownuser,card) then
			return hongheitool.cardType.pao,ownuser.seat
		end

		--1.校验别人是不是跑
		for _, user in pairs(deskInfo.users) do
			if user.uid ~= uid then
				if hongheitool.checkPengPao(user,card) then
					return hongheitool.cardType.pao,user.seat
				end
				local ok, paoType = hongheitool.checkKanPao(user,card)
				if ok then
					return paoType,user.seat
				end
			end
		end

		--4.校验别人是不是碰
		for _, user in pairs(deskInfo.users) do
			if user.uid ~= uid then
				if hongheitool.checkPeng(user,card) then
					deskInfo.actionInfo.iswait = 1
					deskInfo.actionInfo.prioritySeat = user.seat
					if deskInfo.actionInfo.waitList[user.seat] == nil then
						deskInfo.actionInfo.waitList[user.seat] = {}
						local info = {}
						info.type = hongheitool.cardType.guo
						info.seat = user.seat
						table.insert(deskInfo.actionInfo.waitList[user.seat],info)
					end
					local info = {}
					info.level = 3
					info.seat = user.seat
					info.type = hongheitool.cardType.peng
					info.data = card
					table.insert(deskInfo.actionInfo.waitList[user.seat],info)
				end
			end
		end

		--5.校验自己是不是可以吃
		local sSeat = getShangSeat(ownuser.seat)
		local sUser = seleteUserInfo(sSeat,"seat")
		local chiTypeList = hongheitool.checkChi(ownuser,card,sUser)
		local ownIschi
		if chiTypeList then
			deskInfo.actionInfo.iswait = 1
			if deskInfo.actionInfo.prioritySeat == 0 then
				deskInfo.actionInfo.prioritySeat = ownuser.seat
			end
			if deskInfo.actionInfo.waitList[ownuser.seat] == nil then
				deskInfo.actionInfo.waitList[ownuser.seat] = {}
				local info = {}
				info.type = hongheitool.cardType.guo
				info.seat = ownuser.seat
				table.insert(deskInfo.actionInfo.waitList[ownuser.seat],info)
			end
			local info = {}
			info.seat = ownuser.seat
			info.level = 2
			info.type = hongheitool.cardType.chi
			info.data = chiTypeList
			table.insert(deskInfo.actionInfo.waitList[ownuser.seat],info)
			ownIschi = true
		end
		--6.校验下家是不是可以吃
		local nextSeat = getNextSeat(ownuser.seat)
		nextUser = seleteUserInfo(nextSeat,"seat")

		local sSeat = getShangSeat(nextUser.seat)
		local sUser = seleteUserInfo(sSeat,"seat")
		local chiTypeList = hongheitool.checkChi(nextUser,card,sUser)
		if chiTypeList then
			deskInfo.actionInfo.iswait = 1
			if deskInfo.actionInfo.waitList[nextUser.seat] == nil then
				deskInfo.actionInfo.waitList[nextUser.seat] = {}
				local info = {}
				info.type = hongheitool.cardType.guo
				info.seat = nextUser.seat
				table.insert(deskInfo.actionInfo.waitList[nextUser.seat],info)
			end
			local info = {}
			info.level = 1
			info.seat = nextUser.seat
			info.type = hongheitool.cardType.chi
			info.data = chiTypeList
			table.insert(deskInfo.actionInfo.waitList[nextUser.seat],info)
		end
	else
		local nextSeat = getNextSeat(ownuser.seat)
		local nextUser = seleteUserInfo(nextSeat,"seat")
		--1.校验别人是不是可以跑
		for _, user in pairs(deskInfo.users) do
			if user.uid ~= uid then
				local ok, paoType = hongheitool.checkKanPao(user,card)
				if ok then
					return paoType,user.seat
				end
			end
		end
		--2.校验别人是不是可以碰
		for _, user in pairs(deskInfo.users) do
			if user.uid ~= uid then
				if hongheitool.checkPeng(user,card) then
					deskInfo.actionInfo.iswait = 1
					deskInfo.actionInfo.prioritySeat = user.seat
					if deskInfo.actionInfo.waitList[user.seat] == nil then
						deskInfo.actionInfo.waitList[user.seat] = {}
						local info = {}
						info.type = hongheitool.cardType.guo
						info.seat = user.seat
						table.insert(deskInfo.actionInfo.waitList[user.seat],info)
					end
					local info = {}
					info.seat = user.seat
					info.level = 3
					info.type = hongheitool.cardType.peng
					info.data = card
					table.insert(deskInfo.actionInfo.waitList[user.seat],info)
				end
			end
		end
		--3.校验下家是不是可以吃
		local nextSeat = getNextSeat(ownuser.seat)
		nextUser = seleteUserInfo(nextSeat,"seat")

		local sSeat = getShangSeat(nextUser.seat)
		local sUser = seleteUserInfo(sSeat,"seat")

		local chiTypeList = hongheitool.checkChi(nextUser,card,sUser)
		if chiTypeList then
			deskInfo.actionInfo.iswait = 1
			if deskInfo.actionInfo.waitList[nextUser.seat] == nil then
				deskInfo.actionInfo.waitList[nextUser.seat] = {}
				local info = {}
				info.type = hongheitool.cardType.guo
				info.seat = nextUser.seat
				table.insert(deskInfo.actionInfo.waitList[nextUser.seat],info)
			end
			local info = {}
			info.seat = nextUser.seat
			info.type = hongheitool.cardType.chi
			info.level = 2
			info.data = chiTypeList
			table.insert(deskInfo.actionInfo.waitList[nextUser.seat],info)
		end
	end
end

local function draw(seat)
	local user = seleteUserInfo(seat,"seat")
	local drawCard = table.remove(new_card)
	if not drawCard then
		hupaiBance(deskInfo.actionInfo.curaction.seat, deskInfo.actionInfo.curaction.card, hongheitool.HUPAI_TYPE.liuju)
		return
	end

	local noty_retobj  = {}
	noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_DRAW
	noty_retobj.code   = PDEFINE.RET.SUCCESS
	noty_retobj.gameid = deskInfo.gameid
	noty_retobj.seat   = user.seat
	
	noty_retobj.pulicCardsCnt = #new_card

	local ret,dseat,huXi,huCards = checkPengGangHu(drawCard,user.uid,hongheitool.lpType.draw)
	if ret then
		if ret == hongheitool.cardType.kan or ret == hongheitool.cardType.long or ret == hongheitool.cardType.handlong then
			for _, muser in pairs(deskInfo.users) do
				if dseat ~= muser.seat then
					noty_retobj.card = 0
				else
					noty_retobj.card = drawCard
				end
				if muser.cluster_info  and muser.ofline == 0 then
			    	pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
			    end
			end
		else
			noty_retobj.card = drawCard
			broadcastDesk(cjson.encode(noty_retobj))
		end
	else
		noty_retobj.card = drawCard
		broadcastDesk(cjson.encode(noty_retobj))
	end
	
	deskInfo.actionInfo.curaction = {seat = user.seat, type = hongheitool.cardType.draw, time = timeout[1], card = drawCard, source = 0}
	deskInfo.actionInfo.nextaction = {seat = 0, type = 0}

	
	if ret then
		local isJiu
		setTimeOut()
		deskInfo.actionInfo.curaction = {seat = dseat, type = ret, time = timeout[1], card = drawCard, source = 0}
		
		deskInfo.actionInfo.iswait = 0
		deskInfo.actionInfo.prioritySeat = 0
		deskInfo.actionInfo.waitList = {}
		local isChongPao
		local duser = seleteUserInfo(dseat,"seat")
		local noty_retobj  = {}
		if ret == hongheitool.cardType.kan then
			delteHandIncards(duser,drawCard)
			delteHandIncards(duser,drawCard)
			local kanType = hongheitool.cardType.kan
			local info = {}
			info.type = hongheitool.cardType.kan
			info.card = drawCard
			table.insert(duser.menzi,info)

			
			if hongheitool.findCard(duser.notPengPai,drawCard) then
				isJiu = drawCard
			end

			noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_KAN
			noty_retobj.kanType = kanType
			
			deskInfo.actionInfo.nextaction = {seat = duser.seat,type = hongheitool.cardType.put}
			CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
		elseif ret == hongheitool.cardType.long then
			noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_TILONG
			noty_retobj.ishand = 0 --是不是手上的
			isChongPao = getMenziPaoOrlongOrShe(duser)
			if isChongPao then
				local nextSeat = getNextSeat(duser.seat)
				deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			else
				deskInfo.actionInfo.nextaction = {seat = duser.seat,type = hongheitool.cardType.put}
				CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
			end
			
			for i, info in pairs(duser.menzi) do
				if info.type == hongheitool.cardType.kan then
					duser.menzi[i].type = hongheitool.cardType.long
					break
				end
			end
		elseif ret == hongheitool.cardType.handlong then
			noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_TILONG
			noty_retobj.ishand = 1 --手上的坎提的龙
			isChongPao = getMenziPaoOrlongOrShe(duser)
			if isChongPao then
				local nextSeat = getNextSeat(duser.seat)
				deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			else
				deskInfo.actionInfo.nextaction = {seat = duser.seat,type = hongheitool.cardType.put}
				CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
			end
			local info = {}
			info.type = hongheitool.cardType.long
			info.card = drawCard
			table.insert(duser.menzi,info)
			delteHandIncards(duser,drawCard)
			delteHandIncards(duser,drawCard)
			delteHandIncards(duser,drawCard)
			
		elseif ret == hongheitool.cardType.pao then
			noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PAO
			noty_retobj.ishand = 0 --是不是手上的
			isChongPao = getMenziPaoOrlongOrShe(duser)
			if isChongPao then
				local nextSeat = getNextSeat(duser.seat)
				deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			else
				deskInfo.actionInfo.nextaction = {seat = duser.seat,type = hongheitool.cardType.put}
				CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
			end
			for i, info in pairs(duser.menzi) do
				if info.type == hongheitool.cardType.kan or info.type == hongheitool.cardType.peng then
					if info.card == drawCard then
						duser.menzi[i].type = hongheitool.cardType.pao
						
						break
					end
				end
			end
		elseif ret == hongheitool.cardType.handpao then
			noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PAO
			noty_retobj.ishand = 1 --是不是手上的
			isChongPao = getMenziPaoOrlongOrShe(duser)
			if isChongPao then
				local nextSeat = getNextSeat(duser.seat)
				deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			else
				deskInfo.actionInfo.nextaction = {seat = duser.seat,type = hongheitool.cardType.put}
				CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
			end
			local info = {}
			info.type = hongheitool.cardType.pao
			info.card = drawCard
			table.insert(duser.menzi,info)
			delteHandIncards(duser,drawCard)
			delteHandIncards(duser,drawCard)
			delteHandIncards(duser,drawCard)
			
		elseif ret == hongheitool.cardType.hupai then
			local isZimo = nil
			if dseat == user.seat then --自摸胡牌 + 胡息 3
				huXi = huXi + 3
				isZimo = true
			end
			hupaiBance(dseat,drawCard,huXi,nil,huCards,isZimo)
			return 
		end
		
		noty_retobj.code   = PDEFINE.RET.SUCCESS
	    noty_retobj.gameid = deskInfo.gameid
	    noty_retobj.seat   = duser.seat
	    noty_retobj.actionInfo = table.copy(deskInfo.actionInfo)

	    --如果抓的是坎的话并且不是扫旧 --不用下发改牌的值
	    hongheitool.setHuXi(duser)
		-- if noty_retobj.c == PDEFINE.NOTIFY.NOTIFY_HZ_KAN then
	 --    	if not noty_retobj.isJiu then
	 --    		local kanCard = deskInfo.actionInfo.curaction.card
		-- 		for _, muser in pairs(deskInfo.users) do
		-- 			if muser.seat ~= dseat then
		-- 				noty_retobj.actionInfo.curaction.card = 0
		-- 				noty_retobj.menzi = getOherMemzi(duser)
		-- 				noty_retobj.huxi = duser.ohterRoundHuXi
		-- 			else
		-- 				noty_retobj.actionInfo.curaction.card = kanCard
		-- 				noty_retobj.menzi = duser.menzi
		-- 				noty_retobj.huxi = duser.roundHuXi
		-- 			end
		-- 			if muser.cluster_info  and muser.ofline == 0 then
		-- 				pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
		-- 			end
		-- 		end
		-- 		return
		-- 	end
		-- end
		-- if noty_retobj.c == PDEFINE.NOTIFY.NOTIFY_HZ_TILONG then
	 --    	local kanCard = deskInfo.actionInfo.curaction.card
		-- 	for _, muser in pairs(deskInfo.users) do
		-- 		if muser.seat ~= dseat then
		-- 			noty_retobj.actionInfo.curaction.card = 0
		-- 			noty_retobj.menzi = getOherMemzi(duser)
		-- 			noty_retobj.huxi = duser.ohterRoundHuXi
		-- 		else
		-- 			noty_retobj.actionInfo.curaction.card = kanCard
		-- 			noty_retobj.menzi = duser.menzi
		-- 			noty_retobj.huxi = duser.roundHuXi
		-- 		end
		-- 		if muser.cluster_info  and muser.ofline == 0 then
		-- 			pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
		-- 		end
		-- 	end
		-- 	return
		-- end
		for _, muser in pairs(deskInfo.users) do
			if muser.seat ~= dseat then
				if noty_retobj.c == PDEFINE.NOTIFY.NOTIFY_HZ_KAN or noty_retobj.c == PDEFINE.NOTIFY.NOTIFY_HZ_TILONG then
					if not isJiu then
						noty_retobj.actionInfo.curaction.card = 0
					else
						noty_retobj.actionInfo.curaction.card = drawCard
					end
				end
				noty_retobj.menzi = getOherMemzi(duser)
				noty_retobj.huxi = duser.ohterRoundHuXi
			else
				noty_retobj.menzi = duser.menzi
				noty_retobj.huxi = duser.roundHuXi
				if noty_retobj.c == PDEFINE.NOTIFY.NOTIFY_HZ_KAN or noty_retobj.c == PDEFINE.NOTIFY.NOTIFY_HZ_TILONG then
					noty_retobj.actionInfo.curaction.card = drawCard
				end
			end
			if muser.cluster_info  and muser.ofline == 0 then
				pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
			end
		end
		if isChongPao then
			setTimeOut()
	    	local nextSeat = getNextSeat(duser.seat)
	    	draw(nextSeat)
		end
	else
		local noty_retobj  = {}
	    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PUT
	    noty_retobj.code   = PDEFINE.RET.SUCCESS
	    noty_retobj.gameid = deskInfo.gameid
	    noty_retobj.seat   = user.seat
	    deskInfo.actionInfo.curaction = {seat = user.seat, type = hongheitool.cardType.put,time = timeout[1], card = drawCard, source = 0}

	    if deskInfo.actionInfo.iswait == 1 then
			for _, muser in pairs(deskInfo.users) do
		    	if deskInfo.actionInfo.waitList[muser.seat] then
		    		local actionInfo = {}
		    		actionInfo.curaction = deskInfo.actionInfo.curaction
		    		actionInfo.nextaction = deskInfo.actionInfo.nextaction
		    		actionInfo.iswait = 1
		    		actionInfo.waitList = deskInfo.actionInfo.waitList[muser.seat]
		    		noty_retobj.actionInfo = actionInfo
		    		if muser.ofline == 0 then
						pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
					end
					CMD.userSetAutoState("autoPass",timeout[1]*100,muser.seat)
				else
					local actionInfo = {}
		    		actionInfo.curaction = deskInfo.actionInfo.curaction
		    		actionInfo.nextaction = deskInfo.actionInfo.nextaction
		    		actionInfo.iswait = 1
		    		actionInfo.waitList = {}
		    		noty_retobj.actionInfo = actionInfo
		    		if muser.ofline == 0 then
						pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
					end
		    	end
		    end
		else
			deskInfo.actionInfo.curaction = {seat = user.seat, type = hongheitool.cardType.put, time = timeout[1], card = drawCard, source = 0 }
			table.insert(user.qipai,drawCard)
			table.insert(user.notChiPai,drawCard)
			local noty_retobj  = {}
			noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PUT
		    noty_retobj.code   = PDEFINE.RET.SUCCESS
		    noty_retobj.gameid = deskInfo.gameid
		    noty_retobj.seat   = user.seat
		    noty_retobj.actionInfo = deskInfo.actionInfo
		    setTimeOut()
			broadcastDesk(cjson.encode(noty_retobj))

			local nextSeat = getNextSeat(user.seat)
			setTimeOut()
			draw(nextSeat)
		end
	    
	end
end


-- 取出牌
local function getCard(buck) --庄家多抓一张
	setDeskBase()
	local userscard = {}
	for i = 1, 3 do
		userscard[i] = {}
	end

	for i = 1 ,3 do
		for j=1,20 do 
			table.insert(userscard[i],new_card[j])
			table.remove(new_card,j)
		end
		if buck == i then --庄家多发一张
			table.insert(userscard[i],new_card[1])
			table.remove(new_card,1)
		end
	end
	return userscard
end


-- 寻找下一个座位号
local function findNextSeat(seat)
	local seat = seat
	if seat == #deskInfo.users + 1 then
		seat = 1
	end
	local user = seleteUserInfo(seat,"seat")
	if user then
		return user.seat
	end
	return findNextSeat(seat + 1)
end 

--过的时候删除操作信息
local function modifWaitList(seat)
	deskInfo.actionInfo.waitList[seat] = nil
	if table.size(deskInfo.actionInfo.waitList) == 0 then
		deskInfo.actionInfo.iswait = 0
		deskInfo.actionInfo.prioritySeat = 0
	end
end

local function findActionUser(seat)
	for _, info in pairs(waitAction) do
		if info.seat == seat then
			return true
		end
	end
end 

--校验优先级
local function compWaitList(seat,msg)
	if #waitAction == table.size(deskInfo.actionInfo.waitList) then
		return true
	end
	if table.size(deskInfo.actionInfo.waitList) == 1 then
		return true
	else
		--先检测整个待定区能不能碰
		local isPeng
		for dst, waitUsers in pairs(deskInfo.actionInfo.waitList) do
			for _, waitInfo in pairs(waitUsers) do
				if waitInfo.type == hongheitool.cardType.peng then
					isPeng = dst
					break
				end
			end
		end
		if isPeng then
			if isPeng == seat then
				local level
				for _, info in pairs(deskInfo.actionInfo.waitList[seat]) do
					if info.type == hongheitool.cardType.chi then
						local user = seleteUserInfo(seat,"seat")
						if info.level == 2 then
							table.insert(user.notPengPai,card)
							return true
						else
							if not findActionUser(seat) then
								local actInfo = {}
								actInfo.seat = seat
								actInfo.level = info.level
								actInfo.msg = msg
								table.insert(waitAction,actInfo)
								table.insert(user.notPengPai,card)
							end
						end
					end
				end
				if #waitAction == table.size(deskInfo.actionInfo.waitList) then
					table.sort(waitAction,function(a,b) return a.level > b.level end)
					CMD.chiPai(_,waitAction[1].msg,2)
					return false
				end
			else
				for _, info in pairs(deskInfo.actionInfo.waitList[seat]) do --别的玩家能碰 主动降低优先级
					if info.type == hongheitool.cardType.chi then
						if not findActionUser(seat) then
							local actInfo = {}
							actInfo.seat = seat
							actInfo.level = 1
							actInfo.msg = msg
							table.insert(waitAction,actInfo)
						end
						
					end
				end
				if #waitAction == table.size(deskInfo.actionInfo.waitList) then
					table.sort(waitAction,function(a,b) return a.level > b.level end)
					CMD.chiPai(_,waitAction[1].msg,3)
					return false
				end
			end
		else
			for _, info in pairs(deskInfo.actionInfo.waitList[seat]) do
				if info.type == hongheitool.cardType.chi then
					if info.level == 2 then
						return true
					else
						if not findActionUser(seat) then
							local actInfo = {}
							actInfo.seat = seat
							actInfo.level = info.level
							actInfo.msg = msg
							table.insert(waitAction,actInfo)
						end
						
					end
				end
			end
			if #waitAction == table.size(deskInfo.actionInfo.waitList) then
				table.sort(waitAction,function(a,b) return a.level > b.level end)
				CMD.chiPai(_,waitAction[1].msg,4)
				return false
			end
		end
	end
end

function CMD.exit()
	collectgarbage("collect")
	skynet.exit()
end


local function autoPut(seat)
	local user = seleteUserInfo(seat,"seat")
	--判断打牌者是否这个用户
	if deskInfo.actionInfo.nextaction.seat ~= user.seat or deskInfo.actionInfo.nextaction.type ~= hongheitool.cardType.put then
		return PDEFINE.RET.ERROR.NO_ACTION_ERROR
	end
	user.autoc = user.autoc + 1
	local card = delteHandIncards(user)
	if card then
		deskInfo.actionInfo.curaction.seat = user.seat
		deskInfo.actionInfo.curaction.card = card
		deskInfo.actionInfo.curaction.type = hongheitool.cardType.put
		deskInfo.actionInfo.curaction.source = user.seat
		table.insert(user.notChiPai,card)
	else
		return PDEFINE.RET.ERROR.NO_ACTION_ERROR
	end
	deskInfo.actionInfo.nextaction = {seat = 0, type = 0}

	
	-- 通知其它玩家打牌
	local ret,dseat = checkPengGangHu(card,user.uid,hongheitool.lpType.put)
	if ret then
		local noty_retobj  = {}
	    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PUT
	    noty_retobj.code   = PDEFINE.RET.SUCCESS
	    noty_retobj.gameid = deskInfo.gameid
	    noty_retobj.seat   = user.seat
	    noty_retobj.actionInfo = deskInfo.actionInfo
	    broadcastDesk(cjson.encode(noty_retobj))

		deskInfo.actionInfo.curaction = {seat = dseat, type = ret, time = timeout[1], card = card, source = user.seat}
		deskInfo.actionInfo.iswait = 0
		deskInfo.actionInfo.prioritySeat = 0
		deskInfo.actionInfo.waitList = {}
		local isChongPao
		local duser = seleteUserInfo(dseat,"seat")
		local noty_retobj  = {}
		if ret == hongheitool.cardType.pao or ret == hongheitool.cardType.handpao then
			noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PAO
			isChongPao = getMenziPaoOrlongOrShe(duser)
			if ret == hongheitool.cardType.pao then
				noty_retobj.ishand = 0 --是不是手上的
				for i, info in pairs(duser.menzi) do
					if info.type == hongheitool.cardType.kan or info.type == hongheitool.cardType.peng then
						if info.card == card then
							duser.menzi[i].type = hongheitool.cardType.pao
							break
						end
					end
				end
			else
				noty_retobj.ishand = 1 --是不是手上的
				local info = {}
				info.type = hongheitool.cardType.pao
				info.card = card
				table.insert(duser.menzi,info)
				delteHandIncards(duser,card)
				delteHandIncards(duser,card)
				delteHandIncards(duser,card)
			end

			noty_retobj.code   = PDEFINE.RET.SUCCESS
		    noty_retobj.gameid = deskInfo.gameid
		    noty_retobj.seat   = duser.seat
		    noty_retobj.actionInfo = deskInfo.actionInfo
		    noty_retobj.huxi = hongheitool.setHuXi(duser)
		    if isChongPao then
		    	local nextSeat = getNextSeat(duser.seat)
				deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
				broadcastDesk(cjson.encode(noty_retobj))
				setTimeOut()
				draw(nextSeat)
				return PDEFINE.RET.SUCCESS
			else
				deskInfo.actionInfo.nextaction = {seat = duser.seat,type = hongheitool.cardType.put}
				broadcastDesk(cjson.encode(noty_retobj))
				CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
			end
		else
			table.insert(user.notChiPai,card)
		end
		return PDEFINE.RET.SUCCESS
	else
		local noty_retobj  = {}
	    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PUT
	    noty_retobj.code   = PDEFINE.RET.SUCCESS
	    noty_retobj.gameid = deskInfo.gameid
	    noty_retobj.seat   = user.seat
	    if deskInfo.actionInfo.iswait == 1 then
	    	for _, muser in pairs(deskInfo.users) do
		    	if deskInfo.actionInfo.waitList[muser.seat] then
		    		local actionInfo = {}
		    		actionInfo.curaction = deskInfo.actionInfo.curaction
		    		actionInfo.nextaction = deskInfo.actionInfo.nextaction
		    		actionInfo.iswait = 1
		    		actionInfo.waitList = deskInfo.actionInfo.waitList[muser.seat]
		    		noty_retobj.actionInfo = actionInfo
		    		if muser.ofline == 0 then
						pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
					end
					CMD.userSetAutoState("autoPass",timeout[1]*100,muser.seat)
				else
					local actionInfo = {}
		    		actionInfo.curaction = deskInfo.actionInfo.curaction
		    		actionInfo.nextaction = deskInfo.actionInfo.nextaction
		    		actionInfo.iswait = 1
		    		actionInfo.waitList = {}
		    		noty_retobj.actionInfo = actionInfo
		    		if muser.ofline == 0 then
						pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
					end
		    	end
		    end
		    return PDEFINE.RET.SUCCESS
		else
			--没有对该牌进行操作的 就设置摸排玩家
			local nextSeat = getNextSeat(user.seat)
			deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			deskInfo.actionInfo.curaction = {seat = user.seat, type = hongheitool.cardType.put, time = timeout[1], card = card, source = user.seat}
			deskInfo.actionInfo.iswait = 0
			deskInfo.actionInfo.waitList = {}
			noty_retobj.actionInfo = deskInfo.actionInfo
	    	broadcastDesk(cjson.encode(noty_retobj))

	    	setTimeOut()
	    	draw(nextSeat)
	    end
	end
    
end



local function autoPass(seat)
	local user = seleteUserInfo(seat,"seat")
	for _,info in pairs(deskInfo.actionInfo.waitList[user.seat]) do
		if info.type == hongheitool.cardType.peng then
			table.insert(user.notPengPai,deskInfo.actionInfo.curaction.card)
		end
		if info.type == hongheitool.cardType.chi then
			table.insert(user.notChiPai,deskInfo.actionInfo.curaction.card)
		end
	end
	user.autoc = user.autoc + 1
	local actInfo = {}
	actInfo.seat = seat
	actInfo.level = 0
	actInfo.msg = msg
	table.insert(waitAction,actInfo)


	if #waitAction == table.size(deskInfo.actionInfo.waitList) then
		table.sort(waitAction,function(a,b) return a.level > b.level end)
		if waitAction[1].level > 0 then
			CMD.chiPai(_,waitAction[1].msg,5)
		else
			local nextSeat = getNextSeat(deskInfo.actionInfo.curaction.seat)
			if deskInfo.actionInfo.curaction.source > 0 then
				local putUser = seleteUserInfo(deskInfo.actionInfo.curaction.source,"seat")
				table.insert(putUser.qipai,deskInfo.actionInfo.curaction.card)
			else
				local drawUser = seleteUserInfo(deskInfo.actionInfo.curaction.seat,"seat")
				table.insert(drawUser.qipai,deskInfo.actionInfo.curaction.card)
			end
			deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			deskInfo.actionInfo.iswait = 0
			deskInfo.actionInfo.waitList = {}
			local noty_retobj  = {}
		    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PASS
		    noty_retobj.code   = PDEFINE.RET.SUCCESS
		    noty_retobj.gameid = deskInfo.gameid
		    noty_retobj.seat   = user.seat
		    noty_retobj.actionInfo = deskInfo.actionInfo
		    waitAction = {}
		    broadcastDesk(cjson.encode(noty_retobj))
		    setTimeOut()
		    draw(nextSeat)
		end
	end
	-- modifWaitList(user.seat)
	-- if deskInfo.actionInfo.iswait == 0 then
	-- 	local nextSeat = getNextSeat(deskInfo.actionInfo.curaction.seat)
	-- 	table.insert(user.qipai,deskInfo.actionInfo.curaction.card)
	-- 	deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
	-- 	deskInfo.actionInfo.iswait = 0
	-- 	deskInfo.actionInfo.waitList = {}
	-- 	local noty_retobj  = {}
	--     noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PASS
	--     noty_retobj.code   = PDEFINE.RET.SUCCESS
	--     noty_retobj.gameid = deskInfo.gameid
	--     noty_retobj.seat   = user.seat
	--     noty_retobj.actionInfo = deskInfo.actionInfo
	--     broadcastDesk(cjson.encode(noty_retobj))
	--     if #new_card == 0 then
	--     	hupaiBance(-1,-1,hongheitool.HUPAI_TYPE.liuju)
	-- 		return PDEFINE.RET.SUCCESS
	-- 	end
	--     draw(nextSeat)
	-- else
	-- 	if #waitAction >= 1 then
	-- 		CMD.chiPai(_,waitAction[1])
	-- 	end
	-- end
end

local function autoPeng(seat)

end

local function user_set_timeout(ti, f,parme)
	local function t()
	    if f then 
	    	f(parme)
	    end
	 end
	skynet.timeout(ti, t)
	return function(parme) f=nil end
end

local function autoDissolve(isTimeOut)
	local noty_retobj    = {}
	noty_retobj.c        = PDEFINE.NOTIFY.succeddissolve
	noty_retobj.code     = PDEFINE.RET.SUCCESS
	noty_retobj.isShowJieSuan = isTimeOut
	broadcastDesk(cjson.encode(noty_retobj))
	if isTimeOut == 1 then 
		hupaiBance(deskInfo.actionInfo.curaction.seat,deskInfo.actionInfo.curaction.card,hongheitool.HUPAI_TYPE.liuju,true)
	else
		big_over()
	end
end

-- 创建桌子
function CMD.create(source,cluster_info,recvobj,ip,deskId,lat,lng) 
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo(uid,"uid")
	local gameInfo = recvobj.gameInfo
	CMD.initDeskConfig(_, gameInfo, deskId)
	
	
	local playerInfo = getPlayerInfo(uid)

	local seat = getSeatId()
	if not seat then
 		return PDEFINE.RET.ERROR.SEATID_EXIST
 	end
 	
 	deskInfo.conf.curseat = deskInfo.conf.curseat + 1
	local userInfo = {}
	userInfo.cluster_info = cluster_info
	userInfo.score = 0 --总分数
	userInfo.roundScore = 0 --每一局的分数
	userInfo.totalHuXi = 0 --总硬息
	userInfo.roundHuXi = 0 --每一小局显示的胡息
	userInfo.ohterRoundHuXi = 0
	userInfo.mingTangCount = 0 --总名堂次数
	userInfo.sex = playerInfo.sex
	userInfo.usericon = playerInfo.usericon
	userInfo.playername = serializePlayername(playerInfo.playername)
	userInfo.tingPaiInfo = {}
	--userInfo.dianPaoCount = 0
	userInfo.huPaiCount = 0
	--userInfo.zhongZhangCount = 0
	userInfo.uid = uid
	userInfo.lat = lat
	userInfo.lng = lng
	userInfo.state = 0
	userInfo.ofline = 0
	userInfo.menzi = {}
	userInfo.qipai = {}
	userInfo.notChiPai = {}
	userInfo.notPengPai = {}
	userInfo.handInCards = {}
	userInfo.autoc = 0
	userInfo.ip = ip
	userInfo.seat = seat
	table.insert(deskInfo.users,userInfo)
	deskInfo.locatingList,gpsColour = hongheitool.jisuanXY(deskInfo.users)

	local retobj  = {}
    retobj.c      = PDEFINE.NOTIFY.join
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.gameid = deskInfo.conf.gameid
    retobj.deskId   = deskInfo.conf.deskId
    retobj.gpsColour = gpsColour
    retobj.user = { uid = uid , state = 0, seat = userInfo.seat, state = userInfo.state,score = userInfo.score, sex = playerInfo.sex, playername = userInfo.playername, usericon= playerInfo.usericon}
    broadcastDesk(cjson.encode(retobj))
    --需要去掉其它玩家的手牌
    user_set_timeout(100,notyGpsColour)
    
    deskAutoFuc = user_set_timeout(PDEFINE_GAME.GAME_PARAM.DISS_TIME*100,autoDissolve,0)
	return PDEFINE.RET.SUCCESS,deskInfo,retobj.user
end

-- 加入桌子
function CMD.join(source,cluster_info,recvobj,ip,lat,lng)
	return cs(function ()
		local uid = math.floor(recvobj.uid)
		local user = seleteUserInfo(uid,"uid")
		if user then
			return PDEFINE.RET.SUCCESS,deskInfo
		end
		local deskid = recvobj.deskId
		if deskid ~= deskInfo.conf.deskId then
			return PDEFINE.RET.ERROR.DESKID_FAIL
		end
		if deskInfo.conf.distance == 1 then
			if not hongheitool.checkDistance(lat,lng,deskInfo.users) then
				return PDEFINE.RET.ERROR.DISTANCE_EXIST
			end
		end

		if deskInfo.conf.ipcheck == 1 then
			if not hongheitool.checkIp(ip,deskInfo.users) then
				return PDEFINE.RET.ERROR.CHECK_IP
			end
		end
		
		
		local playerInfo = getPlayerInfo(uid)

		local seat = getSeatId()
		if not seat then
	 		return PDEFINE.RET.ERROR.SEATID_EXIST
	 	end
	 	deskInfo.conf.curseat = deskInfo.conf.curseat + 1
		local userInfo = {}
		userInfo.cluster_info = cluster_info
		userInfo.tingPaiInfo = {}
		userInfo.score = 0 --总分数
		userInfo.roundScore = 0 --每一局的分数
		userInfo.totalHuXi = 0 --总硬息
		userInfo.roundHuXi = 0 --每一小局显示的胡息
		userInfo.ohterRoundHuXi = 0
		userInfo.mingTangCount = 0 --总名堂次数
		userInfo.sex = playerInfo.sex
		userInfo.usericon = playerInfo.usericon
		userInfo.playername = serializePlayername(playerInfo.playername)
		--userInfo.dianPaoCount = 0
		userInfo.huPaiCount = 0
		--userInfo.zhongZhangCount = 0
		userInfo.uid = uid
		userInfo.lat = lat
		userInfo.lng = lng
		userInfo.state = 0
		userInfo.ofline = 0
		userInfo.menzi = {}
		userInfo.qipai = {}
		userInfo.notChiPai = {}
		userInfo.notPengPai = {}
		userInfo.handInCards = {}
		userInfo.autoc = 0
		userInfo.ip = ip
		userInfo.seat = seat
		table.insert(deskInfo.users,userInfo)
		deskInfo.locatingList,gpsColour = hongheitool.jisuanXY(deskInfo.users)

		local retobj  = {}
	    retobj.c      = PDEFINE.NOTIFY.join
	    retobj.code   = PDEFINE.RET.SUCCESS
	    retobj.gameid = deskInfo.conf.gameid
	    retobj.deskId   = deskInfo.conf.deskId
	    retobj.gpsColour = gpsColour
	    retobj.user = { uid = uid , state = 0, seat = userInfo.seat, state = userInfo.state,score = userInfo.score, sex = playerInfo.sex, playername = userInfo.playername, usericon= playerInfo.usericon}
	    broadcastDesk(cjson.encode(retobj))
	    --需要去掉其它玩家的手牌
	    user_set_timeout(100,notyGpsColour)
		return PDEFINE.RET.SUCCESS,deskInfo
	end)
end

function CMD.cancelAuto(source,msg)
	local recvobj  = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo(uid,"uid")
	user.autoc = 0
	local retobj  = {}
	retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_CANCE
	retobj.code   = PDEFINE.RET.SUCCESS
	retobj.gameid = deskInfo.gameid
	retobj.seat   = user.seat
	retobj.uid   = uid
	broadcastDesk(cjson.encode(retobj))
	return PDEFINE.RET.SUCCESS 
end
-- 碰 
function CMD.peng(source,msg)
	local recvobj  = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo()
	local pcard = deskInfo.actionInfo.curaction.card
	local user = seleteUserInfo(uid,"uid")
	local waitList = deskInfo.actionInfo.waitList[user.seat]
	--local pengType = hongheitool.cardType.peng
	local pengInfo = {}
	if hongheitool.getValueCount(user.handInCards,pcard) == 2 then
		local info = {}
		info.type = hongheitool.cardType.peng
		info.card = pcard
		info.source = deskInfo.actionInfo.curaction.source
		closeAllTimer()
		for _, waitInfo in pairs(waitList) do
			if waitInfo.type == hongheitool.cardType.peng then
				if pcard == waitInfo.data then
					-- if info.source > 0 then
					-- 	local putUser = seleteUserInfo(info.source,"seat")
					-- 	table.insert(putUser.qipai,card)
					-- end
					table.insert(user.menzi,info)
					break
				end
			end
		end

		waitAction = {}
		delteHandIncards(user,pcard)
		delteHandIncards(user,pcard)
		deskInfo.actionInfo.curaction = {seat = user.seat, type = hongheitool.cardType.peng, time = timeout[1], card = deskInfo.actionInfo.curaction.card, source = deskInfo.actionInfo.curaction.source}
		deskInfo.actionInfo.nextaction = {seat = user.seat,type = hongheitool.cardType.put}
		deskInfo.actionInfo.iswait = 0
		deskInfo.actionInfo.waitList = {}
		local noty_retobj  = {}
	    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PENG
	    noty_retobj.code   = PDEFINE.RET.SUCCESS
	    noty_retobj.gameid = deskInfo.gameid
	    noty_retobj.seat   = user.seat
	    noty_retobj.pengType = hongheitool.cardType.peng
	    noty_retobj.actionInfo = deskInfo.actionInfo
	    hongheitool.setHuXi(user)
	    for _, muser in pairs(deskInfo.users) do
			if muser.seat ~= user.seat then
				noty_retobj.huxi = user.ohterRoundHuXi
			else
				noty_retobj.huxi = user.roundHuXi
			end
			if muser.cluster_info  and muser.ofline == 0 then
				pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
			end
		end

		return PDEFINE.RET.SUCCESS
	else
		return PDEFINE.RET.ERROR.NO_ACTION_ERROR
	end
	
	
end



-- chi
function CMD.chiPai(source,msg,isLocal)
	local recvobj  = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local chi = recvobj.chi.chiData
	local luo = recvobj.chi.luoData
	local chiData = {}
	local user = seleteUserInfo(uid,"uid")
	
	local waitList = deskInfo.actionInfo.waitList[user.seat]
	if not waitList then
		return PDEFINE.RET.ERROR.NO_ACTION_ERROR
	end
	if usersAutoFuc[user.seat] then 
		usersAutoFuc[user.seat](user.seat)
	end
	if compWaitList(user.seat,msg) then
		for _, waitInfo in pairs(waitList) do
			if waitInfo.type == hongheitool.cardType.chi then
				for _, info in pairs(waitInfo.data) do
					if info.chiData[1] == chi[1] and info.chiData[2] == chi[2] then
						chiData[1] = info.chiData[1]
						chiData[2] = info.chiData[2]
						chiData[3] = deskInfo.actionInfo.curaction.card
						break
					end
				end
			end
		end

		local infoData = {}
		infoData.type = hongheitool.cardType.chi
		infoData.data = chiData
		table.insert(user.menzi,infoData)

		delteHandIncards(user,chiData[1])
		delteHandIncards(user,chiData[2])

		--删除落的牌
		for _, info in pairs(luo) do
			local luoData = {}
			local luoInfo = {}
			luoInfo.type = hongheitool.cardType.chi
			luoData[1] = info[1]
			luoData[2] = info[2]
			luoData[3] = info[3]
			luoInfo.data = luoData
			table.insert(user.menzi,luoInfo)

			delteHandIncards(user,info[1])
			delteHandIncards(user,info[2])
			delteHandIncards(user,info[3])
		end
		closeAllTimer()
		local chiInfo = {}
		chiInfo.chiData = chiData
		chiInfo.luoData = luo
		waitAction = {}
		deskInfo.actionInfo.curaction = {seat = user.seat, type = hongheitool.cardType.chi, time = timeout[1], card = deskInfo.actionInfo.curaction.card}
		
		deskInfo.actionInfo.nextaction = {seat = user.seat,type = hongheitool.cardType.put}
		deskInfo.actionInfo.iswait = 0
		deskInfo.actionInfo.waitList = {}
		local noty_retobj  = {}
	    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_CHI
	    noty_retobj.code   = PDEFINE.RET.SUCCESS
	    noty_retobj.gameid = deskInfo.gameid
	    noty_retobj.seat   = user.seat
	    noty_retobj.chiInfo = chiInfo
	    noty_retobj.actionInfo = deskInfo.actionInfo
	    hongheitool.setHuXi(user)
	    for _, muser in pairs(deskInfo.users) do
			if muser.seat ~= user.seat then
				noty_retobj.huxi = user.ohterRoundHuXi
			else
				noty_retobj.huxi = user.roundHuXi
			end
			if muser.cluster_info  and muser.ofline == 0 then
				pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
			end
		end
	end
	return PDEFINE.RET.SUCCESS
end



-- 打牌
function CMD.put(source,msg)
	local recvobj  = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local card = math.floor(recvobj.card)

	local user = seleteUserInfo(uid,"uid")
	--判断打牌者是否这个用户
	if deskInfo.actionInfo.nextaction.seat ~= user.seat or deskInfo.actionInfo.nextaction.type ~= hongheitool.cardType.put then
		return PDEFINE.RET.ERROR.NO_ACTION_ERROR
	end
	user.autoc = 0
	if delteHandIncards(user,card) then
		deskInfo.actionInfo.curaction.seat = user.seat
		deskInfo.actionInfo.curaction.card = card
		deskInfo.actionInfo.curaction.type = hongheitool.cardType.put
		deskInfo.actionInfo.curaction.source = user.seat
		table.insert(user.notChiPai,card)
	else
		return PDEFINE.RET.ERROR.NO_ACTION_ERROR
	end

	--这里通知下是不是有蛇要放下去 TODO
	closeAllTimer()
	deskInfo.actionInfo.nextaction = {seat = 0, type = 0}
	notyTingPaiInfo(user)
	
	-- 通知其它玩家打牌
	local ret,dseat = checkPengGangHu(card,user.uid,hongheitool.lpType.put)
	if ret then
		local noty_retobj  = {}
	    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PUT
	    noty_retobj.code   = PDEFINE.RET.SUCCESS
	    noty_retobj.gameid = deskInfo.gameid
	    noty_retobj.seat   = user.seat
	    noty_retobj.actionInfo = deskInfo.actionInfo
	    broadcastDesk(cjson.encode(noty_retobj))

		deskInfo.actionInfo.curaction = {seat = dseat, type = ret, time = timeout[1], card = card, source = user.seat}
		
		deskInfo.actionInfo.iswait = 0
		deskInfo.actionInfo.prioritySeat = 0
		deskInfo.actionInfo.waitList = {}
		local isChongPao
		local duser = seleteUserInfo(dseat,"seat")
		local noty_retobj  = {}
		if ret == hongheitool.cardType.pao or ret == hongheitool.cardType.handpao then
			noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PAO
			isChongPao = getMenziPaoOrlongOrShe(duser)
			if ret == hongheitool.cardType.pao then
				noty_retobj.ishand = 0 --是不是手上的
				for i, info in pairs(duser.menzi) do
					if info.type == hongheitool.cardType.kan or info.type == hongheitool.cardType.peng then
						if info.card == card then
							duser.menzi[i].type = hongheitool.cardType.pao
							break
						end
					end
				end
			else
				noty_retobj.ishand = 1 --是不是手上的
				local info = {}
				info.type = hongheitool.cardType.pao
				info.card = card
				table.insert(duser.menzi,info)
				delteHandIncards(duser,card)
				delteHandIncards(duser,card)
				delteHandIncards(duser,card)
			end
			local nextSeat
			if isChongPao then
		    	nextSeat = getNextSeat(duser.seat)
				deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			else
				deskInfo.actionInfo.nextaction = {seat = duser.seat,type = hongheitool.cardType.put}
				CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
			end
			setTimeOut()
			noty_retobj.code   = PDEFINE.RET.SUCCESS
		    noty_retobj.gameid = deskInfo.gameid
		    noty_retobj.seat   = duser.seat
		    noty_retobj.actionInfo = deskInfo.actionInfo
		    hongheitool.setHuXi(duser)
		    
			for _, muser in pairs(deskInfo.users) do
				if muser.seat ~= duser.seat then
					noty_retobj.huxi = duser.ohterRoundHuXi
					noty_retobj.menzi = getOherMemzi(duser)
				else
					noty_retobj.huxi = duser.roundHuXi
					noty_retobj.menzi = duser.menzi
				end
				if muser.cluster_info  and muser.ofline == 0 then
					pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
				end
			end
			if isChongPao then
				setTimeOut()
				draw(nextSeat)
			end
		else
			table.insert(user.notChiPai,card)
		end
		return PDEFINE.RET.SUCCESS
	else
		local noty_retobj  = {}
	    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PUT
	    noty_retobj.code   = PDEFINE.RET.SUCCESS
	    noty_retobj.gameid = deskInfo.gameid
	    noty_retobj.seat   = user.seat
	    if deskInfo.actionInfo.iswait == 1 then
	    	for _, muser in pairs(deskInfo.users) do
		    	if deskInfo.actionInfo.waitList[muser.seat] then
		    		local actionInfo = {}
		    		actionInfo.curaction = deskInfo.actionInfo.curaction
		    		actionInfo.nextaction = deskInfo.actionInfo.nextaction
		    		actionInfo.iswait = 1
		    		actionInfo.waitList = deskInfo.actionInfo.waitList[muser.seat]
		    		noty_retobj.actionInfo = actionInfo
		    		if muser.ofline == 0 then
						pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
					end
					CMD.userSetAutoState("autoPass",timeout[1]*100,muser.seat)
				else
					local actionInfo = {}
		    		actionInfo.curaction = deskInfo.actionInfo.curaction
		    		actionInfo.nextaction = deskInfo.actionInfo.nextaction
		    		actionInfo.iswait = 1
		    		actionInfo.waitList = {}
		    		noty_retobj.actionInfo = actionInfo
		    		if muser.ofline == 0 then
						pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
					end
		    	end
		    end
		    return PDEFINE.RET.SUCCESS
		else
			--没有对该牌进行操作的 就设置摸排玩家
			local nextSeat = getNextSeat(user.seat)
			deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			deskInfo.actionInfo.curaction = {seat = user.seat, type = hongheitool.cardType.put, time = timeout[1], card = card, source = user.seat}
			deskInfo.actionInfo.iswait = 0
			deskInfo.actionInfo.waitList = {}
			noty_retobj.actionInfo = deskInfo.actionInfo
			table.insert(user.qipai,card)
	    	broadcastDesk(cjson.encode(noty_retobj))
	    	if #new_card == 0 then
	    		hupaiBance(user.seat,card,hongheitool.HUPAI_TYPE.liuju)
				return PDEFINE.RET.SUCCESS
			end
			setTimeOut()
	    	draw(nextSeat)
	    end
	end
    
	return PDEFINE.RET.SUCCESS
end

-- 准备游戏
local function autoReady(seat)
	local user = seleteUserInfo(seat,"seat")
	if deskInfo.smallState == 1 then
		return PDEFINE.RET.SUCCESS 
	end
	if user.state == 1 then
        return PDEFINE.RET.SUCCESS
    end
    if usersAutoFuc[seat] then 
		usersAutoFuc[seat](seat)
	end
	user.state = 1
	local retobj    = {}
    retobj.code     = PDEFINE.RET.SUCCESS
    retobj.c        = PDEFINE.NOTIFY.NOTIFY_READY
    retobj.uid      = user.uid
    retobj.seat   = user.seat
    broadcastDesk(cjson.encode(retobj))
    if #deskInfo.users == deskInfo.conf.seat then
	    for _, userReady in pairs(deskInfo.users) do  --判断所有玩家是否都已经准备
	        if userReady.state ~= 1 then
	            return PDEFINE.RET.SUCCESS
	        end
	    end
	    CMD.startGame()
	end
    return PDEFINE.RET.SUCCESS
end

function CMD.userSetAutoState(autoType,autoTime,seat)
	if deskInfo.conf.trustee == 1 then
		if usersAutoFuc[seat] then 
			usersAutoFuc[seat](seat)
		end
		local user = seleteUserInfo(seat,"seat")
		if user.autoc >= 2 then
	    	autoTime = timeout[5]*100
	    end
		if autoType == "autoPass" then
			usersAutoFuc[seat] = user_set_timeout(autoTime,autoPass,seat)
		elseif autoType == "autoReady" then
			usersAutoFuc[seat] = user_set_timeout(autoTime,autoReady,seat)
		elseif autoType == "autoPut" then
	        usersAutoFuc[seat] = user_set_timeout(autoTime, autoPut, seat)
	    elseif autoType == "autoPeng" then
	        usersAutoFuc[seat] = user_set_timeout(autoTime, autoPeng, seat)
	    end
	end
end

-- 过
function CMD.pass(source,msg)
	local recvobj  = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo(uid,"uid")
	user.autoc = 0
	if not deskInfo.actionInfo.waitList[user.seat] then
		return PDEFINE.RET.SUCCESS
	end
	if findActionUser(user.seat) then
		return PDEFINE.RET.SUCCESS
	end
	if usersAutoFuc[user.seat] then 
		usersAutoFuc[user.seat](user.seat)
	end
	
	local actInfo = {}
	actInfo.seat = user.seat
	actInfo.level = 0
	actInfo.msg = msg
	table.insert(waitAction,actInfo)

	for _,info in pairs(deskInfo.actionInfo.waitList[user.seat]) do
		if info.type == hongheitool.cardType.peng then
			table.insert(user.notPengPai,deskInfo.actionInfo.curaction.card)
		end
		if info.type == hongheitool.cardType.chi then
			table.insert(user.notChiPai,deskInfo.actionInfo.curaction.card)
		end
	end
	if #waitAction == table.size(deskInfo.actionInfo.waitList) then
		table.sort(waitAction,function(a,b) return a.level > b.level end)
		if waitAction[1].level > 0 then
			CMD.chiPai(_,waitAction[1].msg,1)
		else
			local nextSeat = getNextSeat(deskInfo.actionInfo.curaction.seat)

			if deskInfo.actionInfo.curaction.source > 0 then
				local putUser = seleteUserInfo(deskInfo.actionInfo.curaction.source,"seat")
				table.insert(putUser.qipai,deskInfo.actionInfo.curaction.card)
			else
				local drawUser = seleteUserInfo(deskInfo.actionInfo.curaction.seat,"seat")
				table.insert(drawUser.qipai,deskInfo.actionInfo.curaction.card)
			end
			deskInfo.actionInfo.nextaction = {seat = nextSeat,type = hongheitool.cardType.draw}
			deskInfo.actionInfo.iswait = 0
			deskInfo.actionInfo.waitList = {}
			local noty_retobj  = {}
		    noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PASS
		    noty_retobj.code   = PDEFINE.RET.SUCCESS
		    noty_retobj.gameid = deskInfo.gameid
		    noty_retobj.seat = user.seat
		    noty_retobj.actionInfo = deskInfo.actionInfo
		    waitAction = {}
		    broadcastDesk(cjson.encode(noty_retobj))
		    draw(nextSeat)
		end
	end

	return PDEFINE.RET.SUCCESS
end

--更新玩家的桌子信息
function CMD.updateUserClusterInfo(source, uid, agent)
    local user = seleteUserInfo(uid,"uid")
    if nil ~= user and user.cluster_info then
        user.cluster_info.address = agent
    end
end

-- 开始游戏
function CMD.startGame() --2种开始方式  庄家设置也不一样 
	if deskAutoFuc then deskAutoFuc() end
	--restartTime(timeout[2]) --重置桌子时间
	if deskInfo.bankerInfo.uid == 0 then
		initBankerInfo()
	end
	initDissolveInfo()
	getActionInfo()
	local notify_retobj = {}
	notify_retobj.c = PDEFINE.NOTIFY.start
	notify_retobj.code   = PDEFINE.RET.SUCCESS
    notify_retobj.gameid = PDEFINE.GAME_TYPE.ZIPAI_HONGHEIHU_SR
    notify_retobj.bankerInfo = deskInfo.bankerInfo
    notify_retobj.actionInfo = deskInfo.actionInfo
	local usersCard = getCard(deskInfo.bankerInfo.seat)
	notify_retobj.cardcnt   = #new_card
	deskInfo.cardcnt = #new_card

	waitAction = {}

	-- if #usersCard[1] == 15 then
	-- 	usersCard[1] = {102,103,103,104,104,105,105,203,203,205}
	-- 	usersCard[2] = {209,109,109,108,108,205,205,230}
	-- 	usersCard[3] = {209,109,109,108,108,205,205,230}
	-- 	usersCard[4] = {103,108,109,209,209,205,205,230}
	-- else
	-- 	usersCard[1] = {102,103,103,104,104,105,105,203,203,205}
	-- 	usersCard[2] = {209,109,109,108,108,205,205,230}
	-- 	usersCard[3] = {209,109,109,108,108,205,205,230}
	-- 	usersCard[4] = {103,108,109,209,209,205,205,230}
	-- end
	
	  -- if #usersCard[1] == 21 then
	 	-- usersCard[1] = {205,205,205,209,109,209,203,202,201,206,207,208,204,104,103,104,105,106,210,210,110}
		 --  usersCard[2] = {105,105,105,206,207,209,101,101,101,103,103,103}
	  -- else
	  --  	usersCard[1] =  {105,105,105,206,207,209,101,101,101,103,103,103}
	  --  	usersCard[2] = {205,205,205,209,109,209,203,202,201,206,207,208,204,104,103,104,105,106,210,210,110}
	  --  end
   --   new_card = {104,108,105,104}
	for index,user in pairs(deskInfo.users) do
		user.time = 0
		user.curTime = 0
		user.menzi = {}
		user.qipai = {}
		user.notChiPai = {}
		user.notPengPai = {}
		user.score = user.score + user.roundScore
		user.roundScore = 0
		user.handInCards = usersCard[user.seat]
		user.state = 2
	end

	deskInfo.smallBeginTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
	--检测天胡
	local hcard = nil
	local huXi = nil
	local ok = nil
	local hseat = nil
	local huCards = nil
	for _,user in pairs(deskInfo.users) do
		if #user.handInCards == 21 then
			local hupaiCards = {}
			for i = 1,20 do
				table.insert(hupaiCards,user.handInCards[i])
			end
			ok,huXi,huCards = hongheitool.checkPaoHuZiHu(user,hupaiCards,user.handInCards[21],user.uid)
			if huXi then
				hseat = user.seat
				hcard = user.handInCards[21]
				user.totalHu = huXi
				break
			end
		end
	end
	
	if deskInfo.round == 0 then
		beginTime = os.date("%m-%d %H:%M:%S", os.time())
	end
	deskInfo.round = deskInfo.round + 1
	for index,user in pairs(deskInfo.users) do
		notify_retobj.seat = user.seat
		notify_retobj.menzi = user.menzi
		notify_retobj.tianHuSeat = hseat
		notify_retobj.round = deskInfo.round
		notify_retobj.score = user.score
		for _,muser in pairs(deskInfo.users) do
			notify_retobj.handInCards = nil
			if user.uid == muser.uid then
				notify_retobj.handInCards = muser.handInCards
			end
			if muser.ofline == 0 then
				pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(notify_retobj))
			end
		end
	end

	for _, muser in pairs(deskInfo.users) do
		if deskInfo.actionInfo.nextaction.seat ~= muser.seat then
			notyTingPaiInfo(muser)
		end
	end
	if deskInfo.bigState == 0 then
		deskInfo.bigState = 1
	end
	deskInfo.smallState = 1
	
	if hseat  then
		hupaiBance(hseat,hcard,huXi + 3,nil,huCards,true)
	else
		--自动打牌
		CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
	end
end



-- 准备游戏
function CMD.ready(source,msg)
	local recvobj  = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo(uid,"uid")
	
	if deskInfo.smallState == 1 then
		return PDEFINE.RET.SUCCESS 
	end
	
	if user.state == 1 then
        return PDEFINE.RET.SUCCESS
    end
    user.autoc = 0
    if usersAutoFuc[user.seat] then 
		usersAutoFuc[user.seat](user.seat)
	end
	user.state = 1
	local retobj    = {}
    retobj.code     = PDEFINE.RET.SUCCESS
    retobj.c        = PDEFINE.NOTIFY.NOTIFY_READY
    retobj.uid      = uid
    retobj.seat   = user.seat
    broadcastDesk(cjson.encode(retobj))
    if #deskInfo.users == deskInfo.conf.seat then
	    for _, userReady in pairs(deskInfo.users) do  --判断所有玩家是否都已经准备
	        if userReady.state ~= 1 then
	            return PDEFINE.RET.SUCCESS
	        end
	    end

	    CMD.startGame()
	end
    return PDEFINE.RET.SUCCESS
end

function CMD.getDeskInfoClient(source,msg)
	local recvobj = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)

	local tmpDeskInfo = {}
	tmpDeskInfo.users = table.copy(deskInfo.users)
	--拿掉其它玩家坎牌跟手牌的值
	for _, user in pairs(tmpDeskInfo.users) do
		if user.uid ~= uid then
			for _, menziInfo in pairs(user.menzi) do
				if menziInfo.type == hongheitool.cardType.kan then
					menziInfo.card = 0
				end
				if menziInfo.type == hongheitool.cardType.long then
					menziInfo.card = 0
				end
			end
			user.handInCards = nil
		end
	end

	tmpDeskInfo.conf = deskInfo.conf
	tmpDeskInfo.bankerInfo = deskInfo.bankerInfo
	tmpDeskInfo.smallState = deskInfo.smallState
	tmpDeskInfo.bigState = deskInfo.bigState
	tmpDeskInfo.round = deskInfo.round
	tmpDeskInfo.dissolveInfo = deskInfo.dissolveInfo
	tmpDeskInfo.pulicCardsCnt = #new_card
	for _, muser in pairs(deskInfo.users) do
		if uid == muser.uid then
			muser.lat = recvobj.lat
			muser.lng = recvobj.lng
			if deskInfo.actionInfo.waitList[muser.seat] then
				local actionInfo = {}
				actionInfo.curaction = deskInfo.actionInfo.curaction
				actionInfo.nextaction = deskInfo.actionInfo.nextaction
				actionInfo.iswait = 1
				actionInfo.waitList = deskInfo.actionInfo.waitList[muser.seat]
				tmpDeskInfo.actionInfo = actionInfo
			else
				local actionInfo = {}
				actionInfo.curaction = deskInfo.actionInfo.curaction
				actionInfo.nextaction = deskInfo.actionInfo.nextaction
				actionInfo.iswait = 1
				actionInfo.waitList = {}
				tmpDeskInfo.actionInfo = actionInfo
			end
			break
		end
	end
	print("---------tmpDeskInfo.dissolveInfo-----------",tmpDeskInfo.dissolveInfo)
	if tmpDeskInfo.dissolveInfo.iStart == 1 then
		tmpDeskInfo.dissolveInfo.distimeoutIntervel = tmpDeskInfo.dissolveInfo.distimeoutBeginTime + timeout[4] - os.time()
	end
	tmpDeskInfo.locatingList = hongheitool.jisuanXY(deskInfo.users)
	local retobj = {}
	retobj.c      = math.floor(recvobj.c)
    retobj.code  = PDEFINE.RET.SUCCESS
    retobj.deskInfo = tmpDeskInfo
    return resp(retobj)
end

-- 用户离线获取牌桌信息
function CMD.getDeskInfo(source,msg)
	local recvobj = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)

	local tmpDeskInfo = {}
	tmpDeskInfo.users = table.copy(deskInfo.users)
	--拿掉其它玩家坎牌跟手牌的值
	for _, user in pairs(tmpDeskInfo.users) do
		if user.uid ~= uid then
			for _, menziInfo in pairs(user.menzi) do
				if menziInfo.type == hongheitool.cardType.kan then
					menziInfo.card = 0
				end
				if menziInfo.type == hongheitool.cardType.long then
					menziInfo.card = 0
				end
			end
			user.handInCards = nil
		end
	end

	tmpDeskInfo.conf = deskInfo.conf
	tmpDeskInfo.bankerInfo = deskInfo.bankerInfo
	tmpDeskInfo.smallState = deskInfo.smallState
	tmpDeskInfo.bigState = deskInfo.bigState
	tmpDeskInfo.round = deskInfo.round
	tmpDeskInfo.dissolveInfo = deskInfo.dissolveInfo
	tmpDeskInfo.pulicCardsCnt = #new_card
	for _, muser in pairs(deskInfo.users) do
		if uid == muser.uid then
			muser.lat = recvobj.lat
			muser.lng = recvobj.lng
			if deskInfo.actionInfo.waitList[muser.seat] then
				local actionInfo = {}
				actionInfo.curaction = deskInfo.actionInfo.curaction
				actionInfo.nextaction = deskInfo.actionInfo.nextaction
				actionInfo.iswait = 1
				actionInfo.waitList = deskInfo.actionInfo.waitList[muser.seat]
				tmpDeskInfo.actionInfo = actionInfo
			else
				local actionInfo = {}
				actionInfo.curaction = deskInfo.actionInfo.curaction
				actionInfo.nextaction = deskInfo.actionInfo.nextaction
				actionInfo.iswait = 1
				actionInfo.waitList = {}
				tmpDeskInfo.actionInfo = actionInfo
			end
			break
		end
	end
	print("---------tmpDeskInfo.dissolveInfo-----------",tmpDeskInfo.dissolveInfo)
	if tmpDeskInfo.dissolveInfo.iStart == 1 then
		tmpDeskInfo.dissolveInfo.distimeoutIntervel = tmpDeskInfo.dissolveInfo.distimeoutBeginTime + timeout[4] - os.time()
	end
	tmpDeskInfo.locatingList = hongheitool.jisuanXY(deskInfo.users)

	return tmpDeskInfo
end

function CMD.getLocatingList(source,msg)
	local recvobj = cjson.decode(msg)
	local retobj = {}
	deskInfo.locatingList = hongheitool.jisuanXY(deskInfo.users)
	retobj.c      = math.floor(recvobj.c)
    retobj.code  = PDEFINE.RET.SUCCESS
    retobj.locatingList = deskInfo.locatingList
    return resp(retobj)
end

-- 退出房间
function CMD.exitG(source,msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local user  = seleteUserInfo(uid, "uid")
    if user then  --玩家离开 必须存在房间中
        if deskInfo.bigState == 0 then
            for i, user in pairs(deskInfo.users) do
                if user.uid == uid then
                	if usersAutoFuc[user.seat] then 
						usersAutoFuc[user.seat](user.seat)
					end
                    local retobj = {}
                    retobj.c     = PDEFINE.NOTIFY.exit
                    retobj.code  = PDEFINE.RET.SUCCESS
                    retobj.uid   = uid
                    retobj.seat = user.seat
                    --pcall(cluster.call, user.cluster_info.server, user.cluster_info.address, "deskBack", PDEFINE.GAME_TYPE.ZIPAI_HONGHEIHU_SR) --释放桌子对象
                    for _, muser in pairs(deskInfo.users) do
                        if muser.uid ~= uid  and muser.ofline == 0 then
                            pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(retobj))
                        end
                    end
                    setSeatId(user.seat)
                    pcall(cluster.call, user.cluster_info.server, user.cluster_info.address, "deskBack", PDEFINE.GAME_TYPE.ZIPAI_HONGHEIHU_SR) --释放桌子对象
                    table.remove(deskInfo.users, i)
                    break
                end
            end
        else
            return PDEFINE.RET.ERROR.GAME_ING_ERROR --游戏中不能退出
        end



        if #deskInfo.users == 0 then --需要特殊处理减少桌子跟清空桌子信息
            deskInfo.bigState = 0
            deskInfo.smallState = 0
            deskInfo.conf.curseat = 0
			deskInfo.bankerInfo = {uid = 0, count = 0, seat = 0}
			deskInfo.actionInfo = {iswait = 0, prioritySeat = 0, waitList = {},curaction = {seat = 0, type = 0, time = timeout[1], card = 0},nextaction = {seat = 0, type = 0}}
			local seat = deskInfo.conf.seat
			waitAction = {}
			existSeatIdList = {}
			for i =1, seat do
				table.insert(existSeatIdList,i)
			end
			return PDEFINE.RET.EXIT_RESET
        end
        notyGpsColour()
    end
    return PDEFINE.RET.SUCCESS
end


--用户在线离线
function CMD.ofline(source,ofline,uid)
	local user = seleteUserInfo(uid,"uid")
	if user then
		local retobj = {}
		user.ofline = ofline
		retobj.c = PDEFINE.NOTIFY.NOTIFY_ONLINE
		retobj.code = PDEFINE.RET.SUCCESS
		retobj.ofline = ofline
		retobj.uid = user.uid
		retobj.seat = user.seat
		broadcastDesk(cjson.encode(retobj))
	end
end

function CMD.sendChatMsg(source,msg)
	local recvobj = cjson.decode(msg)
	local uid   = math.floor(recvobj.uid)
	local chatInfo = recvobj.chatInfo
	local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTIFY_CHAT
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.chatInfo = chatInfo
	broadcastDesk(cjson.encode(noty_retobj))
	return PDEFINE.RET.SUCCESS
end

function CMD.gpsUpdate(source,uid,lat,lng)
	local user = seleteUserInfo(uid,"uid")
	if user then
		user.lat = lat
		user.lng = lng
		notyGpsColour()
	end
end

local function addAgreeDissolveUsers(uid,value)
	for _,user in pairs(deskInfo.dissolveInfo.agreeUsers) do
		if user.uid == uid then
			user.isargee = value
		end
	end
	local isDisslve = true
	for _,user in pairs(deskInfo.dissolveInfo.agreeUsers) do
		if user.isargee ~= 1 then
			return false
		end
	end
	return isDisslve
end




--发起解散
function CMD.dissolve(source,msg)
	local recvobj = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo(uid,"uid")
	if deskInfo.conf.isdissolve == 0 then
		return PDEFINE.RET.SUCCESS --不可解散
	end

	if not user then
		return PDEFINE.RET.ERROR.AlREADY_BACK --用户已退出
	end
	if deskInfo.dissolveInfo.iStart == 1 then
		return PDEFINE.RET.ERROR.ACTION_ERROR --发起过解散
	end
	if deskInfo.bigState == 1 then
		deskInfo.dissolveInfo.iStart = 1
		deskInfo.dissolveInfo.startUid = user.uid
		deskInfo.dissolveInfo.startPlayername = user.playername
		deskAutoFuc = user_set_timeout(deskInfo.dissolveInfo.time*100,autoDissolve,1)
		deskInfo.dissolveInfo.distimeoutBeginTime  = os.time() --倒计时开始时间
		deskInfo.dissolveInfo.distimeoutIntervel   = deskInfo.dissolveInfo.time
		addAgreeDissolveUsers(uid,1)
		local retobj    = {}
	    retobj.c        = PDEFINE.NOTIFY.senddissolve
	    retobj.code     = PDEFINE.RET.SUCCESS
	    retobj.uid      = uid
	    retobj.dissolveInfo    = deskInfo.dissolveInfo
	    broadcastDesk(cjson.encode(retobj))
	elseif deskInfo.bigState == 0 then
		local retobj    = {}
		retobj.c        = PDEFINE.NOTIFY.succeddissolve
		retobj.code     = PDEFINE.RET.SUCCESS
		retobj.isShowJieSuan = 1
		broadcastDesk(cjson.encode(retobj))
		big_over()
	end

	return PDEFINE.RET.SUCCESS
end

--同意解散
function CMD.agreeDissolve(source,msg)
	local recvobj = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo(uid,"uid")
	if not user then
		return PDEFINE.RET.ERROR.AlREADY_BACK --用户已退出
	end
	if deskInfo.bigState == 1 and deskInfo.dissolveInfo.iStart == 1 then
		local isDissolve = addAgreeDissolveUsers(uid,1)
		local retobj    = {}
	    retobj.c        = PDEFINE.NOTIFY.agreedissolve
	    retobj.code     = PDEFINE.RET.SUCCESS
	    retobj.uid      = uid
	    retobj.playername    = user.playername
	    retobj.dissolveInfo = deskInfo.dissolveInfo
	    broadcastDesk(cjson.encode(retobj))

	    if isDissolve then
	    	if deskAutoFuc then deskAutoFuc() end
	    	local retobj    = {}
		    retobj.c        = PDEFINE.NOTIFY.succeddissolve
		    retobj.code     = PDEFINE.RET.SUCCESS
		    retobj.isShowJieSuan = 1
		    broadcastDesk(cjson.encode(retobj))

		    hupaiBance(deskInfo.actionInfo.curaction.seat,deskInfo.actionInfo.curaction.card,hongheitool.HUPAI_TYPE.liuju,true)
	    end
	end
	return PDEFINE.RET.SUCCESS
end

--拒绝解散
function CMD.refuseDissolve(source,msg)
	local recvobj = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo(uid,"uid")
	if not user then
		return PDEFINE.RET.ERROR.AlREADY_BACK --用户已退出
	end
		
	if deskInfo.bigState == 1 and deskInfo.dissolveInfo.iStart == 1 then
		initDissolveInfo()
		local retobj    = {}
	    retobj.c        = PDEFINE.NOTIFY.refusedissolve
	    retobj.code     = PDEFINE.RET.SUCCESS
	    retobj.uid      = uid
	    retobj.playername    = user.playername
	    if deskAutoFuc then deskAutoFuc() end
	    broadcastDesk(cjson.encode(retobj))
	end
	return PDEFINE.RET.SUCCESS
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.retpack(f(source, ...))
	end)

	collectgarbage("collect")
end)
