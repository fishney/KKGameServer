local pengHuTingpaiLogic = require "pengTingpaiLogic"
local penghutool = {}
penghutool.cardType = {
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
	pengSan = 11,--碰三
	kanSan = 12,--扫三
	pengSi = 13,--碰四
	kanSi = 14,--坎四
}

penghutool.ACTION_SCORE = {
	[5] = 1,--碰
	[6] = 2, --喂牌
	[7] = 4, --跑
	[8] = 8,--踢龙  本来是喂的牌,又抓了一张
	[9] = 10, --蛇 发牌就发了4张的
	[11] = 5,--碰三
	[12] = 6,--扫三
	[13] = 5,--碰四
	[14] = 6,--扫四
}

penghutool.HUPAI_TYPE = {
	liuju = -1, --流局
	normal = 1, --平胡
	tianHu = 2, --天胡
	diHu = 3, --地胡
	tilongHu = 4, --踢龙胡
	paoHu = 5, --跑胡
	saoHu = 6, --扫胡
	pengHu = 7,--碰胡
	pengSanHu = 8, --碰三胡
	saoSanHu = 9, --扫胡
	pengSiHu = 10, --碰四胡
	saoSiHu = 11, --扫四胡
	shuangLongHu = 12, --双龙
	xiaoQiDuiHu = 13, --小七对
	paoDiHu = 14, --跑地胡
	pengDiHu = 15, --碰地胡
	wuHu = 16, --五福
}


penghutool.HUPAI_HU_XI = {
	[1] = {--大牌
		[4] = 3,--吃
		[5] = 1,--碰
		[6] = 3, --喂牌
		[7] = 6, --跑
		[8] = 9,--踢龙  本来是喂的牌,又抓了一张
		[9] = 9, --蛇 发牌就发了4张的
	},
	[2] = {--小牌
		[4] = 6,--吃
		[5] = 3,--碰
		[6] = 6, --喂牌
		[7] = 9, --跑
		[8] = 12,--踢龙  本来是喂的牌,又抓了一张
		[9] = 12, --蛇 发牌就发了4张的
	},
	
}


