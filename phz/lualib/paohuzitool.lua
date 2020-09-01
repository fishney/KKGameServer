local paoHuTingpaiLogic = require "paoTingpaiLogic"
local huZiGameHu = require "huZiGameHu"
local paohuzitool = {}
paohuzitool.cardType = {
	guo = 1, --
	put = 2, --打牌
	draw = 3, --吃
	chi = 4, --吃
	peng = 5,--碰
	kan = 6, --喂牌
	pao = 7, --跑
	long = 8,--踢龙  本来是喂的牌,又抓了一张
	she = 9, --蛇 发牌就发了4张的
	hupai = 10,--胡牌
	handpao = 11,--跑  手牌的坎跑
	handlong = 12,--踢龙  手牌的坎踢龙
}
paohuzitool.MIN_HU_XI = 15

paohuzitool.HUPAI_TYPE = {
	liuju = -1, --流局
	normal = 1, --平胡
	tianHu = 2, --天胡
	diHu = 3, --地胡
	tilongHu = 4, --踢龙胡
	paoHu = 5, --跑胡
	saoHu = 6, --扫胡
	pengHu = 7,--碰胡
}


paohuzitool.HUPAI_HU_XI = {
	[1] = {--小牌
		[4] = 3,--吃
		[5] = 1,--碰
		[6] = 3, --喂牌
		[7] = 6, --跑
		[8] = 9,--踢龙  本来是喂的牌,又抓了一张
		[9] = 9, --蛇 发牌就发了4张的
		[11] = 6, --跑  手牌的坎跑
		[12] = 9, --踢龙  手牌的坎踢龙
	},
	[2] = {--大牌
		[4] = 6,--吃
		[5] = 3,--碰
		[6] = 6, --喂牌
		[7] = 9, --跑
		[8] = 12,--踢龙  本来是喂的牌,又抓了一张
		[9] = 12, --蛇 发牌就发了4张的
		[11] = 9, --跑  手牌的坎跑
		[12] = 12, --踢龙  手牌的坎踢龙
	},
	
}


--胡牌类型
paohuzitool.HUPAI_SCORE = {
	[1] = 4,
	[2] = 10,
	[3] = 8,
	[4] = 12,
	[5] = 8,
	[6] = 6,
	[7] = 5,
	[8] = 9,
	[9] = 10,
	[10] = 9,
	[11] = 10,
	[12] = 40,
	[13] = 40,
	[14] = 12,
	[15] = 9,
	[16] = 40,
}



--出牌方式
paohuzitool.lpType = {
	draw = 1,
	put = 2,
}

local chiPai = {
	["small"] = {
		[101] = {{102,103},{105,110},{101,201},{201,201}},
		[102] = {{101,103},{103,104},{107,110},{102,202},{202,202}},
		[103] = {{101,102},{102,104},{104,105},{103,203},{203,203}},
		[104] = {{102,103},{103,105},{105,106},{104,204},{204,204}},
		[105] = {{101,110},{103,104},{104,106},{106,107},{105,205},{205,205}},
		[106] = {{104,105},{105,107},{107,108},{106,206},{206,206}},
		[107] = {{105,106},{106,108},{108,109},{102,110},{107,207},{207,207}},
		[108] = {{106,107},{107,109},{109,110},{108,208},{208,208}},
		[109] = {{107,108},{109,209},{108,110},{209,209}},
		[110] = {{101,105},{108,109},{102,107},{110,210},{210,210}},
	},
	["big"] = {
		[201] = {{202,203},{205,210},{201,101},{101,101}},
		[202] = {{201,203},{203,204},{207,210},{102,202},{102,102}},
		[203] = {{201,202},{202,204},{204,205},{103,203},{103,103}},
		[204] = {{202,203},{203,205},{205,206},{104,204},{104,104}},
		[205] = {{201,210},{203,204},{204,206},{206,207},{105,205},{105,105}},
		[206] = {{204,205},{205,207},{207,208},{106,206},{106,106}},
		[207] = {{205,206},{206,208},{208,209},{202,210},{107,207},{107,107}},
		[208] = {{206,207},{207,209},{209,210},{108,208},{108,108}},
		[209] = {{207,208},{208,210},{109,209},{109,109}},
		[210] = {{201,205},{208,209},{202,207},{110,210},{110,110}},
	},
}
function paohuzitool.findCard(tbl,value)
	for k,v in ipairs(tbl) do
	      if v == value then
	          return true
	      end
    end
end

