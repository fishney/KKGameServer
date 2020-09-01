local sharedata = require "sharedata"

local redtool = {}

local CardData=
{
    0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D, --黑桃 A 1 - K(13)
    0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,
    0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,
    0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,
}

--[[
local CardColor =
{
    Spade = 0,          --黑桃
    Heart = 16,         --红桃
    Plum  = 32,         --梅花
    Block = 48,         --方块
}

local CardValue =
{
    card_A = 1,
    card_2 = 2,
    card_3 = 3,
    card_4 = 4,
    card_5 = 5,
    card_6 = 6,
    card_7 = 7,
    card_8 = 8,
    card_9 = 9,
    card_10 = 10,
    card_J = 11,
    card_Q = 12,
    card_K = 13,
}
]]

local CardType =
{
    UNDEFINE=0,        --单张
    DUI_ZI  =1,        --对子
    SHUN_ZI =2,        --顺子
    TONG_HUA=3,        --金花
    TONG_HUA_SHUN = 4, --顺金
    BAO_ZI = 5,        --豹子
}

function redtool.RandCardList(excludeCards, excludeCards2)
    math.randomseed(os.time())
    --要过滤掉指定牌
    local cards = table.copy(CardData);
    if nil ~= excludeCards then
        for i =#cards, 1, -1 do
            for _, card in pairs(excludeCards) do
                local bpoint = false
                if card.value == (cards[i] & 0x0F) and card.color== (cards[i] & 0xF0) then
                    bpoint = true
                    break;
                end
                if bpoint then
                    table.remove(cards, i)
                    break
                end
            end
        end
    end

    if nil ~= excludeCards2 then
        for i =#cards, 1, -1 do
            for _, card in pairs(excludeCards2) do
                local bpoint = false
                if card.value == (cards[i] & 0x0F) and card.color== (cards[i] & 0xF0) then
                    bpoint = true
                    break;
                end
                if bpoint then
                    table.remove(cards, i)
                    break
                end
            end
        end
    end

    for i = 1,#cards do
        local ranOne = math.random(1,#cards+1-i)
        cards[ranOne], cards[#cards+1-i] = cards[#cards+1-i],cards[ranOne]
    end

    local cardBuffer = table.copy(cards);
    return cardBuffer;
end

--从牌型库里过滤下再返回
function redtool.getExcludeLibsCards(type, excludeCards)
    type = tostring(type)
    local cards = sharedata.deepcopy("redblackcardlib", type)

    for i =#cards, 1, -1 do
        for _, card in pairs(excludeCards) do
            local bpoint = false
            for _, item in pairs(cards[i]) do
                if card.value == (item & 0x0F) and card.color== (item & 0xF0) then
                    bpoint = true
                    break;
                end
            end
            if bpoint then
                table.remove(cards, i)
                break
            end
        end
    end
    return cards
end

--从对子里过滤9对以下
function redtool.getExcludeDuiziCards(type, libs)
    if type ~= CardType.UNDEFINE then
        return libs
    end
    local cards = table.copy(libs)
    for i =#cards, 1, -1 do
        local bpoint = false
        for _, item in pairs(cards[i]) do
            local t = (item & 0x0F)
            if t>1 and t < 9 then
                bpoint = true
                break;
            end
        end
        if bpoint then
            table.remove(cards, i)
            break
        end
    end
    return cards
end

--获取非幸运1击牌型
function redtool.getNoLuckCards(excludeCards)
    local cardtypeLib = {CardType.DUI_ZI, CardType.UNDEFINE}
    local randomType = cardtypeLib[math.random(#cardtypeLib)]
    randomType = tostring(randomType)
    local libs = sharedata.deepcopy("redblackcardlib", randomType)
    
    if randomType == CardType.DUI_ZI then
        if nil ~= excludeCards then
            for i =#libs, 1, -1 do
                for _, card in pairs(excludeCards) do
                    local bpoint = false
                    for _, item in pairs(libs[i]) do
                        if card.value == (item & 0x0F) and card.color== (item & 0xF0) then
                            bpoint = true
                            break;
                        end
                    end
                    if bpoint then
                        table.remove(libs, i)
                        break
                    end
                end
            end
        end

        for i=#libs, 1, -1 do
            local cards = {}
            for _, item in pairs(libs[i]) do
                table.insert(cards, {value = item & 0x0F; color = item & 0xF0;})
            end
            redtool.sortByCardsValue(cards)
            if cards[2].value < 9 then
                return cards
            end
        end
    else
        if nil ~= excludeCards then
            for i =#libs, 1, -1 do
                for _, card in pairs(excludeCards) do
                    local bpoint = false
                    for _, item in pairs(libs[i]) do
                        if card.value == (item & 0x0F) and card.color== (item & 0xF0) then
                            bpoint = true
                            break;
                        end
                    end
                    if bpoint then
                        table.remove(libs, i)
                        break
                    end
                end
            end
        end

        local random = math.random(1, #libs)
        local cards = libs[random]
        local cardstable = {}
        for _, item in pairs(cards) do
            table.insert(cardstable, {value = item & 0x0F; color = item & 0xF0;})
        end
        return cardstable
    end
end

--获取幸运1击牌型
function redtool.getLuckCards()
    local cardtypeLib = {CardType.DUI_ZI, CardType.SHUN_ZI, CardType.TONG_HUA, CardType.TONG_HUA_SHUN, CardType.BAO_ZI}
    local randomType = cardtypeLib[math.random(#cardtypeLib)]

    randomType = tostring(randomType)
    local libs = sharedata.deepcopy("redblackcardlib", randomType)

    if randomType == CardType.DUI_ZI then
        for i=#libs, 1, -1 do
            local cards = {}
            for _, item in pairs(libs[i]) do
                table.insert(cards, {value = item & 0x0F; color = item & 0xF0;})
            end
            redtool.sortByCardsValue(cards)
            if cards[2].value >= 9 then
                return cards
            end
        end
    else
        local random = math.random(1, #libs)
        local cards = libs[random]
        local cardstable = {}
        for _, item in pairs(cards) do
            table.insert(cardstable, {value = item & 0x0F; color = item & 0xF0;})
        end
        return cardstable
    end
end

--获取指定牌型的牌
function redtool.getFixedCards(type, excludeCards, must9dui)
    if type > 0 then
        type = tostring(type)
        local libs = sharedata.deepcopy("redblackcardlib", type)
        if nil ~= libs then
            if nil ~= excludeCards then
                --先过滤第一手牌已出的
                libs = redtool.getExcludeLibsCards(type, excludeCards)
            end
            if nil~=must9dui and must9dui>=0 then
                libs = redtool.getExcludeDuiziCards(type, libs)
            end
            local random = math.random(1, #libs)
            local cards = libs[random]
            local cardstable = {}
            for _, item in pairs(cards) do
                table.insert(cardstable, {value = item & 0x0F; color = item & 0xF0;})
            end
            return cardstable
        end
    end
    return nil
end

--展示用 测试用
function redtool.getCardNamebyCard(Card)
    local string=""
    if Card.color ==0 then
        string=string.."黑桃"
    elseif Card.color ==16 then
        string=string.."红桃"
    elseif Card.color ==32 then
        string=string.."梅花"
    elseif Card.color ==48 then
        string=string.."方块"
    else
        string="ERROR"
    end

    if Card.value==1 then
        string=string.."A"
    elseif Card.value==13 then
        string=string.."K"
    elseif Card.value==12 then
        string=string.."Q"
    elseif Card.value==11 then
        string=string.."J"
    else
        string=string..Card.value
    end
    return string
end

--获取牌
function redtool.getCardNamebyCards(Cards)
    local string=""
    for i = 1,#Cards do
        string=string..redtool.getCardNamebyCard(Cards[i]) .." "
    end
    return string
end

--从小到大排列
local function compByCardsValue(a, b)
    if a.value < b.value then
        return true
    end

    if a.value > b.value then
        return false
    end

    return a.color > b.color --颜色值越大，越小

end

function redtool.sortByCardsValue(cards)
    table.sort(cards, compByCardsValue);
end

--》QKA
local function isQKA(cards)
    if cards[1].value == 1 and cards[2].value == 12 and cards[3].value == 13 then
        return true
    end
    return false
end

-- 豹子：三张牌值相同的牌型，由于是有序的，故只需判断第一张与第三张牌值是否相等即可
function redtool.isBaozi( cards)
    if cards[1].value==cards[3].value then
        return true
    end
    return false
end

--顺金：即满足同花又满足顺子的牌型
function redtool.isTongHuaShun(cards)
    local TagTongHua
    local TagShunZi
    TagTongHua = redtool.isTongHua(cards)
    TagShunZi  = redtool.isShunZi(cards)
    if TagTongHua and TagShunZi then --既满足同花也满足顺子的时候，就是同花顺，包含23A
        return true
    end
    return false
end

-- 同花：三张牌花色相同
function redtool.isTongHua (cards)
    if cards[1].color==cards[2].color and cards[1].color==cards[3].color then
        return true
    end
    return false
end

--顺子：三张牌牌值依次递增1，同时还包括A23特殊牌型
function redtool.isShunZi(cards)
    if isQKA(cards) then
        return true
    end

    if cards[3].value - cards[2].value == 1 and cards[2].value - cards[1].value == 1 then
        return true
    end
    return false
end

--对子：两张牌牌值相等，但第一张与第三张不能相等，否则就是豹子了
function redtool.isDuiZi(cards)
    if cards[1].value ~= cards[3].value then
        if cards[1].value == cards[2].value then
            return true
        end

        if cards[2].value == cards[3].value then
            return true
        end
    end
    return false
end

--是否是 9-A的对子
function redtool.is9ADui(cards, cardtype)
    if cardtype == CardType.DUI_ZI then
        if cards[2].value >= 9 or cards[2].value==1 then
            return true
        end
    end
    return false
end

--封装获取牌型函数
function redtool.getCardType(cards)
    redtool.sortByCardsValue(cards)
    if cards then
        --《豹子
        if true == redtool.isBaozi(cards) then
            return CardType.BAO_ZI
        end

        --《同花顺
        if true == redtool.isTongHuaShun(cards) then
            return CardType.TONG_HUA_SHUN
        end

        --《同花
        if true == redtool.isTongHua(cards) then
            return CardType.TONG_HUA;
        end

        --《顺子
        if true == redtool.isShunZi(cards) then
            return CardType.SHUN_ZI;
        end

        -- 《对子
        if true == redtool.isDuiZi(cards) then
            return CardType.DUI_ZI;
        end
    end

    return CardType.UNDEFINE --初始单牌
end

function redtool.getCardTypeNamebyType(CardType)
    if CardType==0 then
        return "散牌"
    end
    if CardType==1 then
        return "对子"
    end
    if CardType==2 then
        return "顺子"
    end
    if CardType==3 then
        return "金花"
    end
    if CardType==4 then
        return "顺金"
    end
    if CardType==5 then
        return "豹子"
    end
    return "异常牌型"
end

--牌型值 不一样的情况
local function CardTypeDifferent( my_Cards, next_Cards, my_Cards_Type, next_Cards_Type )

    return my_Cards_Type > next_Cards_Type
end

--牌里面A的个数
local function hasACount(cards)
    local count = 0
    for i=1, #cards do
        if cards[i].value == 1 then
            count = count + 1
        end
    end
    return count
end

--[[
同牌型的牌比较就要分别处理了：
豹子：比较单张牌牌值
同花顺：比较第三张牌，同时考虑 QKA 特殊顺子情况
同花：从第三张牌开始依次比较
顺子：比较第三张牌，同时考虑 QKA 特殊顺子情况
对牌：首先比较第二张，因为第二张一定是构成对子的那张牌。若相同则再比对（第一张+第三张）
]]
local function CardTypeSame( my_Cards, next_Cards, my_Cards_Type )
    --------------------------------------豹子-----------------------------
    local  win, lose  = true, false
    local  SubValueBaoZi
    if  my_Cards_Type == CardType.Bao_ZI then
        if my_Cards[1].value == 1 then --自己 豹子 AAA
            return win
        end
        if next_Cards[1].value == 1 then --对方 豹子 AAA， 自己输了
            return lose
        end
        print("--------------------------- 豹子 ---------------------")
        print("--------------------------- 豹子 ---------------------:",my_Cards)
        print("--------------------------- 豹子 ---------------------:",next_Cards)
        SubValueBaoZi = my_Cards[1].value - next_Cards[1].value
        print("--------------------------- SubValueBaoZi ---------------------:",SubValueBaoZi)
        if SubValueBaoZi > 0 then
            return win
        elseif SubValueBaoZi < 0 then
            return lose
        else
            return lose
        end
    end
    -------------------------------------顺金-----------------------------
    local  mycards_isqka
    local  nextcards_isqka
    local  SubValueSunZi
    if  my_Cards_Type == CardType.TONG_HUA_SHUN then

        mycards_isqka   = isQKA(my_Cards)
        nextcards_isqka = isQKA(next_Cards)
        --两个都是QKA
        if mycards_isqka  and nextcards_isqka then
            return my_Cards[1].color < next_Cards[1].color --比较A的花色 黑 红 梅 方
        end

        --有一个QKA
        if mycards_isqka  or nextcards_isqka then
            if mycards_isqka then
                return win
            end
            return lose
        end

        --都没有QKA
        if mycards_isqka  == false and nextcards_isqka == false then
            SubValueSunZi = my_Cards[3].value - next_Cards[3].value --牌值最大的牌
            if SubValueSunZi < 0 then
                return lose
            elseif SubValueSunZi > 0 then
                return win
            else
                --顺金 大牌相同的话，后续2张值肯定牌值相等
                return my_Cards[3].color < next_Cards[3].color --牌值最大的牌的花色

                --SubValueSunZi = my_Cards[2].value - next_Cards[2].value --牌值第2大的牌
                --if SubValueSunZi < 0 then
                --    return lose
                --elseif SubValueSunZi > 0 then
                --    return win
                --else
                --    SubValueSunZi = my_Cards[1].value - next_Cards[1].value --牌值最小的牌
                --    if SubValueSunZi < 0 then
                --        return lose
                --    elseif SubValueSunZi > 0 then
                --        return win
                --    else
                --        --顺金，如：红,黑桃567; 黑,红桃567
                --        return my_Cards[3].color < next_Cards[3].color --牌值最大的牌的花色
                --    end
                --end
            end
        end
    end

    --------------------------------------------同花----------------------------------
    if  my_Cards_Type == CardType.TONG_HUA then
        local my_counta   = hasACount(my_Cards)
        local next_counta = hasACount(next_Cards)

        if my_counta > next_counta then
            return win
        elseif my_counta < next_counta then
            return lose
        else
            if my_counta == 1 then --大家都有1张A
                if my_Cards[3].value - next_Cards[3].value > 0 then
                    return win
                elseif my_Cards[3].value - next_Cards[3].value < 0 then
                    return lose
                else
                    if my_Cards[2].value - next_Cards[2].value > 0 then
                        return win
                    elseif my_Cards[2].value - next_Cards[2].value < 0 then
                        return lose
                    else
                        return my_Cards[1].color < next_Cards[1].color
                    end
                end
            else --最多1张A， 大家都没有A
                if my_Cards[3].value - next_Cards[3].value > 0 then
                    return win
                end

                if my_Cards[3].value - next_Cards[3].value < 0 then
                    return lose
                end
                if my_Cards[2].value - next_Cards[2].value > 0 then
                    return win
                end

                if my_Cards[2].value - next_Cards[2].value < 0 then
                    return lose
                end
                if my_Cards[1].value - next_Cards[1].value > 0 then
                    return win
                end

                if my_Cards[1].value - next_Cards[1].value < 0 then
                    return lose
                end
                return my_Cards[3].color < next_Cards[3].color
            end

        end
        return lose
    end

    --------------------------------------------顺子----------------------------------
    local  mycards_isqka
    local  nextcards_isqka
    local  SubValueSunZi
    if  my_Cards_Type == CardType.SHUN_ZI then

        mycards_isqka   = isQKA(my_Cards)
        nextcards_isqka = isQKA(next_Cards)

        --两个都是QKA
        if mycards_isqka  and nextcards_isqka then
            return my_Cards[1].color < next_Cards[1].color --比较A的花色 黑 红 梅 方
        end

        --有一个有QKA
        if mycards_isqka  or nextcards_isqka then
            if mycards_isqka then
                return win
            else
                return lose
            end
        end

        --都没有QKA
        if mycards_isqka  == false and nextcards_isqka == false then
            SubValueSunZi = my_Cards[3].value - next_Cards[3].value
            if SubValueSunZi > 0 then
                return win
            elseif SubValueSunZi < 0 then
                return lose
            else
                --顺子 第大牌相同的值，后续2张值肯定一样
                return my_Cards[3].color < next_Cards[3].color --牌值最大的牌的花色
            end
        end
    end

    --------------------------------------------对子----------------------------------

    if  my_Cards_Type == CardType.DUI_ZI then
        --都是对A
        if my_Cards[2].value == 1 and next_Cards[2].value==1 then
            print("我的牌颜色：", my_Cards[2].color)
            if tonumber(my_Cards[2].color) == 0 or my_Cards[1].color == 0 then
                return win
            end

            print("对方的牌颜色：", next_Cards[2].color)
            if next_Cards[2].color == 0 or next_Cards[1].color == 0 then
                return lose
            end

            return my_Cards[1].color < next_Cards[1].color
        end
        --我对A
        if my_Cards[2].value == 1 and next_Cards[2].value~=1 then
            return win
        end
        --对方对A
        if my_Cards[2].value ~= 1 and next_Cards[2].value==1 then
            return lose
        end

        --第二张牌一定是组成对子的那张牌
        local SubValueDuiZi = my_Cards[2].value - next_Cards[2].value
        --第二张不等
        if SubValueDuiZi > 0 then
            return win
        end
        if SubValueDuiZi < 0 then
            return lose
        end
        --第二张相等(对子相等)
        if SubValueDuiZi == 0 then
            local result = (my_Cards[1].value + my_Cards[3].value ) - (next_Cards[1].value + next_Cards[3].value)
            if result > 0 then
                return win
            elseif result < 0 then
                return lose
            else
                --处理特殊牌型 比如： 红 对8 方片6  黑 对8 黑桃6; 找出除对子外的牌
                local mycards_last, nextcards_last = {}, {}
                if my_Cards[1].value == my_Cards[2].value then
                    mycards_last = my_Cards[3]
                else
                    mycards_last = my_Cards[1]
                end
                if next_Cards[1].value == next_Cards[2].value then
                    nextcards_last = next_Cards[3]
                else
                    nextcards_last = next_Cards[1]
                end
                return mycards_last.color < nextcards_last.color
            end
        end

    end

    --------------------------------------------单牌----------------------------------
    if  my_Cards_Type == CardType.UNDEFINE then

        local my_counta   = hasACount(my_Cards)
        local next_counta = hasACount(next_Cards)

        if my_counta == 1 and next_counta ~= 1 then
            return win
        end

        if my_counta ~= 1 and next_counta == 1 then
            return lose
        end

        if my_counta == 1 and next_counta == 1 then
            if my_Cards[3].value - next_Cards[3].value > 0 then
                return win
            end

            if my_Cards[3].value - next_Cards[3].value < 0 then
                return lose
            end
            if my_Cards[2].value - next_Cards[2].value > 0 then
                return win
            end
            if my_Cards[2].value - next_Cards[2].value < 0 then
                return lose
            end
            return my_Cards[1].color < next_Cards[1].color
        else
            if my_Cards[3].value - next_Cards[3].value > 0 then
                return win
            end

            if my_Cards[3].value - next_Cards[3].value < 0 then
                return lose
            end
            if my_Cards[2].value - next_Cards[2].value > 0 then
                return win
            end

            if my_Cards[2].value - next_Cards[2].value < 0 then
                return lose
            end
            if my_Cards[1].value - next_Cards[1].value > 0 then
                return win
            end

            if my_Cards[1].value - next_Cards[1].value < 0 then
                return lose
            end
            return my_Cards[3].color < next_Cards[3].value
        end
    end
end

--@比牌接口函数
--@ my_Cards, 本家牌,
--@ pre_Cards,下家牌,
--@ ret true/false
function redtool.isOvercomePrev(my_Cards, next_Cards)
    --获取各自牌形
    local my_Cards_Type   = redtool.getCardType(my_Cards)
    local next_Cards_Type = redtool.getCardType(next_Cards)
    local winorlose
    print("-----------------my_Cards_Type----------------------------", my_Cards_Type)
    print("-----------------next_Cards_Type----------------------------", next_Cards_Type)
    if  my_Cards_Type == next_Cards_Type then --牌形相同的情况下
        winorlose =  CardTypeSame(my_Cards, next_Cards, my_Cards_Type)
    end
    if my_Cards_Type ~= next_Cards_Type  then --牌形不同的情况下
        winorlose =  CardTypeDifferent(my_Cards, next_Cards,my_Cards_Type,next_Cards_Type)
    end
    return winorlose
end

return redtool