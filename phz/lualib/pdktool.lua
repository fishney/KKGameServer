--跑得快 斗地主公用tools
-- local pdktool.CardType =
-- {
--     ERROR_CARDS    = 0, --错误牌型
--     SINGLE_CARD    = 1, --单牌
--     DOUBLE_CARD    = 2, --对子
--     THREE_CARD     = 3, --3不带
--     THREE_ONE_CARD = 4, --3带1
--     THREE_TWO_CARD = 5, --3带2
--     BOMB_TWO_CARD  = 6, --四个带2张单牌
--     BOMB_FOUR_CARD = 7, --四个带2对
--     CONNECT_CARD   = 8, --连牌
--     COMPANY_CARD   = 9, --连队
--     AIRCRAFT_CARD  = 10, --飞机不带
--     AIRCRAFT_WING  = 11, --飞机带单牌或对子
--     BOMB_CARD      = 12, --炸弹
--     KINGBOMB_CARD  = 13, --王炸
-- }
pdktool = {}
pdktool.CardType =
{
    ERROR_CARDS    = 0, --错误牌型
    SINGLE_CARD    = 1, --单牌
    DOUBLE_CARD    = 2, --对子
    THREE_CARD     = 3, --3不带
    THREE_ONE_CARD = 4, --3带1
    THREE_TWO_CARD = 5, --3带2
    BOMB_ONE_CARD  = 6, --四个带1张单牌
    BOMB_TWO_CARD = 7, --四个带2张单牌
    BOMB_THREE_CARD = 8, --四个带3张单牌
    CONNECT_CARD   = 9, --连牌
    COMPANY_CARD   = 10, --连队
    AIRCRAFT_WING  = 11, --飞机带单牌或对子
    BOMB_CARD      = 12, --炸弹
    KINGBOMB_CARD  = 13, --王炸
}

--预留16，17表示 大小王 (斗地主用)
--扑克数据 48张(除去大王，小王，红桃2，梅花2，方片2，黑桃A，每人16张)
local CardData48=
{
    0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0F, --黑 3 - 2(15)
    0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E, --红
    0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,0x2E, --梅
    0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x3E, --方
}

--扑克数据 45张(除掉大小王，红桃2,梅花2,方块2, 红桃A,梅花A,方块A, 方块K,每人15张)
local CardData45=
{
    0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x1E,0x0F, --黑 3 - 2(15)
    0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D, --红
    0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D, --梅
    0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,      --方
}



function pdktool.stuctCards(cards)
    local outCardsTmp = {}
    for _, value in pairs(cards) do
        local card = {}
        card.value = getCardValue(value)
        card.color = getCardColor(value)
        table.insert(outCardsTmp,card)
    end
    return outCardsTmp
end

function pdktool.stuctCard(card)
    local card = {}
    card.value = getCardValue(value)
    card.color = getCardColor(value)
    return card
end

