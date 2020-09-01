local huZiGameHu = {}

huZiGameHu.cardType = {
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

local function getValueCount(cards,card)
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

local function sortHuPaiXin( a ,b)
	if a.huXi > b.huXi then
    	return true
    end
end

local function getPengOrSaoHuXi(pcard,user,isDraw,huXi)
	print("--------pcard--------",pcard)
	print("--------huXi--------",huXi)
	print("--------isDraw--------",isDraw)
	print("--------user.uid--------",user.uid)
	if isDraw and isDraw == user.uid then --自己抓的 就是扫 不需要处理
		return huXi
	else--碰的 减掉碰的分
		local sb = math.floor(pcard/100)
		if sb == 1 then --小碰 减2分
			huXi = huXi - 2
		else
			huXi = huXi - 3
		end
		return huXi
	end
end

local function getPaoOrTilongHuXi(pcard,user,isDraw,type,huXi,isHand)
	print("--------pcard--------",pcard)
	print("--------huXi--------",huXi)
	print("--------isDraw--------",isDraw)
	print("--------type--------",type)
	print("--------isHand--------",isHand)
	print("--------user.uid--------",user.uid)
	if isDraw and user.uid == isDraw then --自己抓的
		if type == huZiGameHu.cardType.kan then
			if isHand then --手上的 坎就不管
				return huXi
			else --门子的坎 需要减掉坎的分
				local sb = math.floor(pcard/100)
				if sb == 1 then --小坎 减3分
					huXi = huXi - 3
				else
					huXi = huXi - 6
				end
				return huXi
			end
		elseif type == huZiGameHu.cardType.peng then --碰的 先减3分当做跑 再减掉碰的分
			huXi = huXi - 3
			local sb = math.floor(pcard/100)
			if sb == 1 then --小碰 减1分
				huXi = huXi - 1
			else
				huXi = huXi - 3
			end
			return huXi
		end
	else--不是自己抓的
		if type == huZiGameHu.cardType.kan then
			if isHand then --手上的坎 减3分
				huXi = huXi - 3
				return huXi
			else --门子的坎 先减3分当做跑 再减掉坎的分
				huXi = huXi-3
				--减掉坎的分
				local sb = math.floor(pcard/100)
				if sb == 1 then --小坎 减3分
					huXi = huXi - 3
				else
					huXi = huXi - 6
				end
				return huXi
			end
		elseif type == huZiGameHu.cardType.peng then --碰的 先减3分当做跑 再减掉碰的分
			huXi = huXi - 3
			local sb = math.floor(pcard/100)
			if sb == 1 then --小碰 减1分
				huXi = huXi - 1
			else
				huXi = huXi - 3
			end
			return huXi
		end
	end
end

--检测胡牌 
function huZiGameHu.checkPaoHuZiHu(user,cards,pcard,isDraw,minHuXi,paoHuTingpaiLogic)
	
	local isNomal = nil
	local huPaiReslutList = {}

	local removeCards = nil
	local type = nil
	local addDuoYuHuxi = 0
	for _,info in pairs(user.menzi) do
		if info.type == huZiGameHu.cardType.kan and info.card == pcard then
			table.insert(cards,info.card)
			table.insert(cards,info.card)
			table.insert(cards,info.card)
			removeCards = pcard
			type = info.type
			local sb = math.floor(removeCards/100)
			if sb == 1 then --小坎 减3分
				addDuoYuHuxi = 3
			else
				addDuoYuHuxi = 6
			end
			break
		end
		if info.type == huZiGameHu.cardType.peng and info.card == pcard then
			table.insert(cards,info.card)
			table.insert(cards,info.card)
			table.insert(cards,info.card)
			removeCards = pcard
			type = info.type
			local sb = math.floor(removeCards/100)
			if sb == 1 then --小坎 减3分
				addDuoYuHuxi = 3
			else
				addDuoYuHuxi = 6
			end
			break
		end
	end
	print("-------pcard--------",pcard)
	print("-------type--------",type)
	print("-------user.uid--------",user.uid)
	print("-------isDraw--------",isDraw)
	print("-------cards--------",cards)
	local ret_tingHu = paoHuTingpaiLogic.getTingPaiRes(cards)
	for tingpaiValue,item in pairs(ret_tingHu) do
		print("-------item[3]--------",item[3])
		if pcard == item[3] then
			print("---1111----item[3]--------",item[3])
			--检测是不是跑胡 提龙胡 扫胡 碰胡
			local isAppend = true
			local twoIemtList = {}
			for _,itemInfo in pairs(item[2]) do
				if #itemInfo == 1 and isDraw and user.uid == isDraw and getValueCount(cards,pcard) == 2 then --单调的话 并且自己抓的话 并且自己有两张这种牌的话 直接不让胡 扫烂了
					isAppend = false
				end
				if #itemInfo == 2 then
					table.insert(twoIemtList,itemInfo)
				end
			end
			if isDraw then
				if user.uid == isDraw then
					if not type or type == huZiGameHu.cardType.kan then
						if getValueCount(cards,pcard) >= 2 then
							if #twoIemtList == 2 then 
								if twoIemtList[1][1] == twoIemtList[1][2] and twoIemtList[2][1] == twoIemtList[2][2] then--先判断是不是两对
									if getValueCount(cards,pcard) == 3 then
										isAppend = false
									end
								else --如果只有一对 如 202,202  207,210 那么就只能扫
									if twoIemtList[1][1] == twoIemtList[1][2] and twoIemtList[1][1] == pcard then
										isAppend = false
									end
									if twoIemtList[2][1] == twoIemtList[2][2] and twoIemtList[2][1] == pcard then
										isAppend = false
									end

									if twoIemtList[1][1] == twoIemtList[1][2] and getValueCount(cards,pcard) >= 2 then
										isAppend = false
									end
									if twoIemtList[2][1] == twoIemtList[2][2] and getValueCount(cards,pcard) >= 2 then
										isAppend = false
									end
								end
							elseif #twoIemtList == 1 then  --
								if twoIemtList[1][1] ~= twoIemtList[1][2]  then
									if twoIemtList[1][1] == pcard or twoIemtList[1][2] == pcard then
										isAppend = false
									else 
										if getValueCount(cards,pcard) >= 2 then
											isAppend = false
										end
									end
								else
									if getValueCount(cards,pcard) == 2 and twoIemtList[1][1] ~= pcard then --一对 但是事方子
										isAppend = false
									end
								end
							end
						end
					end
				end
			end
			if isAppend then
				local handHuXi = item[1]
				if #twoIemtList == 1 then
					if twoIemtList[1][1] == twoIemtList[1][2] then
						if getValueCount(cards,pcard) == 3 then --跑胡或者踢龙判断
							local htype
							local isHand
							if not type then
								isHand = true
								htype = huZiGameHu.cardType.kan
							else
								htype = type
							end
							handHuXi = getPaoOrTilongHuXi(pcard,user,isDraw,htype,handHuXi,isHand)
						end
						if getValueCount(cards,pcard) == 2 and twoIemtList[1][1] == pcard then --碰胡获取扫胡取分
							handHuXi = getPengOrSaoHuXi(pcard,user,isDraw,handHuXi)
						end
					else --204,205 胡 206 正好206是个碰 或者坎
						if getValueCount(cards,pcard) == 3 then
							handHuXi = handHuXi - 3
						end
					end
				elseif #twoIemtList == 2 then
					if twoIemtList[1][1] == twoIemtList[1][2] and twoIemtList[2][1] == twoIemtList[2][2] then
						if getValueCount(cards,pcard) == 2 then --碰胡或者扫胡
							if twoIemtList[1][1] == pcard or twoIemtList[2][1] == pcard then
								handHuXi = getPengOrSaoHuXi(pcard,user,isDraw,handHuXi)
							end
						elseif getValueCount(cards,pcard) == 3 and removeCards then --重跑胡 需要减掉之前的插进来坎的分
							handHuXi = handHuXi - addDuoYuHuxi
						end
					else
						if getValueCount(cards,pcard) == 3 and removeCards then --重跑胡
							handHuXi = handHuXi - addDuoYuHuxi
						end
					end
				end
				if handHuXi+user.roundHuXi >= minHuXi then
					local handHuCards = getHuPaiCards(item[2],removeCards,true)
					local huPaiInfo = {}
					huPaiInfo.huXi = handHuXi+user.roundHuXi
					huPaiInfo.handHuCards = handHuCards
					table.insert(huPaiReslutList,huPaiInfo)
				end
			end
		end
	end
	print("---00------huPaiReslutList------",huPaiReslutList)
	if #huPaiReslutList > 0 then 
		table.sort(huPaiReslutList, sortHuPaiXin)
		print("---11------huPaiReslutList------",huPaiReslutList)
		return true,huPaiReslutList[1].huXi,huPaiReslutList[1].handHuCards
	end
end

--获取听牌信息
function huZiGameHu.getTingPaiInfo(user,paoHuTingpaiLogic,minHuXi)
	local tingPaiInfo = {}
	local ret_tingHu = paoHuTingpaiLogic.getTingPaiRes(user.handInCards)
	for tingpaiValue,item in pairs(ret_tingHu) do
		local twoIemtList = {}
		for _,itemInfo in pairs(item[2]) do
			if #itemInfo == 2 then
				table.insert(twoIemtList,itemInfo)
			end
		end

		if item[1] + user.roundHuXi >= minHuXi then
			table.insert(tingPaiInfo,item[3])
		end

		--如果手上是两对 就不考虑门子里面的胡牌了
		if #twoIemtList == 1 then
			if twoIemtList[1][1] == twoIemtList[1][2] then--先判断是不是对子
				--需要减掉这个对子的坎分
				local hsb = math.floor(twoIemtList[1][1]/100)
				if hsb == 1 then
					item[1] = item[1] - 3
				else
					item[1] = item[1] - 6
				end

				for _, info in pairs(user.menzi) do
					local addHuXi = 0
					if info.type == huZiGameHu.cardType.kan or info.type == huZiGameHu.cardType.peng then
						if info.type == huZiGameHu.cardType.peng then
							local sb = math.floor(info.card/100)
							if sb == 1 then --
								addHuXi = 5
							else
								addHuXi = 6
							end
						end
						if item[1] + user.roundHuXi + addHuXi >= minHuXi then 
							table.insert(tingPaiInfo,info.card)
						end
					end
				end
				for _, info in pairs(user.menzi) do
					local addHuXi = 0
					if info.type == huZiGameHu.cardType.kan or info.type == huZiGameHu.cardType.peng then
						if info.type == huZiGameHu.cardType.kan then
							addHuXi = 6
						end
						if item[1] + user.roundHuXi + addHuXi >= minHuXi then 
							table.insert(tingPaiInfo,info.card)
						end
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


return huZiGameHu