--胡牌类型
penghutool.HUPAI_SCORE = {
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
penghutool.lpType = {
	draw = 1,
	put = 2,
}

local chiPai = {
	["small"] = {
		[101] = {{102,103},{101,201},{201,201}},
		[102] = {{101,103},{103,104},{107,110},{102,202},{202,202}},
		[103] = {{101,102},{102,104},{104,105},{103,203},{203,203}},
		[104] = {{102,103},{103,105},{105,106},{104,204},{204,204}},
		[105] = {{103,104},{104,106},{106,107},{105,205},{205,205}},
		[106] = {{104,105},{105,107},{107,108},{106,206},{206,206}},
		[107] = {{105,106},{106,108},{108,109},{102,110},{107,207},{207,207}},
		[108] = {{106,107},{107,109},{109,110},{108,208},{208,208}},
		[109] = {{107,108},{109,209},{108,110},{209,209}},
		[110] = {{108,109},{102,107},{110,210},{210,210}},
	},
	["big"] = {
		[201] = {{202,203},{201,101},{101,101}},
		[202] = {{201,203},{203,204},{207,210},{102,202},{102,102}},
		[203] = {{201,202},{202,204},{204,205},{103,203},{103,103}},
		[204] = {{202,203},{203,205},{205,206},{104,204},{104,104}},
		[205] = {{203,204},{204,206},{206,207},{105,205},{105,105}},
		[206] = {{204,205},{205,207},{207,208},{106,206},{106,106}},
		[207] = {{205,206},{206,208},{208,209},{202,210},{107,207},{107,107}},
		[208] = {{206,207},{207,209},{209,210},{108,208},{108,108}},
		[209] = {{207,208},{208,210},{109,209},{109,109}},
		[210] = {{208,209},{202,207},{110,210},{110,110}},
	},
}
function penghutool.findCard(tbl,value)
	for k,v in ipairs(tbl) do
	      if v == value then
	          return true
	      end
    end
end

function penghutool.delCard(cards,pcard)
	for i,card in pairs(cards) do
		if card == pcard then
			table.remove(cards,i)
			break
		end
	end
end

--查看小七对
function checkXiaoQiDui(user)
	local tables = {}
	for i = 1,#user.handInCards do
		if not tables[user.handInCards[i]] then
			tables[user.handInCards[i]] = 1
		else
			tables[user.handInCards[i]] = tables[user.handInCards[i]] + 1
		end
	end
	local duiCount = 0
	local sheCount = 0
	
	for card,count in pairs(tables) do
		if count == 4 then
			duiCount = duiCount + 2
			sheCount = sheCount + 1
		end
		if count == 3 then
			duiCount = duiCount + 1
		end
		if count == 2 then
			duiCount = duiCount + 1
		end
	end
	if duiCount == 7 then
		return penghutool.HUPAI_TYPE.xiaoQiDuiHu
	end
	if sheCount == 2 then
		return penghutool.HUPAI_TYPE.shuangLongHu
	end
end

--检测胡牌 
function penghutool.checkPaoHuZiHu(user,cards,pcard)
	local ret_tingHu = pengHuTingpaiLogic.getTingPaiRes(cards)
	for tingpaiValue,item in pairs(ret_tingHu) do
		if pcard == tingpaiValue then
			--检测是不是跑胡
			if item[1]+user.roundHuXi >= 5 then
				return item[1]+user.roundHuXi
			end
		end
	end
end

local chiHuXi = {
	[1] = {
		[1] = {101,102,103},
		[2] = {101,205,110},
		[3] = {102,107,110},
	},
	[2] = {
		[1] = {201,202,203},
		[2] = {201,205,210},
		[3] = {202,207,210},
		
	}
}

local function checkChiHuxi(cards,sb)
	for mult,data in pairs(chiHuXi[sb]) do
		if data[1] == cards[1] and data[2] == cards[2] and data[3] == cards[3] then
			return mult * 3
		end
	end
	return 0
end


--获取对应牌型的胡息
function penghutool.getCardsTypeHuXi(info)
	--判断吃 是不是1510
	local infoTmp = table.copy(info)
	local sb = 0
	if infoTmp.type == penghutool.cardType.chi then
		sb = math.floor(infoTmp.data[1] / 100)
	  	return checkChiHuxi(infoTmp.data,sb)
	else
		sb = math.floor(infoTmp.card / 100)
		return penghutool.HUPAI_HU_XI[sb][infoTmp.type]
	end
end

--获取听牌信息
function penghutool.getTingPaiInfo(user)
		local tingPaiInfo = {}
	local ret_tingHu = pengHuTingpaiLogic.getTingPaiRes(user.handInCards)
	for tingpaiValue,item in pairs(ret_tingHu) do
		local twoIemtList = {}
		for _,itemInfo in pairs(item[2]) do
			if #itemInfo == 2 then
				table.insert(twoIemtList,itemInfo)
			end
		end

		table.insert(tingPaiInfo,item[3])
		
		--如果手上是两对 就不考虑门子里面的胡牌了
		if #twoIemtList == 1 then 
			if twoIemtList[1][1] == twoIemtList[1][2] then--先判断是不是对子
				for _, info in pairs(user.menzi) do
					if info.type == penghutool.cardType.kan or info.type == penghutool.cardType.peng then
						table.insert(tingPaiInfo,info.card)
					end
				end
			end
		end
	end
	local tables = {}
	for i = 1,#tingPaiInfo do
		if not tables[tingPaiInfo[i]] then
			tables[tingPaiInfo[i]] = 1
		else
			tables[tingPaiInfo[i]] = tables[tingPaiInfo[i]] + 1
		end
	end
	tingPaiInfo = {}
	for value, _ in pairs(tables) do
		table.insert(tingPaiInfo,value)
	end
	table.sort(tingPaiInfo)
	user.tingPaiInfo = tingPaiInfo
	return tingPaiInfo
end

--
local function gePengAndSaoTypeHuCnt(user,isDraw)
	local cnt = 0
	for _, menziInfo in pairs(user.menzi) do
		if menziInfo.type == penghutool.cardType.peng or menziInfo.type == penghutool.cardType.kan or menziInfo.type == penghutool.cardType.pao or menziInfo.type == penghutool.cardType.long or menziInfo.type == penghutool.cardType.she then
			cnt = cnt + 1
		end
	end
	local huPaiType
	if isDraw and isDraw == user.uid then
		if cnt == 2 then
			huPaiType = penghutool.HUPAI_TYPE.saoSanHu
		elseif cnt == 3 then
			huPaiType = penghutool.HUPAI_TYPE.saoSiHu
		elseif cnt == 4 then
			huPaiType = penghutool.HUPAI_TYPE.wuHu
		else
			huPaiType = penghutool.HUPAI_TYPE.saoHu
		end
	else
		if cnt == 2 then
			huPaiType = penghutool.HUPAI_TYPE.pengSanHu
		elseif cnt == 3 then
			huPaiType = penghutool.HUPAI_TYPE.pengSiHu
		elseif cnt == 4 then
			huPaiType = penghutool.HUPAI_TYPE.wuHu
		else
			huPaiType = penghutool.HUPAI_TYPE.pengHu
		end
	end
	return huPaiType
end

local function gePaoAndTilongTypeHuCnt(user,isDraw,type)
	if isDraw  then
		if user.uid == isDraw then --自己抓的踢龙
			if type == penghutool.cardType.kan then
				return penghutool.HUPAI_TYPE.tilongHu
			else
				return penghutool.HUPAI_TYPE.paoHu
			end
		else
			return penghutool.HUPAI_TYPE.paoHu
		end
	else
		if type == penghutool.cardType.kan then
			return penghutool.HUPAI_TYPE.paoHu
		end
	end
end
 
--检测胡牌
function penghutool.checkHu(user,cards,pcard,isDraw)
	if penghutool.findCard(user.notHuPai,pcard) then
		return nil
	end
	if user.isBaoJin then
		if user.isBaoJin == pcard then
			return nil
		end
	end

	local huPaiType = checkXiaoQiDui(user)
	if huPaiType then
		return huPaiType
	end

	local type = nil
	for _,info in pairs(user.menzi) do
		if info.type == penghutool.cardType.peng and info.card == pcard then
			table.insert(cards,info.card)
			table.insert(cards,info.card)
			table.insert(cards,info.card)
			type = info.type
			break
		end

		if info.type == penghutool.cardType.kan and info.card == pcard then
			table.insert(cards,info.card)
			table.insert(cards,info.card)
			table.insert(cards,info.card)
			type = info.type
			break
		end
	end
	local huPaiTypeList = {}
	if pcard then
		local ret_tingHu = pengHuTingpaiLogic.getTingPaiRes(cards)
		for tingpaiValue,item in pairs(ret_tingHu) do
			if pcard == item[3] then

				
				--检测是不是碰胡
				local isAppend = true
				local twoIemtList = {}
				for _,itemInfo in pairs(item[2]) do
					if #itemInfo == 1 and isDraw and penghutool.getValueCount(cards,pcard) == 2 and isDraw == user.uid then --单调的话 并且自己抓的话 并且自己有两张这种牌的话 直接不让胡 扫烂了
						isAppend = false
					end
					if #itemInfo == 2 then
						table.insert(twoIemtList,itemInfo)
					end
				end
				print("---twoIemtList------",twoIemtList)
				print("---isDraw------",isDraw)
				if penghutool.getValueCount(cards,pcard) >= 2 and isDraw == user.uid then
					if #twoIemtList == 2 then 
						if twoIemtList[1][1] == twoIemtList[1][2] and twoIemtList[2][1] == twoIemtList[2][2] then--先判断是不是两对
							if penghutool.getValueCount(cards,pcard) == 3 and type == penghutool.cardType.kan then
								isAppend = false
							end
						else --如果只有一对 如 202,202  207,210 那么就只能扫
							if twoIemtList[1][1] == twoIemtList[1][2] and twoIemtList[1][1] == pcard then
								isAppend = false
							end
							if twoIemtList[2][1] == twoIemtList[2][2] and twoIemtList[2][1] == pcard then
								isAppend = false
							end
							
							if twoIemtList[1][1] == twoIemtList[1][2] then
								if  penghutool.getValueCount(cards,pcard) == 3 and type == penghutool.cardType.kan then
									isAppend = false
								end
								if  penghutool.getValueCount(cards,pcard) == 2 then
									isAppend = false
								end
							end
							if twoIemtList[2][1] == twoIemtList[2][2] then
								if  penghutool.getValueCount(cards,pcard) == 3 and type == penghutool.cardType.kan then
									isAppend = false
								end
								if  penghutool.getValueCount(cards,pcard) == 2 then
									isAppend = false
								end
							end
						end
					elseif #twoIemtList == 1 then  --
						if twoIemtList[1][1] ~= twoIemtList[1][2] then
							if twoIemtList[1][1] == pcard or twoIemtList[1][2] == pcard then
								isAppend = false
							else
								if penghutool.getValueCount(cards,pcard) >= 2 then
									isAppend = false
								end
							end
						else
							if penghutool.getValueCount(cards,pcard) == 2 and twoIemtList[1][1] ~= pcard then --一对 但是事方子
								isAppend = false
							end
						end
					end
				end
				if isAppend then
					huPaiType = penghutool.HUPAI_TYPE.normal
					if #twoIemtList == 1 then
						if twoIemtList[1][1] == twoIemtList[1][2] then
							if penghutool.getValueCount(cards,pcard) == 3 then --跑胡或者踢龙判断
								huPaiType = gePaoAndTilongTypeHuCnt(user,isDraw,type)
							end
							if penghutool.getValueCount(cards,pcard) == 2 and twoIemtList[1][1] == pcard then --碰胡判断
								huPaiType = gePengAndSaoTypeHuCnt(user,isDraw)
							end
						end
					elseif #twoIemtList == 2 then
						if twoIemtList[1][1] == twoIemtList[1][2] and twoIemtList[2][1] == twoIemtList[2][2] then
							if penghutool.getValueCount(cards,pcard) == 2 then --碰胡或者扫胡
								if twoIemtList[1][1] == pcard or twoIemtList[2][1] == pcard then
									huPaiType = gePengAndSaoTypeHuCnt(user,isDraw)
								end
							end
						end
					end
					table.insert(huPaiTypeList,huPaiType)
				end
			end
		end
	end

	if #huPaiTypeList > 0 then  --因为会存在自己是个 22 77 89 10这样的牌 可以单吊大二 实际上我我用一对大二胡 能赢更多的分
		table.sort(huPaiTypeList,function(a,b)return (a> b) end)
		print("---huPaiTypeList[1]------",huPaiTypeList[1])
		return huPaiTypeList[1]
	end
end

--检测坎跑
function penghutool.checkKanPao(user,pcard)
	for _,info in pairs(user.menzi) do
		if info.type == penghutool.cardType.kan and pcard == info.card then
			return true
		end
	end
end

--检测p碰跑
function penghutool.checkPengPao(user,pcard)
	for _,info in pairs(user.menzi) do
		if info.type == penghutool.cardType.peng and pcard == info.card then
			return true
		end
	end
end

--检测踢龙
function penghutool.checkTiLong(user,pcard)
	for _,info in pairs(user.menzi) do
		if info.type == penghutool.cardType.kan and pcard == info.card then
			return true,penghutool.cardType.long
		end
	end
	if penghutool.getValueCount(user.handInCards,pcard) == 3 then
		return true,penghutool.cardType.handlong
	end
end

function penghutool.getValueCount(cards,card)
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


function penghutool.chekBaojin(user,putCard)
	if #user.handInCards == 3 then
		local tables = {}
		for i = 1,#user.handInCards do
			if not tables[user.handInCards[i]] then
				tables[user.handInCards[i]] = 1
			else
				tables[user.handInCards[i]] = tables[user.handInCards[i]] + 1
			end
		end
		local notHuCard = 0
		for card, count in pairs(tables) do
			if card ~= putCard and count == 2 then
				local sb = math.floor(card/100)
				local chiCardTypeList = {}
				if sb == 1 then
					notHuCard = 200+(card%100)
				else
					notHuCard = 100+(card%100)
				end
				break
			end
		end
		if notHuCard > 0 then
			local scoeTypeCnt = 0
			for _, menziInfo in pairs(user.menzi) do
				if menziInfo.type == penghutool.cardType.peng or menziInfo.type == penghutool.cardType.kan then
					scoeTypeCnt = scoeTypeCnt + 1
				end
			end
			if scoeTypeCnt == 4 then
				return notHuCard
			end
		end
	end
	return nil
end

--检测碰
function penghutool.checkPeng(user,pcard)
	if penghutool.findCard(user.notPengPai,pcard) then
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
			return penghutool.cardType.peng
		end
	end
end

--检测sao
function penghutool.checkSao(user,pcard)
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
			return penghutool.cardType.kan
		end
	end
end

--检测有没有蛇
function penghutool.checkHandShe(cards)
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

local function getLuo(chiCardTypeList,cards,pcard,luoCount)
	local luoData = {}
	for _, info in pairs(chiCardTypeList) do
		if penghutool.findCard(cards, info[1]) and penghutool.findCard(cards, info[2]) then
			local data
			if info[1] == info[2] then
				if penghutool.getValueCount(cards,info[1]) == 2 then
					local data = {}
					data[1] = info[1]
					data[2] = info[2]
					data[3] = pcard
					table.insert(luoData,data)
				end
			elseif pcard == info[1]  then
				if penghutool.getValueCount(cards,info[1]) == 2  then
					local data = {}
					data[1] = info[1]
					data[2] = info[2]
					data[3] = pcard
					table.insert(luoData,data)
				end
			elseif  pcard == info[2] then
				if  penghutool.getValueCount(cards,info[2]) == 2 then
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
				if penghutool.getValueCount(cards,info[1]) == 2 and penghutool.getValueCount(cards,info[2]) == 2 and penghutool.getValueCount(cards,pcard) == 2 then
					local data = {}
					data[1] = info[1]
					data[2] = info[2]
					data[3] = pcard
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
function penghutool.checkChi(user,pcard,suser)
	if #user.handInCards < 4 then
		return nil
	end
	if penghutool.findCard(user.notChiPai,pcard) then
		return nil
	end

	if penghutool.findCard(suser.qipai,pcard) then
		return nil
	end

	local cards = table.copy(user.handInCards)
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
		if penghutool.findCard(cards, info[1]) and penghutool.findCard(cards, info[2]) then
			--先查找是否存在吃的牌
			local count = penghutool.getValueCount(cards,pcard)
			if count == 1 then
				if info[1] == pcard or info[2] == pcard then
					local handInCards = table.copy(cards)
					penghutool.delCard(handInCards,info[1])
					penghutool.delCard(handInCards,info[2])
					local chis = {}
					chis.handInCards = handInCards
					chis.chiData = info
					chis.luoCount = 0
					chis.isChoose = 0
					chis.luoData = {}
					table.insert(chiList,chis)
				else
					if info[1] == info[2] then
						if penghutool.getValueCount(cards,info[1]) == 2 then --说明有一对相反的牌
							local tmpCards = table.copy(cards)
							penghutool.delCard(tmpCards,info[1])
							penghutool.delCard(tmpCards,info[2])
							local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,1)
							if luoData then
								local handInCards = table.copy(cards)
								penghutool.delCard(handInCards,info[1])
								penghutool.delCard(handInCards,info[2])
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
						penghutool.delCard(tmpCards,info[1])
						penghutool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,1)
						if luoData then
							local handInCards = table.copy(cards)
							penghutool.delCard(handInCards,info[1])
							penghutool.delCard(handInCards,info[2])
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
					if penghutool.getValueCount(cards,info[1]) == 2 then --说明有一对相反的牌
						local tmpCards = table.copy(cards)
						penghutool.delCard(tmpCards,info[1])
						penghutool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,2)
						if luoData and #luoData > 1  then
							local handInCards = table.copy(cards)
							penghutool.delCard(handInCards,info[1])
							penghutool.delCard(handInCards,info[2])

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
						penghutool.delCard(tmpCards,pcard)
						penghutool.delCard(tmpCards,info[1])
						penghutool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,1)
						if luoData then
							local handInCards = table.copy(cards)
							penghutool.delCard(handInCards,info[1])
							penghutool.delCard(handInCards,info[2])
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
						penghutool.delCard(tmpCards,pcard)
						penghutool.delCard(tmpCards,info[1])
						penghutool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,1)
						if luoData then
							local handInCards = table.copy(cards)
							penghutool.delCard(handInCards,info[1])
							penghutool.delCard(handInCards,info[2])
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
						penghutool.delCard(tmpCards,info[1])
						penghutool.delCard(tmpCards,info[2])
						local luoData  = getLuo(chiCardTypeList,tmpCards,pcard,2)
						if luoData and #luoData > 0 then
							local chis = {}
							local handInCards = table.copy(cards)
							penghutool.delCard(handInCards,info[1])
							penghutool.delCard(handInCards,info[2])

							chis.handInCards = handInCards
							chis.chiData = info
							if penghutool.findCard(cards, tmpCard) then
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
					if penghutool.getValueCount(cards,info[1]) == 2 then --说明有一对相反的牌
						local handInCards = table.copy(cards)
						penghutool.delCard(handInCards,info[1])
						penghutool.delCard(handInCards,info[2])

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
					penghutool.delCard(handInCards,info[1])
					penghutool.delCard(handInCards,info[2])
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

function penghutool.checkDistance(lat,lng,users)
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

function penghutool.checkIp(ip,users)
	for _, user in pairs(users) do
		if user.ip ==  ip then
			return nil
		end
	end
	return true
end

function penghutool.jisuanXY(users)
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


------------------红黑胡算分和名堂----------------------
function penghutool.checkScore(cards,huxi,difen,beishu)
	local mingTang = 0--没有名堂
	local redNum = 0 --红色张数
	local score = 0 -- 分数
	for _,card in pairs(cards) do
		if card == 102 or card == 107 or card == 110 or card == 202 or card == 207 or card == 210 then
			redNum = redNum + 1
		end
	end
	if redNum == 10 then
		huxi = huxi * 2
		mingTang =  1
	elseif redNum == 13 then
		huxi = huxi * 4
		mingTang = 2
	elseif redNum == 0 then
		huxi = huxi * 5
		mingTang = 3
	elseif redNum == 1 then
		huxi = huxi * 3
		mingTang = 4
	end

	if difen == 0 then
		score = huxi
	else
		score = math.floor((huxi - 15)/3) + difen
	end

	return score * beishu,mingTang
end

return penghutool