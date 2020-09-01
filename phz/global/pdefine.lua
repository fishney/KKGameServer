-- by: xiehuawei@pandadastudio.com
local PDEFINE_MSG = require "pdefine_msg"
local PDEFINE_ERRCODE = require "pdefine_errcode"
local PDEFINE_GAME = require "pdefine_game"
local PDEFINE_REDISKEY = require "pdefine_rediskey"
require "language/chineselang"
require "language/englishlang"

-- 定义一些常量
PDEFINE = {}

-- 接口协议对应处理函数
PDEFINE.PROTOFUN = PDEFINE_MSG.PROTOFUN
-- 错误码
PDEFINE.RET = PDEFINE_ERRCODE

PDEFINE.GAME_TYPE = PDEFINE_GAME.GAME_TYPE

--游戏自动启动
PDEFINE.GAME_AUTO_START = PDEFINE_GAME.AUTO_START

--游戏类型
PDEFINE.GAME_KIND = PDEFINE_GAME.KIND

--游戏匹配接口
PDEFINE.GAME_MATCH = PDEFINE_GAME.MATCH

--游戏类型ID 以及需要创建的个数
--ID 游戏ID
--COUNT 创建的agent数量 百人场目前配置一个就行
--MATCH 0直接创建新房间(单机类) 1匹配规则(对战类) 2百人场(百人场)
PDEFINE.GAME_TYPE_INFO = PDEFINE_GAME.TYPE_INFO

PDEFINE.NOTIFY = PDEFINE_MSG.NOTIFY

PDEFINE.NUMBER = PDEFINE_GAME.NUMBER

--应用ID
PDEFINE.APPID = 
{
    ["LAMI"] = 1,       --拉米
    ["RUILI"] = 2,      --瑞力
    ["BIGBANG"] = 3,    --BigBang
    ["POLY"] = 4,       --Poly99
}

-- 消息类型
PDEFINE.NOTICE_TYPE =
{
    ["SYS"] = 1, --系统
    ["USER"] = 2, --玩家
}

-- slot日志类型
PDEFINE.LOG_TYPE =
{
    ["BONUS_GAME"] = 1, --BONUS_GAME
    ["BET_X"] = 2, --BET_X
    ["FREE_GAME"] = 3, --FREE_GAME
}

PDEFINE.QUEST_STATE =
{
    ["INIT"] = 0, --初始化
    ["DONE"]  = 1, --完成了,可以领取了
    ["GET"] = 2, --领取了
    ["STOP"] = 4, --停止
}

--rediskey
PDEFINE.REDISKEY = PDEFINE_REDISKEY

--默认的概率配置
PDEFINE.DEFAULTREWARDRATE = "3"

--api的worker数量
PDEFINE.MAX_APIWORKER = 10

--上报数据的功能模块名称
PDEFINE.REPORTMOD=
{
    ["login_c1"] = "login_c1",
    ["login_c2"] = "login_c2",
    ["offline"] = "offline",
    ["matchsess"] = "matchsess",
    ["exitgame"] = "exitgame",
    ["gamekick"] = "gamekick",
    ["gameresult"] = "gameresult",
}

--第三方平台定义
PDEFINE.PLATFORM = 
{
    ["EVO"] = 
        {
            ["ID"] = 30000, 
            ["NAME"] = "evo"
        },
}

PDEFINE.EVO_AMOUNT_STATE = 
{
    ["ready"] = 0, --准备提交给evo那边(处于这个状态的订单 在服务器启动以后需要定时对订单进行核算 看对方是不是已经接收了)
    ["funddeposit"] = 1,--evo已经接收数据(暂时不做超时处理 之后有需要再做)
    ["bill"] = 2,--结账(定时结账)
    ["wait"] = 3,--等待人工处理
    ["billover"] = 4,--订单结算完成（订单详情还未处理）
    ["evoover"] = 5,--evo流程完成
}

PDEFINE.SERVER_STATUS =
{
    ["start"] = 0,
    ["run"] = 1,
    ["full"] = 2,
    ["weihu"] = 3,
    ["stop"] = 4,
}

PDEFINE.SERVER_EVENTS =
{
    ["start"] = "start",
    ["stop"] = "stop",
    ["changestatus"] = "changestatus",
}

--玩家类型
PDEFINE.USER_TYPE =
{
    ["vip"] = "vip",
    ["normal"] = "normal",
}

-- 策略模块服务数量
PDEFINE.STRATEGY_WORKER_NUM = 8

--语言常量
PDEFINE.LANGUAGE =
{
    {
        ["KEY"] = "chinese", 
        ["LANG"] = CHINESELANG,
    },
    {
        ["KEY"] = "english", 
        ["LANG"] = ENGLISHLANG,
    },
}

--修改coin类型
PDEFINE.ALTERCOINTAG =
{
    ["UP"] = 1,--上分
    ["DOWN"] = 2,--下分
    ["BET"] = 3,--下注
    ["WIN"] = 4,--赢钱
    ["BIGBANG"] = 5,--bigbang
    ["REDBAG"] = 6,--红包
    ["THRIDADD"] = 7,--第三方转入
    ["THRIDOUT"] = 8,--第三方转出
    ["LUACK_REDBAG"] = 9, --幸运红包
    ["RAIN_REDBAG"] = 10, -- 红包雨
    ["GROW_BOX"] = 11, --成长系统的宝箱
    ["MAXTAG"] = 11,--最大的tag值
    ["REDENVELOPE"] = 12,--红包用户从初始红包上分
    ["LOSER"] = 13,--输钱
    ["BANKCASH"] = 14,--银行存款
    ["BANKDEBITS"] = 15,--银行取款
    ["PROFIT_TRANSFER"] = 101, --收益余额提现成账户余额，玩家账户将自身当前的收益余额提现到账户余额

    ["TODOWN_REDUCE"]     = 102,   --推广员关系，往下级转，自身余额减少
    ["TOUP_REDUCE"]     = 103,   --推广员关系，往上级转，自身余额减少
    ["TODOWN_ADD"]     = 104,   --推广员关系，被上级上分，余额被动增加
    ["TOUP_ADD"]     = 105,   --推广员关系，被下级上分，余额被动增加
    ["CHARGE2THIRDGAME"] = 106, --往第3方游戏平台充值
    ["WITHDRAWTHIRDGAME"] = 107, --从第3方游戏平台提现
    ["CHARGE2THIRDGAMEFAIL"] = 108, --往第3方游戏平台充值失败
}

--一轮借款或者扣库存的状态
PDEFINE.POOLROUND_STATUS = 
{
    ["start"] = 0, --开始
    ["end"] = 1, --已经结束
    ["expireend"] = 2, --过期结束
}

--彩池事件的类型
PDEFINE.POOLEVENT_TYPE = 
{
    ["delstock"] = 1, --扣库存结算
    ["loan"] = 2, --结算-来自借款
    ["redbag"] = 3 --红包-来自借款
}

--彩池的类型
PDEFINE.POOL_TYPE = 
{
    ["none"] = 0, --不是彩池来的
    ["delstock"] = 1, --扣库存
    ["loan"] = 2, --借款
}

PDEFINE.SUBGAME_STATE = {
    ["START"] = 1, -- join时候为开始
    ["ACTION"] = 2, -- 选择动作时候
    ["PEXIT"] = 3, -- 准备退出
    ["NORMAL"] = 0,
}

--slots 押注是否押满
PDEFINE.BET_TYPE = {
    ['FULL'] = 1,    -- 押满
    ['NOTFULL'] = 0, -- 未押满
}