local hztool = {}


PDEFINE.HUPAI_TYPE =
{
    ["ENUM_MJHU_PH"]         = 1,         --平胡
    ["ENUM_MJHU_PPH"]        = 2,         --碰碰胡
    ["ENUM_MJHU_QDZ"]        = 3,         --七对子
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

local function check_qingSe(user,hcard,caishenCount,tmp_cards_T)
	local tmp_cards = table.copy(tmp_cards_T)
	if #user.gangpai > 0 then
		for _, gang in pairs(user.gangpai) do
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
		end
	end

	if #user.pengpai > 0 then
		for _, peng in pairs(user.pengpai) do
			table.insert(tmp_cards,peng.card)
			table.insert(tmp_cards,peng.card)
			table.insert(tmp_cards,peng.card)
		end
	end

	if #user.chipai > 0 then
		for _, chipaiInfo in pairs(user.chipai) do
			table.insert(tmp_cards,chipaiInfo.card1)
			table.insert(tmp_cards,chipaiInfo.card2)
			table.insert(tmp_cards,chipaiInfo.card3)
		end
	end
	local tiao = {type = "taio",count = 0}
	local tong = {type = "tong",count = 0}
	local wan = {type = "wan",count = 0}
	for _,card in pairs(tmp_cards) do
		if card > 10 and card < 20 then
			tiao.count = tiao.count + 1
		end
	end

	for _,card in pairs(tmp_cards) do
		if card > 20 and card < 30 then
			tong.count = tong.count + 1
		end
	end

	for _,card in pairs(tmp_cards) do
		if card > 30 and card < 40 then
			wan.count = wan.count + 1
		end
	end

	local feng = 0
	for _,card in pairs(tmp_cards) do
		if card > 40 and card < 48 then
			feng = feng + 1
		end
	end
	local zt = {}
	table.insert(zt,tiao)
	table.insert(zt,tong)
	table.insert(zt,wan)
	table.sort(zt,function(a,b) return a.count < b.count end)
	if caishenCount >= zt[1].count + zt[2].count + feng then
		return true
	end
end

local function check_QingFeng(user,t,caishenCount)
	local tmp_cards = table.copy(t)
	if #user.gangpai > 0 then
		for _, gang in pairs(user.gangpai) do
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
		end
	end

	if #user.pengpai > 0 then
		for _, peng in pairs(user.pengpai) do
			table.insert(tmp_cards,peng.card)
			table.insert(tmp_cards,peng.card)
			table.insert(tmp_cards,peng.card)
		end
	end

	if #user.chipai > 0 then
		for _, chipaiInfo in pairs(user.chipai) do
			table.insert(tmp_cards,chipaiInfo.card1)
			table.insert(tmp_cards,chipaiInfo.card2)
			table.insert(tmp_cards,chipaiInfo.card3)
		end
	end
	for _,v in ipairs(tmp_cards) do
        if v < 41 then
            return false
        end
    end
    return true
end

local function check_hunSe(user,hcard,caishenCount,tmp_cards_T)
	local tmp_cards = table.copy(tmp_cards_T)
	if #user.gangpai > 0 then
		for _, gang in pairs(user.gangpai) do
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
			table.insert(tmp_cards,gang.card)
		end
	end

	if #user.pengpai > 0 then
		for _, peng in pairs(user.pengpai) do
			table.insert(tmp_cards,peng.card)
			table.insert(tmp_cards,peng.card)
			table.insert(tmp_cards,peng.card)
		end
	end

	if #user.chipai > 0 then
		for _, chipaiInfo in pairs(user.chipai) do
			table.insert(tmp_cards,chipaiInfo.card1)
			table.insert(tmp_cards,chipaiInfo.card2)
			table.insert(tmp_cards,chipaiInfo.card3)
		end
	end
	local tiao = {type = "taio",count = 0}
	local tong = {type = "tong",count = 0}
	local wan = {type = "wan",count = 0}
	for _,card in pairs(tmp_cards) do
		if card > 10 and card < 20 then
			tiao.count = tiao.count + 1
		end
	end

	for _,card in pairs(tmp_cards) do
		if card > 20 and card < 30 then
			tong.count = tong.count + 1
		end
	end

	for _,card in pairs(tmp_cards) do
		if card > 30 and card < 40 then
			wan.count = wan.count + 1
		end
	end
	local zt = {}
	table.insert(zt,tiao)
	table.insert(zt,tong)
	table.insert(zt,wan)
	table.sort(zt,function(a,b) return a.count < b.count end)
	if caishenCount >= zt[1].count + zt[2].count then
		return true
	end
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
--检测十三幺类胡牌
--huType: 
--1:真十三不靠(2倍):东、南、西、北、中、发、白任意5张。加手里的牌必须间隔两张，如147、258、369，可使用财神代替，但白板只能代替白板。
--2:十三不靠(1倍):东、南、西、北、中、发、白任意5张。加其余至少相隔两张的牌。
--3:真七风不靠(4倍):真13不靠加七风胡牌。东、南、西、北、中、发、白加其余至少相隔两张的牌，一定要相隔两张比如：147、258、369.
--4:七风(2倍):东、南、西、北、中、发、白七张齐全。加其余至少相隔两张的牌。财神不能替风牌。

function seprateHuase(t)
    local tTiao = {}
    local tTong = {}
    local tWan = {}  
    local tFeng = {}
    for i = 1, #t do  
        local v = math.floor(t[i] / 10.0)
        if v == 1 then     --条 
            table.insert(tTiao, t[i])  
        elseif v == 2 then --筒
            table.insert(tTong, t[i])  
        elseif v == 3 then  --万
            table.insert(tWan, t[i])  
        elseif v == 4 then --风
            table.insert(tFeng, t[i])  
        end
    end 
    return tTiao, tTong, tWan, tFeng
end

--check 147,258,369
--ret:-1:不成立
----- 11:单牌
----- 21:两张(间隔2张/14/25/36)
----- 22:两张(间隔5张/17/28/39)
----- 23:两张(其他大于间隔3和4个的) 
------31:三张(147/258/369)
------32:三张-大于间隔两个(如:148/149/158/159/169/259/269)
local function check_seq2(paiTable)
	table.sort(paiTable,function(a,b) return a < b end)
	print("------paiTable---------",paiTable)
    local needCSCount = 0
    local nSeqT = -1
    local nCount = #paiTable
    if nCount == 1 then
        nSeqT = 11
        needCSCount = needCSCount + 2
    elseif nCount == 2 then
        local nOffSet = paiTable[2] - paiTable[1]
        if nOffSet == 3 then
            nSeqT = 21
            needCSCount = needCSCount + 1
        elseif nOffSet == 6 then
            nSeqT = 22
            needCSCount = needCSCount + 1
        elseif nOffSet > 3 or nOffSet > 6 then
            nSeqT = 23
            needCSCount = needCSCount + 1
        else
        	nSeqT = 10
        end
    elseif nCount == 3 then
        local nOffSet1 = paiTable[3] - paiTable[2]
        local nOffSet2 = paiTable[2] - paiTable[1]
        if nOffSet1 == 3 and nOffSet2 == 3 then
            nSeqT = 31
        elseif nOffSet1 >= 3 and nOffSet2 >= 3 then
            nSeqT = 32
        else
        	nSeqT = 10
        end
    end
    return nSeqT, needCSCount
end
--check 风牌 5:连续5个东南西北中发白  7:连续7个东南西北中发白
function _check_fengByN(paiTable,num,caishen)
    local needCSCount = 0
    local uniqueT = munique(paiTable,caishen,true)
    local pCount = #uniqueT
    if pCount < num then
        needCSCount = num - pCount
        return false, needCSCount
    end
    return true, needCSCount
end

function check_13YaoGroup(t, laiziList, g_LaiZi)
    local bIsHu = false
    local huType = -1
    local nCSCount = #laiziList
    --分离调通玩风
    local tTiao, tTong, tWan, tFeng = seprateHuase(t)
    -- print("================条条条条条============000====")
    -- print_table(tTiao)
    -- print("================条条条条条============111====")
    -- print("================筒筒筒筒筒============000====")
    -- print_table(tTong)
    -- print("================筒筒筒筒筒============111====")
    -- print("================万万万万万============000====")
    -- print_table(tWan)
    -- print("================万万万万万============111====")
    -- print("================风风风风风============000====")
    -- print_table(tFeng)
    -- print("================风风风风风============111====")
    if #tTiao > 3 or #tTong > 3 or #tWan > 3 then
        --条,筒,万超过3张, 或风牌小于5张 则返回
        return bIsHu,huType
    end
    --需要的财神数
    local needCSCount = 0
    --条 判断
    print("-------tTiao------",tTiao)
    print("-------tTong------",tTong)
    print("-------tWan------",tWan)
    local nNType1, ncscount = check_seq2(tTiao)
    -- print("nNType1="..tostring(nNType1))
    needCSCount = needCSCount + ncscount
    --筒 判断
    local nNType2, ncscount = check_seq2(tTong)
    -- print("nNType2="..tostring(nNType2))
    needCSCount = needCSCount + ncscount
    --万 判断
    local nNType3, ncscount = check_seq2(tWan)
    -- print("nNType3="..tostring(nNType3))
    needCSCount = needCSCount + ncscount
    -- print("needCSCount="..tostring(needCSCount))
    --风 判断
    local uniqueT = munique(tFeng,g_LaiZi,true)
    -- print("================风风风风风============222====")
     print(uniqueT)
    -- print("================风风风风风============333====")
    --5:连续5个东南西北中发白  7:连续7个东南西北中发白
    if #uniqueT ~= #tFeng then 
        print("风牌有重复! 退出")
        --如果风牌有重复则返回
        huType = -1
    else
        --7风
        local bFengIsHu, FenghuType = _check_FengByCount(nNType1, nNType2, nNType3, uniqueT, 7, needCSCount, nCSCount, g_LaiZi)
        -- print("huType="..tostring(huType))
        bIsHu = bFengIsHu
        if bFengIsHu == true then
            if FenghuType == 1 then
                print("真七风不靠胡牌！")
                huType = PDEFINE.HUPAI_TYPE.ENUM_MJHU_ZQFBK
            else
                print("七风胡牌！")
                huType = PDEFINE.HUPAI_TYPE.ENUM_MJHU_QF
            end
        else 
            --5风 13妖
            bFengIsHu, FenghuType = _check_FengByCount(nNType1, nNType2, nNType3, uniqueT, 5, needCSCount, nCSCount, g_LaiZi)
            bIsHu = bFengIsHu
            print("----bFengIsHu-----",bFengIsHu)
            print("----FenghuType-----",FenghuType)
            if FenghuType == 1 then
                print("真十三不靠胡牌！")
                huType = PDEFINE.HUPAI_TYPE.ENUM_MJHU_ZSSBK
            else
                print("十三不靠胡牌！")
                huType = PDEFINE.HUPAI_TYPE.ENUM_MJHU_SSBK
            end
        end
    end
    return bIsHu, huType
end

function _check_13GroupTypeReal(nNType1, nNType2, nNType3)
    if nNType1 == 31 and nNType2 == 31 and nNType3 == 31 then
        return true
    elseif nNType1 == 31 and nNType2 == 31 and nNType3 == -1 then
        return true
    elseif nNType1 == 31 and nNType2 == -1 and nNType3 == 31 then
        return true
    elseif nNType1 == -1 and nNType2 == 31 and nNType3 == 31 then
        return true
    end
    return false
end

function _check_13GroupType(nNType1, nNType2, nNType3)
    if nNType1 >= 31 and nNType2 >= 31 and nNType3 >= 31 then
        return true
    elseif nNType1 >= 31 and nNType2 >= 31 and nNType3 == -1 then
        return true
    elseif nNType1 >= 31 and nNType2 == -1 and nNType3 >= 31 then
        return true
    elseif nNType1 == -1 and nNType2 >= 31 and nNType3 >= 31 then
        return true
    end
    if nNType1 >= 11 and nNType2 >= 11 and nNType3 >= 11 then
        return true
    elseif nNType1 >= 11 and nNType2 >= 11 and nNType3 == -1 then
        return true
    elseif nNType1 >= 11 and nNType2 == -1 and nNType3 >= 11 then
        return true
    elseif nNType1 == -1 and nNType2 >= 11 and nNType3 >= 11 then
        return true
    end
    return false
end


--根据风牌数量判断
--t:不重复的风牌表
--Num:要判断的几风牌
--nNeedCSCount: 需要的财神数量
--nTotalCSCount: 总财神数量
--bCaiShenTFeng: 财神能不能替风牌
--ret: bIsHu 是否胡牌
--ret: huType: 1:真风 2:伪风
function _check_FengByCount(nNType1, nNType2, nNType3, uniqueT, Num, nNeedCSCount, nTotalCSCount,CaiShen)
    print("_check_FengByN=======检测真风="..tostring(Num).."======================start=============")
    local bIsHu = false
    local huType = -1
    local bCanCaiShenTFeng = true --财神代替风牌
    if Num == 7 then
        --7风判断时财神不能代替风牌
        bCanCaiShenTFeng = false
    end
    local bAllFeng, ncscount = _check_fengByN(uniqueT, Num)
    print("bAllFeng="..tostring(bAllFeng).." ncscount="..tostring(ncscount))
    print("nTotalCSCount="..tostring(nTotalCSCount))
    nNeedCSCount = nNeedCSCount + ncscount
    print("nNeedCSCount="..tostring(nNeedCSCount))
    if _check_13GroupTypeReal(nNType1,nNType2,nNType3) == true then 
        print("_check_FengByN 000")
        if bAllFeng == true then
            print("_check_FengByN 001")
            --真风
            huType = 1
            bIsHu = true
        else
            print("_check_FengByN 002")
            --如果有财神并且需要的财神数必须小于拥有的财神数
            if nTotalCSCount > 0 then
                print("_check_FengByN 003")
                if CaiShen == 47 then
                    print("_check_FengByN 004")
                    if nNeedCSCount <= nTotalCSCount and ncscount == 1 then
                        print("_check_FengByN 005")
                        --真风
                        huType = 1
                        bIsHu = true
                    end
                else
                    print("_check_FengByN 006")
                    if nNeedCSCount <= nTotalCSCount then
                        print("_check_FengByN 007")
                        --真风
                        huType = 1
                        bIsHu = true
                    end
                end
            end
        end
    elseif _check_13GroupType(nNType1,nNType2,nNType3) == true then
        print("_check_FengByN 010".." nNType1="..tostring(nNType1).." nNType2="..tostring(nNType2).." nNType3="..tostring(nNType3))
        if bAllFeng == true then
            print("_check_FengByN 011")
            huType = 1 --真风
            if (nNType1 == 23 or nNType2 == 23 or nNType3 == 23) or 
                (nNType1 == 32 or nNType2 == 32 or nNType3 == 32) then
                --有一组牌是 伪风 就是伪风
                print("_check_FengByN 011--0")
                huType = 2 --伪风
            end
            bIsHu = true
        else
            print("_check_FengByN 012")
            --如果有财神并且需要的财神数必须小于拥有的财神数
            if nTotalCSCount > 0 then
                print("_check_FengByN 013")
                if CaiShen == 47 then
                    print("_check_FengByN 014")
                    if bCanCaiShenTFeng == false then --7风判断时财神不能代替风牌
                        if nTotalCSCount >= 1 and ncscount == 1 then
                            print("_check_FengByN 014--1")
                            huType = 1 --真风
                            if (nNType1 == 23 or nNType2 == 23 or nNType3 == 23) or 
                                (nNType1 == 32 or nNType2 == 32 or nNType3 == 32) then
                                --有一组牌是 伪风 就是伪风
                                print("_check_FengByN 015--1")
                                huType = 2 --伪风
                            end
                            bIsHu = true
                        end
                    else    
                        if nNeedCSCount <= nTotalCSCount and ncscount == 1 then
                            print("_check_FengByN 015")
                            huType = 1 --真风
                            if (nNType1 == 23 or nNType2 == 23 or nNType3 == 23) or 
                                (nNType1 == 32 or nNType2 == 32 or nNType3 == 32) then
                                --有一组牌是 伪风 就是伪风
                                print("_check_FengByN 015--1")
                                huType = 2 --伪风
                            end
                            bIsHu = true
                        end
                    end
                else
                    print("_check_FengByN 016 nNeedCSCount="..tostring(nNeedCSCount).." nTotalCSCount="..tostring(nTotalCSCount))
                    if nNeedCSCount <= nTotalCSCount then
                        print("_check_FengByN 017")
                        huType = 1 --真风
                        if (nNType1 == 23 or nNType2 == 23 or nNType3 == 23) or 
                            (nNType1 == 32 or nNType2 == 32 or nNType3 == 32) then
                            --有一组牌是 伪风 就是伪风
                            print("_check_FengByN 017--0")
                            huType = 2 --伪风
                        end
                        bIsHu = true
                    end
                end
            end
        end
    end
    print("_check_FengByN=======检测真风="..tostring(Num).."======================end=============")
    return bIsHu, huType
end
--乱风(10倍):全部是风牌胡牌。不需要组成基本胡牌牌型。
function check_LuanFeng(t)
    for _,v in ipairs(t) do
        if v < 41 then
            return false
        end
    end
    return true
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


local function check_Hu_SP(tmp_cards_T,caishen)
	local htype = 0
    local bIsHu = false
    --分离癞子
    local srcT = table.copy(tmp_cards_T)
    local t, laiziList = seprateLaizi(srcT,caishen)
    --判断财神胡
    local caishenCount = #laiziList --财神个数
    if caishenCount == 4 then --四财神(2倍):有四张财神时，不需要组成基本胡牌牌型
        htype = PDEFINE.HUPAI_TYPE.ENUM_MJHU_PH
        bIsHu = true
    end
    --7对子判断
    if check_7DuiZi(t, caishenCount) == true then
    	htype = PDEFINE.HUPAI_TYPE.ENUM_MJHU_QDZ
        bIsHu = true
    end
    return bIsHu, htype
end

function hztool.getHType(user,hcard)
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
            ahtype = PDEFINE.HUPAI_TYPE.ENUM_MJHU_PPH
        else
            ahtype = PDEFINE.HUPAI_TYPE.ENUM_MJHU_PH
        end
    else
        ret,ahtype = check_Hu_SP(tmp_cards,35)
    end
	print("--sp---ret------",ret)
	print("--sp---ahtype------",ahtype)
    return ret,ahtype
end

function hztool.checkIsHu(tmp_cards, hcard)
    local cutInfo = {}
    local huMap = {}
    check_Hu(tmp_cards, false, hcard, huMap, cutInfo,35)
    print("---66666--huMap------",#huMap)
    if #huMap == 1 then
        return hcard
    else
        if check_Hu_SP(tmp_cards,35) then
            return hcard
        end
    end
    return 0
end
function hztool.getCoin(htype,difen,pcsC,TgangC,htp)
	print("-----222222---",htype)
	local db = 0
	local tmp_coin = 0
	for _,gtype in pairs(htype) do
		db = PDEFINE.COIN_TYPE[gtype]
		tmp_coin = tmp_coin + db
	end
	local taddcoin = 0
	if TgangC then
		if htp == 2 then
			taddcoin = taddcoin + (TgangC-1)*2
		end
	end
	if pcsC > 0 then
		taddcoin = taddcoin + (pcsC-1)*2
	end
	return tmp_coin + taddcoin
end

function  random_uid()
	local random_value = random.GetRange(0, 9, 7)
	local uid = ""
	for i,key in pairs(random_value) do
		if i == 1 and key == 0 then
			key = 3
		end
		uid = uid .. key
	end
	return tonumber(uid)
end

return hztool