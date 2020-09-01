local skynet = require "skynet"
local netpack = require "netpack"
local crypt = require "crypt"
local socket = require "socket"
local cluster = require "cluster"
local socketdriver = require "socketdriver"
local random = require "random"
local cjson   = require "cjson"
local pdktool = require "pdktool"
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
	gameid = PDEFINE.GAME_TYPE.PUKE_PAODEKUAI,
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

-- 查找手牌是否存在出牌信息
local function seleteHandIncards(user,pcards)
	local flag = nil
	for _, pcard in pairs(pcards) do
		for _,card in pairs(user.handInCards) do
			if pcard == card then
				flag = true
			end
		end
		if flag == nil then
			return nil
		end
	end
	return true
end

local function closeAllTimer(seat)
	if not seat then
		for _,user in pairs(deskInfo.users) do
			if usersAutoFuc[user.seat] then 
				usersAutoFuc[user.seat](user.seat)
			end
		end
	else
		if usersAutoFuc[seat] then 
			usersAutoFuc[seat](seat)
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
	deskInfo.bankerInfo = {uid = 0, seat = 0}
	deskInfo.actionInfo = {curaction = {seat = 0, outCards = {}, cardType = 0, putCardsList = {}},nextaction = {seat = 0, type = 0, time = 15, hint = {}}}
	initDissolveInfo()
	local seat = deskInfo.conf.seat
	for i =1, seat do
		table.insert(existSeatIdList,i)
	end
end

local function setBankerInfo(uid,seat)
	deskInfo.bankerInfo.uid = uid
	deskInfo.bankerInfo.seat = seat
end

