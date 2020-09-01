local hongzhongtool = {}

local function rad(d)
	return (d*math.pi/180)
end

local function pow(x,y)
	return x^y
end

hongzhongtool.cardType = {
	guo = 1, --过
	put = 2, --打牌
	draw = 3, --抓牌
	peng = 4,--碰
	mgang = 5,--明杠
	agang = 6,--暗杠
	jgang = 7,--接杠
	fgang = 8,--放杠
	hupai = 9,--胡牌
	wait = 10,--等待别人操作
    gang = 11,--显示杠的按钮
}

hongzhongtool.HUPAI_TYPE = {
	liuju = -1, --流局
	normal = 1, --平胡
	ppHu = 2, --碰碰胡
	qdzHu = 3, --七对子胡
}

table.empty = function(t)
    return not next(t)
end

-- 深拷贝
table.copy = function(t, nometa)
    local result = {}

    if not nometa then
        setmetatable(result, getmetatable(t))
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = table.copy(v, nometa)
        else
            result[k] = v
        end
    end
    return result
end

-- 浅拷贝
table.clone = function(t, nometa)
    local result = {}
    if not nometa then
        setmetatable(result, getmetatable(t))
    end
    for k, v in pairs (t) do
        result[k] = v
    end
    return result
end


local function unique(t, bArray)  
    local check = {}  
    local n = {}  
    local idx = 1
    for k, v in pairs(t) do  
        if not check[v.value] then  
            if bArray then  
                n[idx] = v.value  
                idx = idx + 1  
            else  
                table.insert(n,v)
            end  
            check[v.value] = true  
        end  
    end  
    return n  
end

local function munique(t,caishen,bArray)  
    local check = {}  
    local n = {}  
    local idx = 1
    for k, v in pairs(t) do  
        if not check[v] then  
            if bArray then  
                n[idx] = v  
                idx = idx + 1  
            else  
                table.insert(n,v)
            end
            if v ~= caishen then
           		check[v] = true
           	end 
        end  
    end  
    return n  
end

local function printT(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, v)
    end
   	table.sort(result)
    --
    local str = ""
    for k, v in ipairs(result) do
        str = str .. v .. ","
    end
    --
    return str
end

local function insertList(t, t1)
    for i = 1, #t1 do
        table.insert(t, t1[i])
    end
end

local function seprateLaizi(t,LaiZi)
    local tTmpList = {}
    local laiziList = {}  
      
    for i = #t, 1, -1 do  
        local v = t[i]  
        if v == LaiZi then  
            table.insert(laiziList, v)  
        else
            table.insert(tTmpList, v)  
        end  
    end  
    return tTmpList, laiziList  
end 


local function removeOneNum(t, v)
    for i = 1, #t do
        if t[i] == v then
            table.remove(t, i)
            break
        end
    end
end

local function getSameNumCount(t, v)
    local count = 0
    for i = 1, #t do
        if v == t[i] then
            count = count + 1
        end
    end
    return count
end

local function getCardCount(cards)
	local valurNum = {}
	for _,card in pairs(cards) do
		if not valurNum[card] then
			valurNum[card] = 0
		end
	end

	local tmp_heb_cards = table.copy(cards)
	for i = 1,#tmp_heb_cards do
		for j = 1,#cards do
			if tmp_heb_cards[i] == cards[j] then
				tmp_heb_cards[i] = 0
				valurNum[cards[i]] = valurNum[cards[i]] + 1
			end
		end
	end
	return valurNum
end



function hongzhongtool.getValueCount(cards,card)
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

