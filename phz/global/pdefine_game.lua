PDEFINE_GAME = {}

PDEFINE_GAME.GAME_TYPE = 
{
    ["ZIPAI_PENGHZ"] = 1, --俱乐部攸县碰胡子 
    ["ZIPAI_PENGHZ_SR"] = 3, --攸县碰胡子, 开房类
    ["ZIPAI_PAOHZ"] = 2, --俱乐部攸县跑胡子
    ["ZIPAI_PAOHZ_SR"] = 4, --攸县跑胡子,开房类
    ["ZIPAI_HONGHEIHU"] = 5, --俱乐部红黑胡
    ["ZIPAI_HONGHEIHU_SR"] = 6, --红黑胡,开房类
    ["ZIPAI_LIUHUQIANG"] = 7, --俱乐部六胡抢
    ["ZIPAI_LIUHUQIANG_SR"] = 8, --六胡抢,开房类
    ["PUKE_PAODEKUAI"] = 9, --俱乐部跑得快
    ["PUKE_PAODEKUAI_SR"] = 10, --跑得快,开房类
    ["MJ_HONGZ"] = 11, --俱乐部红中
    ["MJ_HONGZ_SR"] = 12, --红中,开房类
}

--游戏类型
PDEFINE_GAME.GAME_PARAM = 
{
    ["DISS_TIME"] = 600, --超时时间
}

--游戏类型
PDEFINE_GAME.KIND = 
{
    ["FIGHT"] = 1, --对战
    ["BET"]   = 2, --下注类  百人场
    ["ALONE"]   = 3, --单击
}

--游戏匹配接口
PDEFINE_GAME.MATCH = 
{
    ["FIGHT"] = "matchFight", --对战
    ["BET"]   = "matchBet", --下注类  百人场
    ["ALONE"]   = "matchAlone", --单击
}

--游戏名称
PDEFINE_GAME.TYPE_INFO = 
{
    [1] = -- 攸县碰胡子
    {
        ID = 1,
        COUNT = 4,
        STATE = 1,
        AGENT = "penghziagent",
        MATCH = "FIGHT",
    },
    [2] = -- 攸县跑胡子 
    {
        ID = 2,
        COUNT = 4,
        STATE = 1,
        AGENT = "paohziagent",
        MATCH = "FIGHT",
    },
    [3] = -- 攸县碰胡子 开房类
    {
        ID = 3,
        COUNT = 4,
        STATE = 1,
        AGENT = "srpenghziagent",
        MATCH = "FIGHT",
    },
    [4] = -- 攸县跑胡子 开房类
    {
        ID = 4,
        COUNT = 4,
        STATE = 1,
        AGENT = "srpaohziagent",
        MATCH = "FIGHT",
    },
    [5] = -- 红黑胡
    {
        ID = 5,
        COUNT = 4,
        STATE = 1,
        AGENT = "hongheihuagent",
        MATCH = "FIGHT",
    },
    [6] = -- 红黑胡 开房类
    {
        ID = 6,
        COUNT = 4,
        STATE = 1,
        AGENT = "srhongheihuagent",
        MATCH = "FIGHT",
    },
    [7] = -- 六胡抢
    {
        ID = 7,
        COUNT = 4,
        STATE = 1,
        AGENT = "liuhuqiangagent",
        MATCH = "FIGHT",
    },
    [8] = -- 六胡抢 开房类
    {
        ID = 8,
        COUNT = 4,
        STATE = 1,
        AGENT = "srliuhuqiangagent",
        MATCH = "FIGHT",
    },
    [9] = -- 跑得快
    {
        ID = 9,
        COUNT = 4,
        STATE = 1,
        AGENT = "paodekuaiagent",
        MATCH = "FIGHT",
    },
    [10] = -- 跑得快 开房类
    {
        ID = 10,
        COUNT = 4,
        STATE = 1,
        AGENT = "srpaodekuaiagent",
        MATCH = "FIGHT",
    },
    [11] = -- 红中
    {
        ID = 11,
        COUNT = 4,
        STATE = 1,
        AGENT = "hongzagent",
        MATCH = "FIGHT",
    },
    [12] = -- 红中 开房类
    {
        ID = 12,
        COUNT = 4,
        STATE = 1,
        AGENT = "srhongzagent",
        MATCH = "FIGHT",
    },
}

PDEFINE_GAME.NUMBER =
{
    views = 16, --观战人数
    maxround = 100000, --最大局数

    people = 2,
    delteTime = 60,
    nvalue = 1000,
    fgrgame = 1000000
}
return PDEFINE_GAME