local function initBankerInfo()
	if deskInfo.bankerInfo.uid == 0 then
		if deskInfo.conf.seat == 2 then
			local minCard = 0x0F
			local uid = 0
			local seat = 0
			for i=1, #deskInfo.users do
				local mcard = deskInfo.users[i].handInCards[#deskInfo.users[i].handInCards]
				if getCardValue(mcard) < getCardValue(minCard) then
					minCard = mcard
					uid = deskInfo.users[i].uid
					seat = deskInfo.users[i].seat
				elseif getCardValue(mcard) == getCardValue(minCard) then
					if getCardColor(mcard) > getCardColor(minCard) then
						minCard = mcard
						uid = deskInfo.users[i].uid
						seat = deskInfo.users[i].seat
					end
				end
			end
			deskInfo.bankerInfo.uid = uid
			deskInfo.bankerInfo.seat = seat
			deskInfo.bankerInfo.minCard = minCard
		else
			for i=1, #deskInfo.users do
				for _, card in pairs(deskInfo.users[i].handInCards) do
					if card == 0x03 then
						deskInfo.bankerInfo.uid = deskInfo.users[i].uid
						deskInfo.bankerInfo.seat = deskInfo.users[i].seat
						deskInfo.bankerInfo.minCard = 0x03
						return
					end
				end
			end
		end
	end
end

local function getActionInfo()
	deskInfo.actionInfo.nextaction.seat = deskInfo.bankerInfo.seat
	deskInfo.actionInfo.nextaction.type =  2
end


local function addTgTime()
	if deskInfo.conf.trustee == 1 then
		deskInfo.actionInfo.curaction.time = timeout[1]
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


local function delteHandIncards(user,pcards)
	for _,pcard in pairs(pcards) do
		for i = #user.handInCards, 1, -1 do
		    if pcard == user.handInCards[i] then
		        table.remove(user.handInCards, i)
		    end
		end
	end
	return true
end

-- 广播给房间里的所有人
local function broadcastDesk(retobj)
	for _, muser in pairs(deskInfo.users) do
        if muser.cluster_info and muser.ofline == 0 then
            pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", retobj)
        end
    end
end

-- 查找特定的牌
local function findNiao()
	if deskInfo.conf.param1 > 0 then
		for _, user in pairs(deskInfo.users) do
			for _, card in pairs(user.handInCards) do
				if card == 0x1A then
					return user.seat
				end
			end
			for _, card in pairs(user.putCards) do
				if card == 0x1A then
					return user.seat
				end
			end
		end
	end
	return 0
end

local function notyGpsColour()
	deskInfo.locatingList,gpsColour = pdktool.jisuanXY(deskInfo.users)
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




-- 给该桌子放置一副已经打乱的扑克
local function setDeskBase()
	new_card =
	{
	    0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x1E,0x0F, --黑 3 - 2(15)
	    0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D, --红
	    0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D, --梅
	    0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,      --方
	}

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

-- 当把游戏结束
local function global_over()
	deskInfo.smallState = 0
	deskInfo.smallBeginTime = ""
	deskInfo.actionInfo = {curaction = {seat = 0, outCards = {}, cardType = 0, putCardsList = {}},nextaction = {seat = 0, type = 0, time = 15, hint = {}}}
	for _,user in pairs(deskInfo.users) do
		if usersAutoFuc[user.seat] then 
			usersAutoFuc[user.seat](user.seat)
		end
		user.isBaoJin = 0
		user.handInCards = {}
		user.roundScore = 0 --每一局的分数
		user.roundzhadan = 0 --当局炸弹数
		user.putCards = {}
		user.state = 0
		user.cardsCnt = 0
		CMD.userSetAutoState("autoReady",timeout[1]*100,user.seat)
	end
	
end

-- 当把游戏结束
local function big_over()
	for _,user in pairs(deskInfo.users) do
		pcall(cluster.call, user.cluster_info.server, user.cluster_info.address, "deskBack", PDEFINE.GAME_TYPE.PUKE_PAODEKUAI) --释放桌子对象
		pcall(cluster.call, "clubs", ".clubsmgr", "deltelUser", user.uid, deskInfo.conf.clubid,deskInfo.conf.deskId,true)
	end

	deskInfo.users = {}
	deskInfo.smallState = 0
	deskInfo.bigState = 0
	deskInfo.bankerInfo = {uid = 0, count = 1, seat = 0}
	deskInfo.actionInfo = {curaction = {seat = 0, outCards = {}, cardType = 0, putCardsList = {}},nextaction = {seat = 0, type = 0, time = 15}}
	pcall(cluster.call, "game", ".dsmgr", "recycleAgent", skynet.self(), deskInfo.conf.deskId)
end

local function hupaiBance(seat,isdissolve)
	local noty_retobj  = {}
	noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_HUPAI
	noty_retobj.code   = PDEFINE.RET.SUCCESS
	noty_retobj.gameid = deskInfo.gameid
	noty_retobj.diPaiCards = new_card
	noty_retobj.seat = seat or 0
	local niaoseat = findNiao()
	noty_retobj.niaoseat = niaoseat
	
	local zzhaniao = nil
	if niaoseat == seat then
		zzhaniao = true
	end
	local zhaniao = nil
	if seat then
		local huser = seleteUserInfo(seat,"seat")
		for _,user in pairs(deskInfo.users) do
			if not zzhaniao then
				if niaoseat == user.seat then
					zhaniao = true
				else
					zhaniao = nil
				end
			end
			if user.seat ~= seat then
				if #user.handInCards > 1 then
					local niaomult = 1
					
					local mult = 1
				    if #user.handInCards == 15 then --春天
				    	mult = 2
				    end
					user.loseCount = user.loseCount + 1
					if zzhaniao or zhaniao then
						if deskInfo.conf.param1 == 1 then --两倍
							user.roundScore = user.roundScore - (#user.handInCards )*mult*2
							huser.roundScore = huser.roundScore + (#user.handInCards )*mult*2
						elseif deskInfo.conf.param1 == 2 then --加5分
							user.roundScore = user.roundScore - (#user.handInCards )*mult-5
							huser.roundScore = huser.roundScore + (#user.handInCards )*mult+5
						elseif deskInfo.conf.param1 == 3 then --加5分
							user.roundScore = user.roundScore - (#user.handInCards )*mult-10
							huser.roundScore = huser.roundScore + (#user.handInCards )*mult+10
						else
							user.roundScore = user.roundScore - (#user.handInCards )*mult
							huser.roundScore = huser.roundScore + (#user.handInCards )*mult
						end
					else
						user.roundScore = user.roundScore - (#user.handInCards )*mult
						huser.roundScore = huser.roundScore + (#user.handInCards )*mult
					end
					user.score = user.score + user.roundScore
					user.zhadancount = user.zhadancount + user.roundzhadan
				end
			end
		end
		if huser.roundScore > huser.highscore then
			huser.highscore = huser.roundScore
		end
		huser.winCount = huser.winCount + 1
		huser.score = huser.score + huser.roundScore
		huser.zhadancount = huser.zhadancount + huser.roundzhadan
		setBankerInfo(huser.uid,huser.seat)
	end
	

	local userList = {}
	for _,user in pairs(deskInfo.users) do
		local info = {}
		info.isChunTian = 0
		if #user.handInCards == 15 and seat then
			info.isChunTian = 1
		end
		info.uid = user.uid
		info.playername = user.playername
		info.usericon = user.usericon
		info.seat = user.seat
		info.roundzhadan = user.roundzhadan
		info.putCards = user.putCards
		info.handInCards = user.handInCards
		info.score = user.score
		info.roundScore = user.roundScore
		table.insert(userList,info)
	end
	noty_retobj.users = userList
	gameRecord(1)
	skynet.sleep(30)
	broadcastDesk(cjson.encode(noty_retobj))

	if deskInfo.round == deskInfo.conf.gamenum or isdissolve then
		local userList = {}
		for _,user in pairs(deskInfo.users) do
			local info = {}
			info.uid = user.uid
			info.playername = user.playername
			info.usericon = user.usericon
			info.seat = user.seat
			info.highscore = user.highscore
			info.zhadancount = user.zhadancount
			info.winCount = user.winCount
			info.loseCount = user.loseCount
			info.score = user.score
			info.beishu = deskInfo.conf.score
			user.score = user.score*deskInfo.conf.score
			info.scoreCount = user.score
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
	else
		global_over()
	end
end


-- 取出牌
local function getCard() 
	setDeskBase()
	local userscard = {}
	for i = 1, deskInfo.conf.seat do
		userscard[i] = {}
	end
	for i = 1 ,deskInfo.conf.seat do
		for j=1,15 do
			table.insert(userscard[i],table.remove(new_card))
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

local function setActionUser(seat,putCardsInfo)
	for i, info in pairs(deskInfo.actionInfo.curaction.putCardsList) do
		if info.seat == seat then
			deskInfo.actionInfo.curaction.putCardsList[i] = putCardsInfo
			return
		end
	end
	table.insert(deskInfo.actionInfo.curaction.putCardsList,putCardsInfo)
end

function CMD.exit()
	collectgarbage("collect")
	skynet.exit()
end

--设置打出去的牌
local function setPutCards(cards,user)
	for _, card in pairs(cards) do
		table.insert(user.putCards,card)
	end
end

local function stuctcardsVaues(ret)
	local retList = {}
	for _, groups in pairs(ret) do
		local retInfo = {}
		for _,info in pairs(groups) do
			local card = info.value + info.color
			table.insert(retInfo,card)
		end
		table.insert(retList,retInfo)
	end
	return retList
end

local function autoLastPut(seat)
	local user = seleteUserInfo(seat,"seat")
	local cards = table.copy(user.handInCards)
	local cardType = 0
	cardType = pdktool.getType(pdktool.stuctCards(cards))
	if cardType == 0  or cardType == 6 or cardType == 7 or cardType == 8 then
		return PDEFINE.RET.ERROR.NO_ACTION_ERROR
	elseif cardType == pdktool.CardType.BOMB_CARD then
		user.roundzhadan = user.roundzhadan + 1
	end
	if delteHandIncards(user,cards) then
		setPutCards(cards,user)
		deskInfo.actionInfo.curaction.seat = user.seat
		deskInfo.actionInfo.curaction.outCards = cards
		table.insert(deskInfo.actionInfo.curaction.putCardsList,putCardsInfo)
		deskInfo.actionInfo.curaction.cardType = cardType
		deskInfo.actionInfo.nextaction.seat = 0
		user.cardsCnt = #user.handInCards

		local noty_retobj  = {}
		noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PUT_PDK
		noty_retobj.code   = PDEFINE.RET.SUCCESS
		noty_retobj.gameid = deskInfo.gameid
		noty_retobj.seat   = user.seat
		noty_retobj.cardsCnt = user.cardsCnt
		noty_retobj.actionInfo = deskInfo.actionInfo
		noty_retobj.isBaoJin = 0
		broadcastDesk(cjson.encode(noty_retobj))

		if #user.handInCards == 0 then
			if deskInfo.actionInfo.curaction.cardType == pdktool.CardType.BOMB_CARD then
				for _, user in pairs(deskInfo.users) do
					if user.seat == deskInfo.actionInfo.curaction.seat then
						user.roundScore = user.roundScore + (deskInfo.conf.seat - 1)*10
					else
						user.roundScore = user.roundScore - 10
					end
				end
			end
			hupaiBance(user.seat)
			return PDEFINE.RET.SUCCESS
		end
	else
		return PDEFINE.RET.SUCCESS
	end
end

-- 过
local function pass(seat)
	skynet.sleep(100)
	local user = seleteUserInfo(seat,"seat")
	if usersAutoFuc[user.seat] then 
		usersAutoFuc[user.seat](user.seat)
	end
	user.autoc = 0

	local putCardsInfo = {}
	putCardsInfo.seat = user.seat
	putCardsInfo.outCards = {}
	putCardsInfo.isPass = 1
	setActionUser(seat,putCardsInfo)

	local nextSeat = getNextSeat(user.seat)
	local nextUser = seleteUserInfo(nextSeat,"seat")
	if nextSeat == deskInfo.actionInfo.curaction.seat then
		if deskInfo.actionInfo.curaction.cardType == pdktool.CardType.BOMB_CARD then
			local coinUserList = {}
			for _, user in pairs(deskInfo.users) do
				if user.seat == deskInfo.actionInfo.curaction.seat then
					user.score = user.score + (deskInfo.conf.seat - 1)*10
				else
					user.score = user.score - 10
				end
				local info = {}
				info.seat = user.seat
				info.score = user.score
				table.insert(coinUserList,info)
			end
			local noty_Coin = {}
			noty_Coin.c = PDEFINE_MSG.NOTIFY.NOTY_ZHADAN_SCORE_CHANGE
			noty_Coin.usersCoin = coinUserList
			noty_Coin.code = PDEFINE.RET.SUCCESS
			broadcastDesk(cjson.encode(noty_Coin))
		end
		deskInfo.actionInfo.nextaction.type = 2
		deskInfo.actionInfo.nextaction.hint = {}
		deskInfo.actionInfo.nextaction.seat = nextSeat
		deskInfo.actionInfo.curaction.outCards = {}
		deskInfo.actionInfo.curaction.seat = 0
		deskInfo.actionInfo.curaction.cardType = 0
		deskInfo.actionInfo.curaction.putCardsList = {}


		
	else
		local ret = pdktool.getTips(pdktool.stuctCards(nextUser.handInCards),pdktool.stuctCards(deskInfo.actionInfo.curaction.outCards))
		local hint = stuctcardsVaues(ret)
		for _, info in pairs(hint) do
			local scards = pdktool.getCardNamebyCards(pdktool.stuctCards(info))
		end
		if #ret == 0 then
			--通知该玩家要不起
			deskInfo.actionInfo.nextaction.type = 0
			deskInfo.actionInfo.nextaction.seat = nextSeat
		else
			deskInfo.actionInfo.nextaction.type = 1
			deskInfo.actionInfo.nextaction.seat = nextSeat
			deskInfo.actionInfo.nextaction.hint = hint
		end
	end
	local noty_retobj  = {}
	noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PASS
	noty_retobj.code   = PDEFINE.RET.SUCCESS
	noty_retobj.gameid = deskInfo.gameid
	noty_retobj.seat = user.seat
	noty_retobj.actionInfo = deskInfo.actionInfo

	
	
	broadcastDesk(cjson.encode(noty_retobj))
	if deskInfo.actionInfo.nextaction.type == 0 then
		pass(deskInfo.actionInfo.nextaction.seat)
	else
		--判断最大的玩家的牌是不是 可以直接出掉pdktool.tips(cards)
		local retResult = pdktool.tips(pdktool.stuctCards(nextUser.handInCards))
		for _, retInfo in pairs(retResult) do
			if #retInfo == #nextUser.handInCards then
				CMD.userSetAutoState("autoLastPut",100,nextSeat)
				break
			end
		end
	end
	return PDEFINE.RET.SUCCESS
end

--判断下个玩家是不是报警了
local function getNextIsBaoJin(seat)
	local nextSeat = getNextSeat(seat)
	local nextUser = seleteUserInfo(nextSeat,"seat")
	return nextUser.isBaoJin
end

--查找是否包含最小的那张牌
local function selectMinCard(cards)
	if deskInfo.isFirst then
		local isHaveMinCard = false
		for _, card in pairs(cards) do
			if card == deskInfo.bankerInfo.minCard then
				isHaveMinCard = true
				break
			end
		end
		if not isHaveMinCard then
			return nil
		end
	end
	return true
end

-- 打牌
function CMD.pdkPutCard(source,msg)
	local recvobj  = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local cards = recvobj.cards
	local user = seleteUserInfo(uid,"uid")
	local isBaoJin = getNextIsBaoJin(user.seat) 
	if isBaoJin > 0 then
		if #cards == 1 then
			if cards[1] ~= user.handInCards[1] then
				return PDEFINE.RET.ERROR.PUT_MAX_CARD
			end
		end
	end
	if not selectMinCard(cards) then
		return PDEFINE.RET.ERROR.PUT_MIN_CARD
	end

	
	--判断打牌者是否这个用户
	if deskInfo.actionInfo.nextaction.seat ~= user.seat then
		return PDEFINE.RET.SUCCESS
	end
	if not seleteHandIncards(user,cards) then
		return PDEFINE.RET.SUCCESS
	end
	--判断有没有上个玩家
	local cardType = 0
	cardType = pdktool.getType(pdktool.stuctCards(cards))
	if cardType == 0 then
		return PDEFINE.RET.ERROR.NO_ACTION_ERROR
	elseif cardType == pdktool.CardType.BOMB_CARD then
		user.roundzhadan = user.roundzhadan + 1
	end
	
	if #deskInfo.actionInfo.curaction.outCards > 0 then
		if not pdktool.compare_cards(pdktool.stuctCards(cards), pdktool.stuctCards(deskInfo.actionInfo.curaction.outCards)) then
			return PDEFINE.RET.SUCCESS
		end
	end
	closeAllTimer()

	deskInfo.isFirst = nil

	local nextSeat = getNextSeat(user.seat)
	local nextUser = seleteUserInfo(nextSeat,"seat")

	

	if delteHandIncards(user,cards) then
		setPutCards(cards,user)
		deskInfo.actionInfo.curaction.seat = user.seat
		deskInfo.actionInfo.curaction.outCards = cards
		table.insert(deskInfo.actionInfo.curaction.putCardsList,putCardsInfo)
		deskInfo.actionInfo.curaction.cardType = cardType
		deskInfo.actionInfo.nextaction.seat = nextSeat
		user.cardsCnt = #user.handInCards
	else
		return PDEFINE.RET.SUCCESS
	end
	local putCardsInfo = {}
	putCardsInfo.seat = user.seat
	putCardsInfo.outCards = cards
	putCardsInfo.isPass = 0
	setActionUser(user.seat,putCardsInfo)


	--检测下个玩家能不能要的起
	
	local ret = pdktool.getTips(pdktool.stuctCards(nextUser.handInCards),pdktool.stuctCards(cards))
	local hint = stuctcardsVaues(ret)
	for _, info in pairs(hint) do
		local scards = pdktool.getCardNamebyCards(pdktool.stuctCards(info))
	end
	if #ret == 0 then
		--通知该玩家要不起
		deskInfo.actionInfo.nextaction.type = 0
	else
		deskInfo.actionInfo.nextaction.type = 1
		deskInfo.actionInfo.nextaction.hint = hint
	end

	if #user.handInCards == 0 then
		deskInfo.actionInfo.nextaction.seat = 0
		deskInfo.actionInfo.nextaction.type = 0
		deskInfo.actionInfo.nextaction.hint = {}
	end
	local noty_retobj  = {}
	noty_retobj.c      = PDEFINE.NOTIFY.NOTIFY_HZ_PUT_PDK
	noty_retobj.code   = PDEFINE.RET.SUCCESS
	noty_retobj.gameid = deskInfo.gameid
	noty_retobj.seat   = user.seat
	noty_retobj.cardsCnt = user.cardsCnt
	noty_retobj.actionInfo = deskInfo.actionInfo
	noty_retobj.isBaoJin = 0
	broadcastDesk(cjson.encode(noty_retobj))

	if #user.handInCards == 0 then
		if deskInfo.actionInfo.curaction.cardType == pdktool.CardType.BOMB_CARD then
			for _, user in pairs(deskInfo.users) do
				if user.seat == deskInfo.actionInfo.curaction.seat then
					user.roundScore = user.roundScore + (deskInfo.conf.seat - 1)*10
				else
					user.roundScore = user.roundScore - 10
				end
			end
		end
		hupaiBance(user.seat)
		return PDEFINE.RET.SUCCESS
	elseif #user.handInCards == 1 then
		noty_retobj.isBaoJin = 1
		user.isBaoJin = 1
	end

	if deskInfo.actionInfo.nextaction.type == 0 then
		pass(nextSeat)
	else
		--判断最大的玩家的牌是不是 可以直接出掉pdktool.tips(cards)
		local retResult = pdktool.tips(pdktool.stuctCards(nextUser.handInCards))
		for _, retInfo in pairs(retResult) do
			if #retInfo == #nextUser.handInCards then
				local hcardType = pdktool.getType(pdktool.stuctCards(nextUser.handInCards))
				if hcardType == pdktool.CardType.BOMB_CARD or deskInfo.actionInfo.curaction.cardType == hcardType then
					CMD.userSetAutoState("autoLastPut",100,nextSeat)
					break
				end
			end
		end
	end

	return PDEFINE.RET.SUCCESS
end





local function autoPut(seat)

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

-- 返回到大厅 需要下发当前的桌子ID给客户端 然它定位当前哪个桌子上,也是判断自己当前是已经进入到了桌子里
function CMD.backClubHall(source,msg)
	local recvobj  = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local user = seleteUserInfo(uid,"uid")
	user.isBackClubHall = true
	local retobj = {}
	retobj.c      = math.floor(recvobj.c)
    retobj.code  = PDEFINE.RET.SUCCESS
    retobj.deskId = deskInfo.conf.deskId
    return resp(retobj)
end


local function autoDissolve(isTimeOut)
	local noty_retobj    = {}
	noty_retobj.c        = PDEFINE.NOTIFY.succeddissolve
	noty_retobj.code     = PDEFINE.RET.SUCCESS
	noty_retobj.isShowJieSuan = isTimeOut
	broadcastDesk(cjson.encode(noty_retobj))
	if isTimeOut == 1 then 
		hupaiBance(nil,true)
	else
		big_over()
	end
end

-- 加入桌子
function CMD.hallJoin(source,uid,cluster_info,ip,lat,lng,state)
	return cs(function ()
		local user = seleteUserInfo(uid,"uid")
		if user then
			if user then
				local tmp_deskInfo = table.copy(deskInfo)
				for i,muser in pairs(tmp_deskInfo.users) do
					if muser.uid ~= uid then
						tmp_deskInfo.users[i].handInCards = nil
					end
				end
				return PDEFINE.RET.SUCCESS,tmp_deskInfo
			end
		end
		if deskInfo.conf.distance == 1 then
			if not pdktool.checkDistance(lat,lng,deskInfo.users) then
				return PDEFINE.RET.ERROR.DISTANCE_EXIST
			end
		end

		if deskInfo.conf.ipcheck == 1 then
			if not pdktool.checkIp(ip,deskInfo.users) then
				return PDEFINE.RET.ERROR.CHECK_IP
			end
		end
		
		local playerInfo = getPlayerInfo(uid)

		local seat = getSeatId()
		if not seat then
	 		return PDEFINE.RET.ERROR.SEATID_EXIST
	 	end
	 	if #deskInfo.users == 0 then
	 		deskAutoFuc = user_set_timeout(PDEFINE_GAME.GAME_PARAM.DISS_TIME*100,autoDissolve,0)
	 	end
	 	deskInfo.conf.curseat = deskInfo.conf.curseat + 1
		local userInfo = {}
		userInfo.isBaoJin = 0
		userInfo.tingPaiInfo = {}
		userInfo.cluster_info = cluster_info
		userInfo.putCards = {}
		userInfo.cardsCnt = 0
		userInfo.score = 0 --总分数
		userInfo.roundScore = 0 --每一局的分数
		userInfo.roundzhadan = 0 --当局炸弹数
		userInfo.highscore = 0 --最高分数
		userInfo.zhadancount = 0 --炸弹总数
		userInfo.winCount = 0  --赢局数
		userInfo.loseCount = 0  --输局数
		userInfo.sex = playerInfo.sex
		userInfo.usericon = playerInfo.usericon
		userInfo.playername = serializePlayername(playerInfo.playername)
		userInfo.uid = uid
		userInfo.lat = lat
		userInfo.lng = lng
		userInfo.state = 0
		userInfo.ofline = 0
		userInfo.handInCards = {}
		userInfo.autoc = 0
		userInfo.ip = ip
		userInfo.seat = seat
		table.insert(deskInfo.users,userInfo)
		deskInfo.locatingList,gpsColour = pdktool.jisuanXY(deskInfo.users)

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
		return PDEFINE.RET.SUCCESS,deskInfo,retobj.user
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
	    elseif autoType == "autoLastPut" then
	        usersAutoFuc[seat] = user_set_timeout(autoTime, autoLastPut, seat)
	    elseif autoType == "autoPeng" then
	        usersAutoFuc[seat] = user_set_timeout(autoTime, autoPeng, seat)
	    end
	end

	if usersAutoFuc[seat] then 
		usersAutoFuc[seat](seat)
	end
	if autoType == "autoLastPut" then
	    usersAutoFuc[seat] = user_set_timeout(autoTime, autoLastPut, seat)
	end
end



--更新玩家的桌子信息
function CMD.updateUserClusterInfo(source, uid, agent)
    local user = seleteUserInfo(uid,"uid")
    if nil ~= user and user.cluster_info then
        user.cluster_info.address = agent
    end
end

-- 开始游戏
function CMD.startGame() 
	if deskAutoFuc then deskAutoFuc() end
	--restartTime(timeout[2]) --重置桌子时间
	initDissolveInfo()
	
	
	local notify_retobj = {}
	notify_retobj.c = PDEFINE.NOTIFY.start
	notify_retobj.code   = PDEFINE.RET.SUCCESS
    notify_retobj.gameid = PDEFINE.GAME_TYPE.PUKE_PAODEKUAI
    notify_retobj.bankerInfo = deskInfo.bankerInfo
   
	local usersCard = getCard(deskInfo.bankerInfo.seat)
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
	
	--usersCard[1] = {0x04,0x14,0x24,0x34,0x03,0x13,0x2A,0x3A,0x15,0x06,0x07,0x08,0x16,0x17,0x18}
    --usersCard[2] = {0x28,0x14,0x24,0x37,0x06,0x19,0x28,0x05,0x15,0x06,0x07,0x08,0x16,0x17,0x18}
	for index,user in pairs(deskInfo.users) do
		user.time = 0
		user.curTime = 0
		user.score = user.score + user.roundScore
		user.roundScore = 0
		user.handInCards = usersCard[user.seat]
		user.cardsCnt = #usersCard[user.seat]
		user.state = 2
	end

	for _,muser in pairs(deskInfo.users) do
		pdktool.sortByCards(muser.handInCards)
		local scards = pdktool.getCardNamebyCards(pdktool.stuctCards(muser.handInCards))
	end

	if deskInfo.bankerInfo.uid == 0 then
		initBankerInfo()
		deskInfo.isFirst = true
	end
	getActionInfo()
 	notify_retobj.actionInfo = deskInfo.actionInfo
	deskInfo.smallBeginTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
	if deskInfo.round == 0 then
		beginTime = os.date("%m-%d %H:%M:%S", os.time())
	end
	deskInfo.round = deskInfo.round + 1
	pcall(cluster.call, "clubs", ".clubsmgr", "updateRound", deskInfo.conf.clubid,deskInfo.conf.deskId,deskInfo.round,deskInfo.conf.gamenum)
	for index,user in pairs(deskInfo.users) do
		notify_retobj.seat = user.seat
		notify_retobj.round = deskInfo.round
		notify_retobj.score = user.score
		notify_retobj.cardsCnt = user.cardsCnt
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
	if deskInfo.bigState == 0 then
		deskInfo.bigState = 1
	end
	deskInfo.smallState = 1
	for _, user in pairs(deskInfo.users) do
		if user.isBackClubHall then
			CMD.notyDeskInfo(user.uid)
			user.isBackClubHall = nil
		end
	end
	
	--CMD.userSetAutoState("autoPut",timeout[1]*100,deskInfo.actionInfo.nextaction.seat)
	
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
	if deskInfo.bigState == 0 then
    	pcall(cluster.call, "clubs", ".clubsmgr", "userReady", user.uid,deskInfo.conf.clubid,deskInfo.conf.deskId)
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

-- 用户离线获取牌桌信息
local function localGetDeskInfo(uid,lat,lng)
	local tmpDeskInfo = {}
	tmpDeskInfo.users = table.copy(deskInfo.users)
	--拿掉其它玩家坎牌跟手牌的值
	for _, user in pairs(tmpDeskInfo.users) do
		if user.uid ~= uid then
			user.handInCards = nil
		else
			user.lat = lat or user.lat
			user.lng = lng or user.lng
			user.isBackClubHall = nil
		end
	end

	tmpDeskInfo.conf = deskInfo.conf
	tmpDeskInfo.bankerInfo = deskInfo.bankerInfo
	tmpDeskInfo.smallState = deskInfo.smallState
	tmpDeskInfo.bigState = deskInfo.bigState
	tmpDeskInfo.round = deskInfo.round
	tmpDeskInfo.dissolveInfo = deskInfo.dissolveInfo
	tmpDeskInfo.pulicCardsCnt = #new_card
	tmpDeskInfo.actionInfo = deskInfo.actionInfo
	
	if tmpDeskInfo.dissolveInfo.iStart == 1 then
		tmpDeskInfo.dissolveInfo.distimeoutIntervel = tmpDeskInfo.dissolveInfo.distimeoutBeginTime + timeout[4] - os.time()
	end
	tmpDeskInfo.locatingList = pdktool.jisuanXY(deskInfo.users)

	return tmpDeskInfo
end

function CMD.getDeskInfoClient(source,msg)
	local recvobj = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	local retobj = {}
	retobj.c      = math.floor(recvobj.c)
    retobj.code  = PDEFINE.RET.SUCCESS
    retobj.deskInfo = localGetDeskInfo(uid,recvobj.lat,recvobj.lng)
    return resp(retobj)
end

-- 用户离线获取牌桌信息
function CMD.getDeskInfo(source,msg)
	local recvobj = cjson.decode(msg)
	local uid = math.floor(recvobj.uid)
	return localGetDeskInfo(uid,recvobj.lat,recvobj.lng)
end

function CMD.notyDeskInfo(uid)
	local muser = seleteUserInfo(uid,"uid")
	local deskInfo = localGetDeskInfo(uid)
	local noty_retobj  = {}
	noty_retobj.code   = PDEFINE.RET.SUCCESS
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.c      = PDEFINE.NOTIFY.NOTY_UPDATE_DESKINFO
	noty_retobj.response.deskInfo = deskInfo
	if muser.cluster_info and muser.ofline == 0 then
	    pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(noty_retobj))
	end
end

function CMD.getLocatingList(source,msg)
	local recvobj = cjson.decode(msg)
	local retobj = {}
	deskInfo.locatingList = pdktool.jisuanXY(deskInfo.users)
	retobj.c      = math.floor(recvobj.c)
    retobj.code  = PDEFINE.RET.SUCCESS
    retobj.locatingList = deskInfo.locatingList
    return resp(retobj)
end

-- 退出房间
function CMD.exitG(source,msg)
	return cs(function ()
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
	                    --pcall(cluster.call, user.cluster_info.server, user.cluster_info.address, "deskBack", PDEFINE.GAME_TYPE.PUKE_PAODEKUAI) --释放桌子对象
	                    for _, muser in pairs(deskInfo.users) do
	                        if muser.uid ~= uid  and muser.ofline == 0 then
	                            pcall(cluster.call, muser.cluster_info.server, muser.cluster_info.address, "sendToClient", cjson.encode(retobj))
	                        end
	                    end
	                    setSeatId(user.seat)
	                    pcall(cluster.call, "clubs", ".clubsmgr", "deltelUser", uid, deskInfo.conf.clubid,deskInfo.conf.deskId)
	                    pcall(cluster.call, user.cluster_info.server, user.cluster_info.address, "deskBack", PDEFINE.GAME_TYPE.PUKE_PAODEKUAI) --释放桌子对象
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
				return PDEFINE.RET.SUCCESS
	        end
	        notyGpsColour()
	    end
	    return PDEFINE.RET.SUCCESS
    end)
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
		pcall(cluster.call, "clubs", ".clubsmgr", "setOnline", user.uid,deskInfo.conf.clubid,ofline)
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

		    hupaiBance(nil,true)
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