local function tiQuShunzi(t, v,caishen)  
    --
    local t, laiziList = seprateLaizi(t,caishen)
    --  
    table.sort(t)  
      
    local v1 = v  
    local v2 = v + 1  
    local v3 = v + 2  
    if v1 > 40 or v2 > 40 or v3 > 40 then
   		return nil,nil
   	end
    local needLaiziNum = 0  
    local remainLaiziNum = 0  
    local missV1, missV2, missV3  --缺失某个数字的标志 

    if getSameNumCount(t, v1) == 0 then  
        needLaiziNum = needLaiziNum + 1  
        missV1 = true  
    end
    if getSameNumCount(t, v2) == 0 then  
        needLaiziNum = needLaiziNum + 1  
        missV2 = true  
    end
    if getSameNumCount(t, v3) == 0 then  
        needLaiziNum = needLaiziNum + 1  
        missV3 = true  
    end
    remainLaiziNum = #laiziList - needLaiziNum  
    if remainLaiziNum < 0 then  
        return nil, nil  
    end
    --  
    local resultList = {v1, v2, v3}
    if not missV1 then
        table.insert(resultList, v1)
    else
        table.insert(resultList, laiziList[1])  
    end
    if not missV2 then
        table.insert(resultList, v2)  
    else
        table.insert(resultList, laiziList[1])  
    end
    if not missV3 then  
        table.insert(resultList, v3)  
    else  
        table.insert(resultList, laiziList[1])  
    end  
      
    local remainList = table.clone(t)  
    if not missV1 then  
       removeOneNum(remainList, v1)  
    else  
        removeOneNum(remainList, laiziList[1])  
    end  
    if not missV2 then  
        removeOneNum(remainList, v2)  
    else  
        removeOneNum(remainList, laiziList[1])  
    end  
    if not missV3 then  
        removeOneNum(remainList, v3)  
    else  
        removeOneNum(remainList, laiziList[1])  
    end  
    --  
    for i = 1,  remainLaiziNum do  
        table.insert(remainList, laiziList[1])  
    end  
    --  
    return resultList, remainList  
end

local function tiQuJiangOrKe(t, v,cashen, isJiang)  
    --
    local t, laiziList = seprateLaizi(t,cashen)  
    --  
    table.sort(t)  
    --  
    local resultList = {}   --  
    local remainList = table.clone(t)
    --
    local num = (isJiang and 2 or 3)
    --
    for i = #t, 1, -1 do
        local vTemp = remainList[i]
        if vTemp == v then
            table.insert(resultList, v)
            table.remove(remainList, i)
            if #resultList == num then
                break
            end
        end
    end
    --
    if #resultList == num then
        --放回赖子
        insertList(remainList, laiziList)
        return resultList, remainList
    else
        local needLaiziNum = num-#resultList
        local remainLaiziNum = #laiziList - needLaiziNum
        
        if remainLaiziNum < 0 then
            return nil, nil
        end
         
        if #resultList < num and (#laiziList >= needLaiziNum) then
            --提取结果中插入赖子
            for i = 1, needLaiziNum do
                table.insert(resultList, laiziList[1])
            end
            --剩余牌中插入多余的赖子
            for i = 1, remainLaiziNum do
                table.insert(remainList, laiziList[1])
            end
            --
            return resultList, remainList
       end
    end
    --  
    return nil, nil
end 



local function check_Hu(t, isHaveTiQuJiang, pai, huMap, cutInfo,caishen)

    --检查剩余的牌是否都是红中
    local srcT = table.copy(t)
    local nt, laiziList = seprateLaizi(srcT,caishen)
    if #t == #laiziList then
        huMap[1] = pai
        return
    end

    functionList = {
        tiQuJiangOrKe,
        tiQuShunzi
    }

    --剪支使用
    if cutInfo[printT(t)] then 
        return  
    else  
        cutInfo[printT(t)] = printT(t)  
    end
    --
  
    if #t == 0 then
        huMap[1] = pai
        return
    end
    table.sort(t)
      
    if not isHaveTiQuJiang then  --先提取将  
        for i = 1, #t do  
            local id = t[i]  
            local resultList, remainList = tiQuJiangOrKe(t, id,caishen, true)  
            if resultList then  
                isHaveTiQuJiang = true  
                check_Hu(remainList, isHaveTiQuJiang, pai, huMap, cutInfo,caishen)  
                isHaveTiQuJiang = false  
                insertList(remainList, resultList)  
                table.sort(remainList)  
            end  
        end  
    else --提取扑或者刻
        for i = 1, #t do  
            local functionList =  functionList  
              
            for j = 1, #functionList do  
                local id = t[i]
                local resultList, remainList = functionList[j](t, id,caishen)  
                if resultList then  
                    check_Hu(remainList, isHaveTiQuJiang, pai, huMap, cutInfo,caishen)  
                    insertList(remainList, resultList)  
                    table.sort(remainList)  
                end  
            end  
        end  
    end  
end