function paohuzitool.delCard(cards,pcard)
	for i,card in pairs(cards) do
		if card == pcard then
			table.remove(cards,i)
			break
		end
	end
end

--查看小七对
function checkXiaoQiDui(user,cards)
	local tables = {}
	for i = 1,#cards do
		if not tables[cards[i]] then
			tables[cards[i]] = 1
		else
			tables[cards[i]] = tables[cards[i]] + 1
		end
	end
	local duiCount = 0
	local sheCount = 0
	for card,count in pairs(tables) do
		if count == 4 then
			duiCount = duiCount + 2
		end
		if count == 2 then
			duiCount = duiCount + 1
		end
	end
	if duiCount == 7 then
		return paohuzitool.HUPAI_TYPE.xiaoQiDuiHu
	end
	for _,info in pairs(user.menzi) do
		if info.type == paohuzitool.cardType.she then
			sheCount = sheCount + 1
		end
	end
	if sheCount == 2 then
		return paohuzitool.HUPAI_TYPE.shuangLongHu
	end
end

--获取听牌信息
function paohuzitool.getTingPaiInfo(user)
	return huZiGameHu.getTingPaiInfo(user,paoHuTingpaiLogic,paohuzitool.MIN_HU_XI)
end

local function sortHuPaiXin( a ,b)
	if a.huXi > b.huXi then
    	return true
    end
end 

function paohuzitool.checkPaoHuZiHu(user,cards,pcard,isDraw)
	return huZiGameHu.checkPaoHuZiHu(user,cards,pcard,isDraw,15,paoHuTingpaiLogic)
end

local chiHuXi = {
	[1] = {
		[1] = {101,102,103},
		[2] = {101,105,110},
		[3] = {102,107,110},
	},
	[2] = {
		[1] = {201,202,203},
		[2] = {201,205,210},
		[3] = {202,207,210},
		
	}
}

local function checkChiHuxi(cards,sb)
	table.sort(cards)
	for mult,data in pairs(chiHuXi[sb]) do
		if data[1] == cards[1] and data[2] == cards[2] and data[3] == cards[3] then
			return sb * 3
		end
	end
	return 0
end


--获取对应牌型的胡息
function paohuzitool.getCardsTypeHuXi(info)
	--判断吃 是不是1510
	local infoTmp = table.copy(info)
	local sb = 0
	if infoTmp.type == paohuzitool.cardType.chi then
		sb = math.floor(infoTmp.data[1] / 100)
	  	return checkChiHuxi(infoTmp.data,sb)
	else
		sb = math.floor(infoTmp.card / 100)
		return paohuzitool.HUPAI_HU_XI[sb][infoTmp.type]
	end
end

--检测坎跑
function paohuzitool.checkKanPao(user,pcard)
	for _,info in pairs(user.menzi) do
		if info.type == paohuzitool.cardType.kan and pcard == info.card then
			return true,paohuzitool.cardType.pao
		end
	end
	if paohuzitool.getValueCount(user.handInCards,pcard) == 3 then
		return true,paohuzitool.cardType.handpao
	end
end

--检测踢龙
function paohuzitool.checkTiLong(user,pcard)
	for _,info in pairs(user.menzi) do
		if info.type == paohuzitool.cardType.kan and pcard == info.card then
			return true,paohuzitool.cardType.long
		end
	end
	if paohuzitool.getValueCount(user.handInCards,pcard) == 3 then
		return true,paohuzitool.cardType.handlong
	end
end

--检测p碰跑
function paohuzitool.checkPengPao(user,pcard)
	for _,info in pairs(user.menzi) do
		if info.type == paohuzitool.cardType.peng and pcard == info.card then
			return true
		end
	end
end

function paohuzitool.getValueCount(cards,card)
	local tables = {}
	for i = 1,#cards do
		if not tables[cards[i]] then
			tables[cards[i]] = 1
		else
			tables[cards[i]] = tables[cards[i]] + 1
		end
	end
	if not tables[card] then
		return 0
	end
	return tables[card]
end

--检测有没有蛇
function paohuzitool.checkHandShe(cards)
	local tables = {}
	for i = 1,#cards do
		if not tables[cards[i]] then
			tables[cards[i]] = 1
		else
			tables[cards[i]] = tables[cards[i]] + 1
		end
	end
	local haveShe = nil
	for _, count in pairs(tables) do
		if count == 4 then
			haveShe = true
		end
	end
	return haveShe
end