-- 洗牌
function pdktool.RandCardList(cardCount)
    local card
    math.randomseed(os.time())

    if cardCount == 45 then
        for i = 1,#CardData45 do
            local ranOne = math.random(1,#CardData45+1-i)
            CardData45[ranOne], CardData45[#CardData45+1-i] = CardData45[#CardData45+1-i],CardData45[ranOne]
        end
        card = CardData45
    else
        for i = 1,#CardData48 do
            local ranOne = math.random(1,#CardData48+1-i)
            CardData48[ranOne], CardData48[#CardData48+1-i] = CardData48[#CardData48+1-i],CardData48[ranOne]
        end

        card = CardData48
    end
    return card
end

-- 测试所有的牌是否都是扑克牌
function pdktool.isCards(cards)
    for _,c in pairs(cards) do
        if c.value > 15 or c.value < 3 then
            return false
        end

        if c.color ~= 0 and c.color ~= 16 and c.color ~= 32 and c.color ~= 48 then
            return false
        end
    end
    return true
end

--获得牌值对应的table
function pdktool.getCardsTabValue(cards)
    local tmp = {}
    for k, v in pairs(cards) do
        if type(v) ~= "table" then
            tmp[k] = v.value
        else
            tmp[k] = pdktool.getCardsTabValue(v)
        end
    end
    return tmp
end

-- 单张翻译函数
function pdktool.getCardNamebyCard(Card)
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

    if Card.value == 13 then
        string = string.."K"
    elseif Card.value == 12 then
        string = string.."Q"
    elseif Card.value == 11 then
        string = string.."J"
    elseif Card.value == 14 then
        string = string .. "A"
    elseif Card.value == 15 then
        string = string .. "2"
    else
        string=string..Card.value
    end
    return string
end

-- 多张翻译函数
function pdktool.getCardNamebyCards(Cards)
    local string=""
    -- for _, item in pairs(Cards) do
    --     print(item)
    -- end

    for i = 1,#Cards do
        string=string..pdktool.getCardNamebyCard(Cards[i]) .." "
    end
    return string
end

--大的排在前面
function compByCardsValue(a, b)

    if  b.value < a.value then
        return true
    end

    if a.value < b.value then
        return false
    end

    return a.color < b.color
end

--排序， 大的排前面
function pdktool.sortByCardsValue(cards)
    table.sort(cards, compByCardsValue);
end

--大的排在前面
function compByCards(a, b)

    if getCardValue(a) > getCardValue(b) then
        return true
    elseif getCardValue(a) < getCardValue(b) then
        return false
    else
        return getCardColor(a) < getCardColor(b)
    end
end

--排序， 大的排前面 cards
function pdktool.sortByCards(cards)
    table.sort(cards, compByCards);
end

--是否单牌(要求先判断过 isCards)
function pdktool.is_single(cards)
    if 1 == #cards then
        return true
    end
    return false
end

--是否是对子(要求先判断过 isCards)
function pdktool.is_double(cards)
    if #cards == 2 and cards[1].value == cards[2].value then
        return true
    end
    return false
end

--3不带 只判断3个牌相等(要求先判断过 isCards)
function pdktool.is_three(cards)
    if 3 ~= #cards then
        return false
    end

    if cards[1].value == cards[2].value and cards[1].value == cards[3].value then
        return true
    end

    return false
end

--3带1 先对数字排序 将带的牌移除判断剩下的三个牌是不是 3不带(要求先判断过 isCards)
function pdktool.is_three_one(cards)
    if 4 ~= #cards then
        return false
    end
    pdktool.sortByCardsValue(cards)
    for _,card in pairs(cards) do
    end
    if cards[1].value == cards[2].value and cards[2].value == cards[3].value then
        if cards[4].value ~= cards[1].value then
            return true
        end
    end

    if cards[2].value == cards[3].value and cards[3].value == cards[4].value then
        if cards[1].value ~= cards[2].value then
            return true
        end
    end

    return false
end

--3带2(要求先判断过 isCards)
function pdktool.is_three_two(cards)
    if 5 ~= #cards then
        return false
    end
    pdktool.sortByCardsValue(cards)
    if cards[1].value == cards[2].value and cards[2].value == cards[3].value then
        if cards[4].value ~= cards[1].value and cards[5].value ~= cards[1].value then
            return true
        end
    end

    if cards[2].value == cards[3].value and cards[3].value == cards[4].value then
        if cards[1].value ~= cards[2].value and cards[5].value ~= cards[1].value then
            return true
        end
    end

    if cards[3].value == cards[4].value and cards[4].value == cards[5].value then
        if cards[1].value ~= cards[3].value and cards[2].value ~= cards[3].value then
            return true
        end
    end

    return false
end

--炸弹(要求先判断过 isCards)
function pdktool.is_bomb(cards)
    if 4 ~= #cards then
        return false
    end

    if cards[1].value == cards[2].value and cards[2].value == cards[3].value and cards[3].value == cards[4].value then
        return true
    end

    return false
end

--王炸(要求先判断过 isCards) 预留暂时用不上
function pdktool.is_king_bomb(cards)
    if 2 ~= #cards then
        return false
    end
    pdktool.sortByCardsValue(cards)
    if cards[1].value == 17 and cards[2].value == 16 then
        return true
    end
    return false
end

--顺子(要求先判断过 isCards)
function pdktool.is_shunzi(cards)
    if 5 > #cards then
        return false
    end

    pdktool.sortByCardsValue(cards) --大的排在前面
    if cards[1].value > 14 then --2 不能在顺子中
        return false
    end

    for i = 1, (#cards -1) do
        if cards[i].value ~= cards[i+1].value + 1 then
            return false
        end
    end
    return true
end

--连对(要求先判断过 isCards) 33445566
function pdktool.is_company(cards)
    if 4 > #cards or (#cards%2) == 1 then
        return false
    end
    pdktool.sortByCardsValue(cards) --66554433
    local len = #cards
    for i =1 , (len -1 ) do
        if (i % 2) == 1 then
            if cards[i].value ~= cards[i+1].value then  -- 1和2 3和4 5和6 7和8 相等
                return false
            end
        else
            if cards[i].value ~= cards[i+1].value + 1 then -- 2和3 4和5 6和7 相差1
                return false
            end
        end
    end
    return true
end

-- 飞机不带 (要求先判断过 isCards)
-- 遍历到三个一组中的第一个的时候判断这组的值是否都相等
-- 遍历到三个一组中的最后一个的时候判断和下一组的数值是不是差一
function pdktool.is_aircraft(cards)
    if 6 > #cards  then
        return false
    end

    pdktool.sortByCardsValue(cards)
    local len = #cards
    for i = 1, (len - 1) do
        if (i % 3) == 1 then
            if cards[i].value ~= cards[i+1].value or cards[i+1].value ~= cards[i+2].value then
                return false
            end
        elseif (i % 3) == 0 then
            if cards[i].value ~= (cards[i+1].value + 1) then
                return false
            end
        end
    end
    return true
end

--4带2 (要求先判断过 isCards)
function pdktool.is_bomb_two(cards)
    if #cards ~= 6  then
        return false
    end

    pdktool.sortByCardsValue(cards)

    local tmpTable1 = {}  --存放炸弹牌
    local tmpTable2 = {}  --存放炸弹带的牌
    local tmppos = 0
    -- 先从牌中抽出炸弹不带的牌
    for pos = 1, (#cards - 3)  do
        if cards[pos].value == cards[pos + 1].value and cards[pos].value == cards[pos + 2].value and cards[pos + 2].value  == cards[pos + 3].value then
            table.insert(tmpTable1, cards[pos])
            table.insert(tmpTable1, cards[pos + 1])
            table.insert(tmpTable1, cards[pos + 2])
            table.insert(tmpTable1, cards[pos + 3])
            tmppos = pos
        end
    end
    if tmppos == 0 then
        return false
    end
    -- 再得到带的牌
    for k,v in pairs(cards) do
        if v.value ~= cards[tmppos].value then
            table.insert(tmpTable2, v)
        end
    end
    if pdktool.is_bomb(tmpTable1) then
        if 2 == #tmpTable2 then
            return true
        elseif 4 == #tmpTable2 then
            --table.sort(tmpTable2)
            pdktool.sortByCardsValue(tmpTable2)
            if tmpTable2[1].value == tmpTable2[2].value and tmpTable2[3].value == tmpTable2[4].value then
                return true
            end
        end
    end

    return false
end

--4带1 (要求先判断过 isCards)
function pdktool.is_bomb_one(cards)
    if #cards ~= 5 then
        return false
    end

    pdktool.sortByCardsValue(cards)

    local tmpTable1 = {}  --存放炸弹牌
    local tmpTable2 = {}  --存放炸弹带的牌
    local tmppos = 0
    -- 先从牌中抽出炸弹不带的牌
    for pos = 1, (#cards - 3)  do
        if cards[pos].value == cards[pos + 1].value and cards[pos].value == cards[pos + 2].value and cards[pos + 2].value  == cards[pos + 3].value then
            table.insert(tmpTable1, cards[pos])
            table.insert(tmpTable1, cards[pos + 1])
            table.insert(tmpTable1, cards[pos + 2])
            table.insert(tmpTable1, cards[pos + 3])
            tmppos = pos
        end
    end
    if tmppos == 0 then
        return false
    end
    -- 再得到带的牌
    for k,v in pairs(cards) do
        if v.value ~= cards[tmppos].value then
            table.insert(tmpTable2, v)
        end
    end
    if pdktool.is_bomb(tmpTable1) then
        if 1 == #tmpTable2 then
            return true
        end
    end

    return false
end


--4带3 (要求先判断过 isCards)
function pdktool.is_bomb_three(cards)
    if #cards ~= 7 then
        return false
    end

    pdktool.sortByCardsValue(cards)

    local tmpTable1 = {}  --存放炸弹牌
    local tmpTable2 = {}  --存放炸弹带的牌
    local tmppos = 0
    -- 先从牌中抽出炸弹不带的牌
    for pos = 1, (#cards - 3)  do
        if cards[pos].value == cards[pos + 1].value and cards[pos].value == cards[pos + 2].value and cards[pos + 2].value  == cards[pos + 3].value then
            table.insert(tmpTable1, cards[pos])
            table.insert(tmpTable1, cards[pos + 1])
            table.insert(tmpTable1, cards[pos + 2])
            table.insert(tmpTable1, cards[pos + 3])
            tmppos = pos
        end
    end
    if tmppos == 0 then
        return false
    end
    -- 再得到带的牌
    for k,v in pairs(cards) do
        if v.value ~= cards[tmppos].value then
            table.insert(tmpTable2, v)
        end
    end
    if pdktool.is_bomb(tmpTable1) then
        if 3 == #tmpTable2 then
            return true
        end
    end

    return false
end

-- 飞机带翅膀(要求先判断过 isCards) 如： 444555+79 或 333444555+7799JJ
function pdktool.is_aircraft_wing(cards)
    if 6 > #cards  then
        return false
    end
    -- 先判断有没有炸弹拆成三带一的情况 如果有那么将其中一个替换没有的数（如 19）
    pdktool.sortByCardsValue(cards)
    local tmp = 0 --记录有几个炸弹 防止有多个炸拆三带一
    for k = 1, (#cards - 4) do
        if cards[k].value == cards[k + 1].value and cards[k + 1].value == cards[k + 2].value and cards[k + 2].value == cards[k + 3].value then
            cards[k + 3].value = 19 + tmp
            tmp = tmp + 1
        end
    end

    local aircraftCount = math.floor(#cards / 4)
    pdktool.sortByCardsValue(cards)
    local tmpTable1 = {} --存放飞机的牌
    local tmpTable2 = {}  --存放飞机带的牌
    -- 先从牌中抽出飞机不带
    for pos = 1, #cards - 2 do
        if cards[pos].value == cards[pos + 1].value and cards[pos].value == cards[pos + 2].value then
            table.insert(tmpTable1, cards[pos])
            table.insert(tmpTable1, cards[pos + 1])
            table.insert(tmpTable1, cards[pos + 2])
            tmppos = pos
        end
    end
    if #tmpTable1 == 0 then
        return false
    end
    -- 再得到带的牌
    for k1, v1 in pairs(cards) do
        local count = 0
        for i = 1, aircraftCount do
            if v1.value == tmpTable1[i * 3].value then
                count = count + 1
            end
        end
        if  count == 0 then
            table.insert(tmpTable2, v1)
        end
    end

    if not pdktool.is_aircraft(tmpTable1) then
        return false
    end

    return true
end

--获得扑克牌的牌值
local function getValue(card)
    return card.value
end

-- 自定义复制table函数
local function copyTab(st)
    local tab = {}
    tab = table.copy(st)
    return tab
end

--将table里面的元素倒过来
function ascendingTable(table)
    local tmp = {}
    for i = #table, 1, -1 do
        tmp[#tmp + 1] = table[i]
    end
    return tmp
end

--两个table相减
function pdktool.subTable(tab1, tab2) --从tab1里去掉tab2
    local tmpcards = copyTab(tab1)
    for k,v in pairs(tab2) do
        for i = 1, #tmpcards do
            if tmpcards[i] ~= nil and tmpcards[i].value == tab2[k].value and tmpcards[i].color == tab2[k].color then
                table.remove(tmpcards, i)
            end
        end
    end
    return tmpcards
end

--获取类型
function pdktool.getType(postcards)
    local cards = table.copy(postcards)
    local len = #cards
    if len <= 5 and len > 0 then
        if pdktool.is_single(cards) then
            return pdktool.CardType.SINGLE_CARD
        elseif pdktool.is_double(cards) then
            return pdktool.CardType.DOUBLE_CARD
        elseif pdktool.is_bomb(cards) then
            return pdktool.CardType.BOMB_CARD
        elseif pdktool.is_king_bomb(cards) then
            return pdktool.CardType.KINGBOMB_CARD
        elseif pdktool.is_three(cards) then
            return pdktool.CardType.THREE_CARD
        elseif pdktool.is_three_one(cards) then
            return pdktool.CardType.THREE_ONE_CARD
        elseif pdktool.is_shunzi(cards) then
            return pdktool.CardType.CONNECT_CARD
        elseif pdktool.is_three_two(cards) then
            return pdktool.CardType.THREE_TWO_CARD
        elseif pdktool.is_company(cards) then
            return pdktool.CardType.COMPANY_CARD
        elseif pdktool.is_bomb_one(cards) then
            return pdktool.CardType.BOMB_TWO_CARD
        end
    elseif len < 20 and len > 5 then
        if pdktool.is_shunzi(cards) then
            return pdktool.CardType.CONNECT_CARD
        elseif pdktool.is_aircraft(cards) then
            return pdktool.CardType.AIRCRAFT_CARD
        elseif pdktool.is_company(cards) then
            return pdktool.CardType.COMPANY_CARD
        elseif pdktool.is_bomb_two(cards) then
            return pdktool.CardType.BOMB_TWO_CARD
        elseif pdktool.is_bomb_three(cards) then
            return pdktool.CardType.BOMB_THREE_CARD
        elseif pdktool.is_aircraft_wing(cards) then
            return pdktool.CardType.AIRCRAFT_WING
        end
    end
    return pdktool.CardType.ERROR_CARDS
end

-- 比牌 只要将带牌的牌型单独比较 其他的都可以直接比较

-- 普通比较 比较单牌 对子 炸弹 顺子 飞机不带 3不带 true 表示第一个大 false 表示第二个大
function pdktool.compare_normal(cards1, cards2)
    pdktool.sortByCardsValue(cards1)
    pdktool.sortByCardsValue(cards2)
    if cards1[1].value > cards2[1].value then
        return true
    end
    return false
end

--适合三带和飞机带,机中大牌的任何三张都会比小牌的大 true 表示第一个大 false 表示第二个大
function pdktool.compare_three_and_aircraft_take(cards1, cards2)
    pdktool.sortByCardsValue(cards1)
    pdktool.sortByCardsValue(cards2)

    local oneCards1, twoCards1, threeCards1, fourCards1, kingBomb1 = pdktool.getAllType(cards1)
    local oneCards2, twoCards2, threeCards2, fourCards2, kingBomb2 = pdktool.getAllType(cards2)

    if threeCards1[1][1].value > threeCards2[1][1].value then
        return true
    end
    return false
end

-- 四带的比较 true 表示第一个大 false 表示第二个大
function pdktool.compare_four_take(cards1, cards2)
    pdktool.sortByCardsValue(cards1)
    pdktool.sortByCardsValue(cards2)

    local oneCards1, twoCards1, threeCards1, fourCards1, kingBomb1 = pdktool.getAllType(cards1)
    local oneCards2, twoCards2, threeCards2, fourCards2, kingBomb2 = pdktool.getAllType(cards2)

    if fourCards1[1][1].value > fourCards2[1][1].value then
        return true
    end
    return false
end

-- playcards,prePlayCards  true表示card1大  false表示cards2大
function pdktool.compare_cards(cards1, cards2)
    -- print("牌型：－－－－－－－－"..pdktool.getType(playCardsValue))
    local CardType1 = pdktool.getType(cards1)
    local CardType2 = pdktool.getType(cards2)

    if #cards2 == 0 and CardType1 ~= 0 then
        return true
    end

    if CardType1 == 0 then
        return false
    end

    if CardType1 == pdktool.CardType.KINGBOMB_CARD then
        return true
    elseif CardType2 == KINGBOMB_CARD then
        return false
    end

    if CardType1 == CardType2 then
        local typecard = pdktool.getType(cards1)
        if CardType1 == pdktool.CardType.BOMB_TWO_CARD or CardType1 == pdktool.CardType.BOMB_FOUR_CARD then
            if pdktool.compare_four_take(cards1, cards2) then
                return true
            end
        elseif CardType1 == pdktool.CardType.AIRCRAFT_WING or CardType1 == pdktool.CardType.THREE_ONE_CARD or CardType1 == pdktool.CardType.THREE_TWO_CARD then
            if pdktool.compare_three_and_aircraft_take(cards1, cards2) then
                return true
            end
        else
            if pdktool.compare_normal(cards1, cards2) then
                return true
            end
        end
    elseif CardType1 == pdktool.CardType.BOMB_CARD and CardType2 ~= pdktool.CardType.BOMB_CARD then
        return true
    end

    return false
end

--将牌按 牌值分类 单牌 对子 三个 四个 分类
--return oneCards, twoCards, threeCards, fourCards
function pdktool.getAllType(cards)
    local tmpcards = copyTab(cards)
    local kingBomb, fourCards, oneCards, twoCards, threeCards = {}, {}, {}, {}, {}

    --王炸
    if #cards >=2 then
        if cards[1].value == 17 and cards[2] == 16 then
            kingBomb = {cards[1], cards[2]}
        end
        tmpcards = pdktool.subTable(cards, kingBomb)
    end
    --炸弹
    for i = 1, #tmpcards - 3 do
        if tmpcards[i].value == tmpcards[i + 1].value and tmpcards[i].value == tmpcards[i+2].value and tmpcards[i].value == tmpcards[i + 3].value then
            fourCards[#fourCards + 1] = {tmpcards[i], tmpcards[i + 1], tmpcards[i + 2], tmpcards[i + 3]}
        end
    end
    for k,v in pairs(fourCards) do
        tmpcards = pdktool.subTable(tmpcards, v)
    end

    --3个
    for i = 1, #tmpcards - 2 do
        if tmpcards[i].value == tmpcards[i + 1].value and tmpcards[i].value == tmpcards[i + 2].value then
            threeCards[#threeCards + 1] = {tmpcards[i], tmpcards[i + 1], tmpcards[i + 2]}
        end
    end
    for k,v in pairs(threeCards) do
        tmpcards = pdktool.subTable(tmpcards, v)
    end

    --对子
    for i = 1, #tmpcards - 1 do
        if tmpcards[i].value == tmpcards[i+1].value then
            twoCards[#twoCards + 1] = {tmpcards[i], tmpcards[i + 1]}
        end
    end
    for k,v in pairs(twoCards) do
        tmpcards = pdktool.subTable(tmpcards, v)
    end

    --单张
    for i = 1, #tmpcards do
        oneCards[#oneCards + 1] = {tmpcards[i]}
    end

    oneCards   = ascendingTable(oneCards) --小的排在前面
    twoCards   = ascendingTable(twoCards)
    threeCards = ascendingTable(threeCards)
    fourCards  = ascendingTable(fourCards)
    return oneCards, twoCards, threeCards, fourCards, kingBomb
end

--得到带的单牌 cards手上有的牌 playcards 将要出的牌
function pdktool.get_take_single(cards,playCards, count)
    pdktool.sortByCardsValue(cards)

    local takeCards = {}
    local oneCards, twoCards, threeCards, fourCards = pdktool.getAllType(cards)
    --这里是因为不想修改原来的代码所以又倒过来一次
    oneCards   = ascendingTable(oneCards)
    twoCards   = ascendingTable(twoCards)
    threeCards = ascendingTable(threeCards)
    fourCards  = ascendingTable(fourCards)
    if #oneCards >= count then
        for i = count , 1, -1 do
            takeCards[#takeCards + 1] = oneCards[#oneCards - i + 1]
        end

    elseif #oneCards < count and (#oneCards + #twoCards) >= count then
        for i = #oneCards, 1, -1 do
            takeCards[#takeCards + 1] = oneCards[i][1]
        end

        for i = count + #twoCards -#oneCards, 1, -1 do
            takeCards[#takeCards + 1] = twoCards[i]
            takeCards[#takeCards + 1] = twoCards[i + 1]
        end

    elseif (#oneCards + #twoCards) < count and (#oneCards + #twoCards + #threeCards) >= count then
        for i = #oneCards, 1, -1 do
            takeCards[i] = oneCards[i][1]
        end

        for i = #twoCards + #oneCards, 1, -1 do
            takeCards[#takeCards + 1] = twoCards[i]
            takeCards[#takeCards + 1] = twoCards[i + 1]
        end

        for i = count + #threeCards - #twoCards - #oneCards , 1, -1 do
            takeCards[#takeCards + 1] = threeCards[i]
            takeCards[#takeCards + 1] = threeCards[i + 1]
            takeCards[#takeCards + 1] = threeCards[i + 2]
        end
    else
        return nil
    end
    -- for k,v in pairs(takeCards) do
    --   print(k,v)
    -- end

    local tmpTakeCards = {}
    for i = count, 1, -1 do
        tmpTakeCards[#tmpTakeCards + 1] = takeCards[i]
    end
    takeCards = tmpTakeCards
    return takeCards
end

--得到带的对子 cards手上有的牌 playcards 将要出的牌
function pdktool.get_take_double(cards, playCards, count)
    pdktool.sortByCardsValue(cards)
    local takeCards = {}
    local oneCards, twoCards, threeCards, fourCards = pdktool.getAllType(cards)
    oneCards  = ascendingTable(oneCards)
    twoCards   = ascendingTable(twoCards)
    threeCards = ascendingTable(threeCards)
    fourCards  = ascendingTable(fourCards)
    if not twoCards then
        return
    end

    if #twoCards >= count then
        for i = #twoCards, 1, -1 do
            takeCards[#takeCards + 1] = {twoCards[i][1], twoCards[i][2]}
        end
    elseif #twoCards < count and (#twoCards + #threeCards) >= count then
        for i = #twoCards, 1, -1 do
            takeCards[#takeCards + 1] = {twoCards[i], twoCards[i + 1]}
        end

        for i = #threeCards, 1, -1 do
            takeCards[#takeCards + 1] = {threeCards[i], threeCards[i + 1]}
        end
    else
        return nil
    end

    local tmpTakeCards = {}
    for i = count, 1, -1 do
        tmpTakeCards[#tmpTakeCards + 1] = takeCards[i]
    end
    takeCards = tmpTakeCards
    return takeCards
end

function addBomb(playCards,fourCards,kingBomb)
    for i = 1, #fourCards do
        playCards[#playCards + 1] = fourCards[i]
    end
    if #kingBomb == 2 then
        playCards[#playCards + 1] = kingBomb
    end
end

--单牌提示算法  cards 手上有的牌 outcards 已经打出的牌 playcards 要出的牌
function pdktool.tip_single(cards, outCards)
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local playCards = {}
    for k,v in pairs(oneCards) do
        if v[1].value > outCards[1].value then
            playCards[#playCards + 1] = v
        end
    end

    for k,v in pairs(twoCards) do
        if v[1].value > outCards[1].value then
            playCards[#playCards + 1] = {v[1]}
        end
    end

    for k,v in pairs(threeCards) do
        if v[1].value > outCards[1].value then
            playCards[#playCards + 1] = {v[1]}
        end
    end
    addBomb(playCards, fourCards, kingBomb)
    return playCards
end

--对子提示算法 cards 手上有的牌 outcards 已经打出的牌 playcards 要出的牌
function pdktool.tip_double(cards, outCards)
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local playCards = {}
    for k,v in pairs(twoCards) do
        if v[1].value > outCards[1].value then
            playCards[#playCards + 1] = v
        end
    end

    for k,v in pairs(threeCards) do
        if v[1].value > outCards[1].value then
            playCards[#playCards + 1] = {v[1],v[2]}
        end
    end
    addBomb(playCards, fourCards, kingBomb)
    return playCards
end

--三不带提示算法
function pdktool.tip_three(cards, outCards)
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local playCards = {}
    for k,v in pairs(threeCards) do
        if v[1].value > outCards[1].value then
            playCards[#playCards + 1] = v
        end
    end
    addBomb(playCards, fourCards, kingBomb)
    return playCards
end

--炸弹提示算法
function pdktool.tip_bomb(cards, outCards)
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local playCards = {}
    for k,v in pairs(fourCards) do
        if v[1].value > outCards[1].value then
            playCards[#playCards + 1] = v
        end
    end
    return playCards
end

-- 先从手上的牌里面得到各种牌值的一个牌（如｛103,105, 205, 305, 106, 206, 306｝｛103，205，206，｝）
-- 再从得到的牌组合出和outcards牌数一样的牌，再判断 组合出的牌是否是顺子
function pdktool.tip_shunzi(cards, outCards)
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)

    local j = 1
    local playCards = {}
    local len = #outCards
    local tmpcards = {}

    for i = 1, #cards do
        if i == 1 then
            tmpcards[j] = cards[i]
            j = j + 1
        elseif outCards[1].value < cards[i].value and cards[i].value ~= cards[i - 1].value then
            tmpcards[j] = cards[i]
            j = j + 1
        end
    end
    for i = 1, #tmpcards do
        local tmp = {}
        for k = 1, len do
            if (i + len - 1) <= #tmpcards then
                tmp[k] = tmpcards[i + k - 1]
            end
        end
        if pdktool.is_shunzi(tmp) then
            playCards[#playCards + 1] = table.copy(tmp)
        end
    end
    playCards = ascendingTable(playCards)
    addBomb(playCards, fourCards, kingBomb)

    return playCards
end

--连对提示算法和顺子提示算法类似
function pdktool.tip_company(cards, outCards)
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local j = 1
    local playCards = {}
    local len = #outCards / 2
    local tmpcards = {}
    for i = 1, #cards - 1 do
        if i == 1 then
            if cards[i].value == cards[i + 1].value and outCards[1].value < cards[i].value then
                tmpcards[j] = {cards[i], cards[i + 1]}
                j = j + 1
            end
        elseif outCards[1].value < cards[i].value and cards[i].value == cards[i + 1].value and cards[i].value ~= cards[i - 1].value then
            tmpcards[j] = {cards[i], cards[i + 1]}
            j = j + 1
        end
    end
    for i = 1, #tmpcards do
        local tmp = {}
        for k = 1, len do
            if (i + len - 1) <= #tmpcards  then
                tmp[#tmp + 1] = tmpcards[i + k - 1][1]
                tmp[#tmp + 1] = tmpcards[i + k - 1][2]
            end
        end
        if pdktool.is_company(tmp) then
            playCards[#playCards + 1] = tmp
        end
    end
    addBomb(playCards, fourCards, kingBomb)
    return playCards
end

--飞机不带提示算法
function pdktool.tip_aircraft(cards, outCards)
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local j = 1
    local playCards = {}
    local len = #outCards / 3
    local tmpcards = {}
    for i = 1, #cards - 2 do
        if i == 1 then
            if cards[i].value == cards[i + 1].value and cards[i].value == cards[i + 2].value then
                tmpcards[j] = {cards[i], cards[i + 1], cards[i + 2]}
                j = j + 1
            end
        elseif outCards[1].value < cards[i].value and cards[i].value ~= cards[i-1].value and cards[i].value == cards[i + 1].value and cards[i].value == cards[i + 2].value then
            tmpcards[j] = {cards[i], cards[i + 1], cards[i + 2]}
            j = j + 1
        end
    end
    for i = 1, #tmpcards do
        local tmp = {}
        for k = 1, len do
            if (i + len - 1) <= #tmpcards  then
                tmp[#tmp + 1] = tmpcards[i + k - 1][1]
                tmp[#tmp + 1] = tmpcards[i + k - 1][2]
                tmp[#tmp + 1] = tmpcards[i + k - 1][3]
            end
        end
        if pdktool.is_aircraft(tmp) then
            playCards[#playCards + 1] = tmp
        end
    end
    addBomb(playCards, fourCards, kingBomb)
    return playCards
end

-- 三带单牌和对子提示算法
-- getValue(cards[i]) ~= getValue(cards[i - 1]) 使 cards［i］是每一种牌值的第一个 103，203，204，305，105  第一个103和305
function pdktool.tip_three_take(cards, outCards)
    local outCardsValue = 0
    for i = 1, 3 do
        if outCards[i].value == outCards[i+1].value then
            outCardsValue = outCards[i].value
        end
    end
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local playCards = {}
    for k,v in pairs(threeCards) do
        if threeCards[k][1].value > outCardsValue then
            playCards[#playCards + 1] = threeCards[k]
        end
    end
    -- local takeCards = {}
    -- for i = 1, #playCards do
    --     if #outCards ==4 then
    --         takeCards = pdktool.get_take_single(cards, playCards[i], 1)
    --         playCards[i][4] = takeCards[1][1]
    --     else
    --         takeCards = pdktool.get_take_double(cards, playCards[i], 1)
    --         playCards[i][4] = takeCards[1][1]
    --         playCards[i][5] = takeCards[1][2]
    --     end
    -- end
    addBomb(playCards, fourCards, kingBomb)
    return playCards
end

-- 四带单牌和对子提示算法
-- getValue(cards[i]) ~= getValue(cards[i - 1]) 使 cards［i］是每一种牌值的第一个 103，203，204，305，105  第一个103和305
function pdktool.tip_four_take(cards, outCards)
    local outCardsValue = 0
    for i = 1, #outCards - 2 do
        if outCards[i].value == outCards[i + 1].value and outCards[i].value == outCards[i + 2].value then
            outCardsValue = outCards[i].value
        end
    end
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local playCards = {}
    for k,v in pairs(fourCards) do
        if fourCards[k][1].value > outCardsValue then
            playCards[#playCards + 1] = copyTab(fourCards[k])
        end
    end
    addBomb(playCards, fourCards, kingBomb)

    -- local takeCard = {}
    -- for i = 1, #playCards do
    --     if #outCards ==6 then
    --         takeCard = pdktool.get_take_single(cards, playCards[i], 2)
    --         if not takeCard then
    --             return
    --         end
    --         playCards[i][5] = takeCard[1][1]
    --         playCards[i][6] = takeCard[2][1]
    --     else
    --         takeCard = pdktool.get_take_double(cards, playCards[i], 2)
    --         if not takeCard then
    --             return
    --         end
    --         playCards[i][5] = takeCard[1][1]
    --         playCards[i][6] = takeCard[1][2]
    --         playCards[i][7] = takeCard[2][1]
    --         playCards[i][8] = takeCard[2][2]
    --     end
    -- end
    -- addBomb(playCards, fourCards, kingBomb)
    return playCards
end

--飞机带牌提示算法
function pdktool.tip_aircraft_take(cards, outCards)
    local j = 1
    local playCards = {}
    local len = 0
    local isTakeSingel = true
    if #outCards % 4 == 0 then
        len = #outCards / 4
        isTakeSingel = true
    elseif #outCards % 5 == 0 then
        len = #outCards / 5
        isTakeSingel = false
    end
    local outCardsValue = 0
    for i = 1, #outCards - 2 do
        if outCards[i].value == outCards[i + 1].value and outCards[i].value == outCards[i + 2].value then
            outCardsValue = outCards[i].value
        end
    end
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)

    for i = #threeCards, 1, -1 do
        local tmp = {}
        for k = 1, len do
            if (i + len - 1) <= #threeCards  then
                tmp[#tmp + 1] = threeCards[i + k - 1][1]
                tmp[#tmp + 1] = threeCards[i + k - 1][2]
                tmp[#tmp + 1] = threeCards[i + k - 1][3]
            end
        end
        if pdktool.is_aircraft(tmp) and outCardsValue < tmp[1].value then
            playCards[#playCards + 1] = tmp
        end
    end

    local takeCard = {}
    if isTakeSingel then
        takeCards = pdktool.get_take_single(cards, playCards, len)
        if not takeCard then
            return
        end
        for j = 1, #playCards do
            for i = 1, len do
                playCards[j][6 + i] = takeCards[i][1]
            end
        end
    else
        takeCards = pdktool.get_take_double(cards, playCards, len)
        if not takeCard then
            return
        end
        for j = 1, #playCards do
            for i = 1, len do
                playCards[j][6 + i] = takeCards[i][1]
                playCards[j][8 + i] = takeCards[i][2]
            end
        end
    end
    addBomb(playCards, fourCards, kingBomb)
    return playCards
end

-- 得到顺子
function pdktool.getConnect(cards)
    pdktool.sortByCardsValue(cards)
    local tmpcards,playCards = {}, {}
    for i = 1, #cards do
        if i == 1 then
            tmpcards[#tmpcards + 1] = cards[i]
        elseif i ~= 1 and cards[i].value ~= cards[i - 1].value then
            tmpcards[#tmpcards + 1] = cards[i]
        end
    end
    for i = #tmpcards, 5, -1 do
        for j = 1, #tmpcards - i do
            local tmp = {}
            for k = 1, i do
                tmp[#tmp + 1] = tmpcards[k + j]
            end
            if pdktool.is_shunzi(tmp) then
                playCards[#playCards + 1] = copyTab(tmp)
            end
        end
    end
    return playCards
end

-- 得到顺子
function pdktool.getShunZi(cards)
    local playCards = {}
    pdktool.sortByCardsValue(cards)
    if pdktool.is_shunzi(cards) then
        playCards[#playCards + 1] = cards
    end
    return playCards
end

-- 没有上家牌的时候 提示
function pdktool.tips(cards)
    local oneCards, twoCards, threeCards, fourCards, kingBomb = pdktool.getAllType(cards)
    local playCards = {}
    local tmpConnect = pdktool.getShunZi(cards)
    for k,v in pairs(tmpConnect) do
        playCards[#playCards + 1] = v
    end
    for i = 1, #threeCards do
        if #cards < 6 then
            playCards[#playCards + 1] = cards
        else
            playCards[#playCards + 1] = threeCards[i]
        end
    end
    for i = 1, #twoCards do
        playCards[#playCards + 1] = twoCards[i]
    end
    for i = 1, #oneCards do
        playCards[#playCards + 1] = oneCards[i]
    end
    for i = 1, #fourCards do
        playCards[#playCards + 1] = fourCards[i]
    end
    for i = 1, #kingBomb do
        playCards[#playCards + 1] = kingBomb[i]
    end
    if pdktool.is_company(cards) then
        playCards[#playCards + 1] = cards
    end
    return  playCards
end

--获取出牌提示
function pdktool.getTips(cards, outCards)
    local tmpOutCards = outCards
    local playCards = {}
    if #tmpOutCards == 0 then
        playCards = pdktool.tips(cards)
        return playCards
    end
    local cardsType = pdktool.getType(outCards)
    if cardsType == pdktool.CardType.SINGLE_CARD  then
        playCards = pdktool.tip_single(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.DOUBLE_CARD then
        playCards = pdktool.tip_double(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.THREE_CARD then
        playCards = pdktool.tip_three(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.THREE_TWO_CARD or cardsType == pdktool.CardType.THREE_ONE_CARD then
        playCards = pdktool.tip_three_take(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.BOMB_FOUR_CARD or cardsType == pdktool.CardType.BOMB_TWO_CARD or cardsType == pdktool.CardType.BOMB_THREE_CARD then
        playCards =  pdktool.tip_four_take(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.CONNECT_CARD then
        playCards = pdktool.tip_shunzi(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.COMPANY_CARD then
        playCards = pdktool.tip_company(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.AIRCRAFT_CARD then
        playCards = pdktool.tip_aircraft(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.AIRCRAFT_WING then
        playCards = pdktool.tip_aircraft_take(cards, tmpOutCards)
    elseif cardsType == pdktool.CardType.BOMB_CARD then
        playCards = pdktool.tip_bomb(cards, tmpOutCards)
    else
        return {}
    end
    return playCards
end

--要出的牌是否都在手牌中 true 是 false 否
function pdktool.inhandle(cards, outCards)
    if #outCards == 0 then
        return true
    end
    local ret = 0
    for k,v in pairs(outCards) do
        for i=1, #cards do
            if v.color == cards[i].color and v.value == cards[i].value then
                ret = ret + 1
            end
        end
    end
    return (ret == #outCards)
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


function pdktool.checkDistance(lat,lng,users)
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

function pdktool.checkIp(ip,users)
    for _, user in pairs(users) do
        if user.ip ==  ip then
            return nil
        end
    end
    return true
end

function pdktool.jisuanXY(users)
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

return pdktool