--七对子(2倍):可有财神的七个对子。
--七对子爆头(4倍):已有六个对子，最后一张用财神敲响为七对子爆头。
local function check_7DuiZi(t, caishenCount)
    if #t + caishenCount == 14 then
        local ps = 0 --对牌数
       	local valurNum = getCardCount(t)
    	local quandui = 0
    	for card,count in pairs(valurNum) do
    		if count >= 2 then
    			ps = ps + math.floor(count/2)
    		end
    	end
        local ss = 7 - ps
        -- print("ss="..tostring(ss).." cs="..tostring(caishenCount))
        --如果单牌数小于等于财神数则胡牌
        if ss <= caishenCount then
            return true
        end
    end
    return false
end

local function check_Hu_SP(tmp_cards_T,caishen)
	local htype = 0
    local bIsHu = false
    --分离癞子
    local srcT = table.copy(tmp_cards_T)
    local t, laiziList = seprateLaizi(srcT,caishen)
    --判断财神胡
    local caishenCount = #laiziList --财神个数
    if caishenCount == 4 then --四财神(2倍):有四张财神时，不需要组成基本胡牌牌型
        htype = hongzhongtool.HUPAI_TYPE.normal
        bIsHu = true
    end
    --7对子判断
    if check_7DuiZi(t, caishenCount) == true then
    	htype = hongzhongtool.HUPAI_TYPE.qdzHu
        bIsHu = true
    end
    return bIsHu, htype
end

function hongzhongtool.checkIsHu(tmp_cards, hcard)
    local cutInfo = {}
    local huMap = {}
    check_Hu(tmp_cards, false, hcard, huMap, cutInfo,35)
    if #huMap == 1 then
        return hcard
    else
        if check_Hu_SP(tmp_cards,35) then
            return hcard
        end
    end
end

local function pphu(user,tmp_cards,t,caishenCount,caishen,hcard)
    local ps = 0 --对牌数
    local valurNum = getCardCount(tmp_cards)
    local quandui = 0
    local dan = 0
    local dancard = {}
    local tdan = 0
    local isDan = false
    if #user.gangpai > 0 then return false end
    for card,count in pairs(valurNum) do
        if count == 1 and card ~= caishen then
            if isDan == false then
                dan = dan + 1
                isDan = true
            else
                dan = dan + 2
            end
        end
        if count == 2 and card ~= caishen then
            dan = dan + 1
        end
        if count == 4 and card ~= caishen then
           if isDan == false then
                dan = dan + 1
                isDan = true
            else
                dan = dan + 2
            end
        end
    end
   
    if dan <= caishenCount then
        return true
    end
    return false
end

function hongzhongtool.getHType(user,hcard)
    local ahtype = 0
    local ret = false
    local tmp_cards = table.copy(user.handInCards)
    local cutInfo = {}
    local huMap = {}
    check_Hu(tmp_cards, false, hcard, huMap, cutInfo,35)
    print("---555555--huMap------",huMap)
    if #huMap == 1 then
        ret = true
        local t, laiziList = seprateLaizi(tmp_cards,35)
        if pphu(user,tmp_cards,t,#laiziList,35,hcard) then
            ahtype = hongzhongtool.HUPAI_TYPE.ppHu
        else
            ahtype = hongzhongtool.HUPAI_TYPE.normal
        end
    else
        ret,ahtype = check_Hu_SP(tmp_cards,35)
    end
    print("--sp---ret------",ret)
    print("--sp---ahtype------",ahtype)
    return ret,ahtype
end

function hongzhongtool.getTingPaiInfo(user)
    local tingPaiList = {}
    for i = 1, 9 do
        if hongzhongtool.checkIsHu(user.handInCards, i) then
            table.insert(tingPaiList,i)
        end
    end
    for i = 11, 19 do
        if hongzhongtool.checkIsHu(user.handInCards, i) then
            table.insert(tingPaiList,i)
        end
    end

    for i = 21, 29 do
        if hongzhongtool.checkIsHu(user.handInCards, i) then
            table.insert(tingPaiList,i)
        end
    end
    if hongzhongtool.checkIsHu(user.handInCards, 35) then
        table.insert(tingPaiList,i)
    end
    return tingPaiList
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

function hongzhongtool.checkDistance(lat,lng,users)
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

function hongzhongtool.checkIp(ip,users)
	for _, user in pairs(users) do
		if user.ip ==  ip then
			return nil
		end
	end
	return true
end

function hongzhongtool.jisuanXY(users)
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

return hongzhongtool