--检测碰
function paohuzitool.checkPeng(user,pcard)
	if paohuzitool.findCard(user.notPengPai,pcard) then
		return nil
	end
	local tables = {}
	for i = 1,#user.handInCards do
		if not tables[user.handInCards[i]] then
			tables[user.handInCards[i]] = 1
		else
			tables[user.handInCards[i]] = tables[user.handInCards[i]] + 1
		end
	end

	for card, count in pairs(tables) do
		if card == pcard and count == 2 then
			return paohuzitool.cardType.peng
		end
	end
end

--检测sao
function paohuzitool.checkSao(user,pcard)
	local tables = {}
	for i = 1,#user.handInCards do
		if not tables[user.handInCards[i]] then
			tables[user.handInCards[i]] = 1
		else
			tables[user.handInCards[i]] = tables[user.handInCards[i]] + 1
		end
	end

	for card, count in pairs(tables) do
		if card == pcard and count == 2 then
			return paohuzitool.cardType.kan
		end
	end
end

local function getLuo(chiCardTypeList,cards,pcard,luoCount)
	local luoData = {}
	for _, info in pairs(chiCardTypeList) do
		if paohuzitool.findCard(cards, info[1]) and paohuzitool.findCard(cards, info[2]) then
			local data
			if info[1] == info[2] then
				if paohuzitool.getValueCount(cards,info[1]) == 2 then
					local data = {}
					data[1] = info[1]
					data[2] = info[2]
					data[3] = pcard
					table.insert(luoData,data)
				end
			elseif pcard == info[1]  then
				if paohuzitool.getValueCount(cards,info[1]) == 2  then
					local data = {}
					data[1] = info[1]
					data[2] = info[2]
					data[3] = pcard
					table.insert(luoData,data)
				end
			elseif  pcard == info[2] then
				if  paohuzitool.getValueCount(cards,info[2]) == 2 then
					local data = {}
					data[1] = info[1]
					data[2] = info[2]
					data[3] = pcard
					table.insert(luoData,data)
				end
			else
				local data = {}
				data[1] = info[1]
				data[2] = info[2]
				data[3] = pcard
				table.insert(luoData,data)
				if paohuzitool.getValueCount(cards,info[1]) == 2 and paohuzitool.getValueCount(cards,info[2]) == 2 and paohuzitool.getValueCount(cards,pcard) == 2 then
					local data = {}
					data[1] = info[1]
					data[2] = info[2]
					data[3] = pcard
					table.insert(luoData,data)
					table.insert(luoData,data)
				end
			end
		end
	end
	if #luoData > 0 then
		return luoData
	end
end

--检测吃
function paohuzitool.checkChi(user,pcard,suser)
	if #user.handInCards < 4 then
		return nil
	end
	local cards = table.copy(user.handInCards)
	-- 去除砍跟蛇
	local kanOrSheCardList = {}
	for _, card in pairs(cards) do
		local count = paohuzitool.getValueCount(cards,card)
		if count > 2 then
			if not kanOrSheCardList[card] then
				kanOrSheCardList[card] = count
			end
		end
	end

	for card,count in pairs(kanOrSheCardList) do
		for i = 1, count do
			paohuzitool.delCard(cards,card)
		end
	end

	if paohuzitool.findCard(user.notChiPai,pcard) then
		return nil
	end

	if paohuzitool.findCard(user.notChiPai,pcard) then
		return nil
	end

	if paohuzitool.findCard(suser.qipai,pcard) then
		return nil
	end
	
	local chiList = {}
	local sb = math.floor(pcard/100)
	local chiCardTypeList = {}
	if sb == 1 then
		chiCardTypeList = chiPai.small[pcard]
	else
		chiCardTypeList = chiPai.big[pcard]
	end

	local ret = {}
	for _, info in pairs(chiCardTypeList) do
		if paohuzitool.findCard(cards, info[1]) and paohuzitool.findCard(cards, info[2]) then
			--先查找是否存在吃的牌
			local count = paohuzitool.getValueCount(cards,pcard)
			if count == 1 then
				if info[1] == pcard or info[2] == pcard then
					local handInCards = table.copy(cards)
					paohuzitool.delCard(handInCards,info[1])
					paohuzitool.delCard(handInCards,info[2])
					local chis = {}
					chis.handInCards = handInCards
					chis.chiData = info
					chis.luoCount = 0
					chis.isChoose = 0
					chis.luoData = {}
					table.insert(chiList,chis)
				else
					if info[1] == info[2] then
						if paohuzitool.getValueCount(cards,info[1]) == 2 then --说明有一对相反的牌
							local tmpCards = table.copy(cards)
							paohuzitool.delCard(tmpCards,info[1])
							paohuzitool.delCard(tmpCards,info[2])
							local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,1)
							if luoData then
								local handInCards = table.copy(cards)
								paohuzitool.delCard(handInCards,info[1])
								paohuzitool.delCard(handInCards,info[2])
								local chis = {}
								chis.handInCards = handInCards
								chis.chiData = info
								chis.luoCount = 1
								chis.isChoose = 0
								chis.luoData = luoData
								table.insert(chiList,chis)
							end
						end
					else
						local tmpCards = table.copy(cards)
						paohuzitool.delCard(tmpCards,info[1])
						paohuzitool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,1)
						if luoData then
							local handInCards = table.copy(cards)
							paohuzitool.delCard(handInCards,info[1])
							paohuzitool.delCard(handInCards,info[2])
							local chis = {}
							chis.handInCards = handInCards
							chis.chiData = info
							chis.luoCount = 1
							chis.isChoose = 0
							chis.luoData = luoData
							table.insert(chiList,chis)
						end
					end
				end
			elseif count == 2 then
				if info[1] == info[2] then
					if paohuzitool.getValueCount(cards,info[1]) == 2 then --说明有一对相反的牌
						local tmpCards = table.copy(cards)
						paohuzitool.delCard(tmpCards,info[1])
						paohuzitool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,2)
						if luoData and #luoData > 1  then
							local handInCards = table.copy(cards)
							paohuzitool.delCard(handInCards,info[1])
							paohuzitool.delCard(handInCards,info[2])

							local chis = {}
							chis.handInCards = handInCards
							chis.chiData = info
							chis.luoCount = 2
							chis.isChoose = 0
							chis.luoData = luoData
							table.insert(chiList,chis)
						end
					end
				else
					if info[1] == pcard then
						local tmpCards = table.copy(cards)
						paohuzitool.delCard(tmpCards,pcard)
						paohuzitool.delCard(tmpCards,info[1])
						paohuzitool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,1)
						if luoData then
							local handInCards = table.copy(cards)
							paohuzitool.delCard(handInCards,info[1])
							paohuzitool.delCard(handInCards,info[2])
							local chis = {}
							chis.handInCards = handInCards
							chis.chiData = info
							chis.luoCount = 1
							chis.isChoose = 0
							chis.luoData = luoData
							table.insert(chiList,chis)
						end
					elseif info[2] == pcard then
						local tmpCards = table.copy(cards)
						paohuzitool.delCard(tmpCards,pcard)
						paohuzitool.delCard(tmpCards,info[1])
						paohuzitool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,1)
						if luoData then
							local handInCards = table.copy(cards)
							paohuzitool.delCard(handInCards,info[1])
							paohuzitool.delCard(handInCards,info[2])
							local chis = {}
							chis.handInCards = handInCards
							chis.chiData = info
							chis.luoCount = 1
							chis.isChoose = 0
							chis.luoData = luoData
							table.insert(chiList,chis)
						end
					else --两个都不相同 就看那一对牌是否存在另外一种相反的牌
						if sb == 1 then
							tmpCard = pcard + 100
						else
							tmpCard = pcard - 100
						end

						local tmpCards = table.copy(cards)
						paohuzitool.delCard(tmpCards,info[1])
						paohuzitool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,2)
						if luoData and #luoData > 0 then
							local chis = {}
							local handInCards = table.copy(cards)
							paohuzitool.delCard(handInCards,info[1])
							paohuzitool.delCard(handInCards,info[2])

							chis.handInCards = handInCards
							chis.chiData = info
							if paohuzitool.findCard(cards, tmpCard) then
								if #luoData == 1 then
									chis.luoCount = 1
									chis.isChoose = 0
								else
									chis.luoCount = 2
									chis.isChoose = 1
								end
								chis.luoData = luoData
								table.insert(chiList,chis)
							else
								--如果没有一对相反的牌 就必须要落两方牌
								if #luoData == 2 then
									chis.luoCount = 2
									chis.isChoose = 0
									chis.luoData = luoData
									table.insert(chiList,chis)
								end
							end
						end
					end
				end
			else
				if info[1] == info[2] then
					if paohuzitool.getValueCount(cards,info[1]) == 2 then --说明有一对相反的牌
						local handInCards = table.copy(cards)
						paohuzitool.delCard(handInCards,info[1])
						paohuzitool.delCard(handInCards,info[2])

						local chis = {}
						chis.handInCards = handInCards
						chis.chiData = info
						chis.luoCount = 0
						chis.isChoose = 0
						chis.luoData = {}
						table.insert(chiList,chis)
					end
				else
					local chis = {}
					local handInCards = table.copy(cards)
					paohuzitool.delCard(handInCards,info[1])
					paohuzitool.delCard(handInCards,info[2])
					chis.handInCards = handInCards
					chis.chiData = info
					chis.luoCount = 0
					chis.isChoose = 0
					chis.luoData = {}
					table.insert(chiList,chis)
				end
			end
		end
	end
	if #chiList > 0 then
		return chiList
	end
	return nil
end

function paohuzitool.checkScore(huxi,type,beishu)
	local score
	if type == 1 then
		score = beishu*huxi
	elseif type == 2 then
		score = beishu*math.floor(huxi/3)
	elseif type == 3 then
		score = beishu*math.floor(huxi/6)
	end
	return score
end

local function rad(d)
	return (d*math.pi/180)
end

local function pow(x,y)
	return x^y
end

local function getDistance(lat1,lng1,lat2,lng2)
	local EARTH_RADIUS = 6378.137
	local radLat1 = rad(lat1)
	local radLat2 = rad(lat2)
	local a = radLat1 - radLat2
	local b = rad(lng1) - rad(lng2)
	local s = 2 * math.asin(math.sqrt(pow(math.sin(a/2),2) + math.cos(radLat1)*math.cos(radLat2)*pow(math.sin(b/2),2)))
	s = s * EARTH_RADIUS
	return tonumber(string.format('%.1f',s*1000))
end


function paohuzitool.setHuXi(user)
	local roundHuXiTmp = 0
	local ohterRoundHuXiTmp = 0
	for _, info in pairs(user.menzi) do
		local huXi = paohuzitool.getCardsTypeHuXi(info) or 0
		roundHuXiTmp = roundHuXiTmp + huXi
		if info.type ~= paohuzitool.cardType.kan and info.type ~= paohuzitool.cardType.she and info.type ~= paohuzitool.cardType.long then
			ohterRoundHuXiTmp = ohterRoundHuXiTmp + huXi
		end
	end
	
	user.ohterRoundHuXi = ohterRoundHuXiTmp
	user.roundHuXi = roundHuXiTmp
	return user.roundHuXi
end

function paohuzitool.checkDistance(lat,lng,users)
	for _, user in pairs(users) do
		local s = -1
		if lat and lng and user.lat and user.lng then
			s = getDistance(lat, lng, user.lat, user.lng)
			if s < 200 then
				return nil
			end
		end
	end
	return true
end

function paohuzitool.checkIp(ip,users)
	for _, user in pairs(users) do
		if user.ip ==  ip then
			return nil
		end
	end
	return true
end

function paohuzitool.jisuanXY(users)
	local locatingList = {}
	local globGpsColour = 1
	for _, muser in pairs(users) do
		local locatingInfo = {}
		locatingInfo.uid = muser.uid
		locatingInfo.playername = muser.playername 
		locatingInfo.usericon = muser.usericon
		locatingInfo.isOpen = 0
		locatingInfo.ip = muser.ip
		locatingInfo.headColour = 1
		locatingInfo.seat = muser.seat
		if muser.lat and muser.lng then
			locatingInfo.isOpen = 1
		end
		locatingInfo.data = {}
		
		for _, user in pairs(users) do
			if user.uid ~= muser.uid then
				local gpsColour = 1
				local info = {}
				local s = -1
				
				if muser.lat and muser.lng and user.lat and user.lng then
					s = getDistance(muser.lat,muser.lng,user.lat,user.lng)
				end
				if locatingInfo.isOpen == 1 and s < 200 and s > 0 then
					locatingInfo.headColour = 2
					gpsColour = 2
				end
				info.gpsColour = gpsColour
				info.uid = user.uid
				info.seat = user.seat
				info.locating = s
				info.playername = user.playername
				info.usericon = user.usericon
				table.insert(locatingInfo.data,info)
			end
		end
		table.insert(locatingList,locatingInfo)
	end
	
	if #locatingList > 1 then
		for _,info in pairs(locatingList) do
			if info.isOpen == 0 then
				globGpsColour = 2
				break
			end
		end
		for _,info in pairs(locatingList) do
			for _,user in pairs(info.data) do
				if user.gpsColour == 2 then
					globGpsColour = 3
				end
			end
			
		end
	end
	return locatingList,globGpsColour
end

return paohuzitool