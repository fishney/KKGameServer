PDEFINE_ERRCODE =
{
    ["SUCCESS"] = 200,              -- 成功
    ["UNDEFINE"] = 300,             -- 未定义错误
    ["ERROR"] =
    {
        ["EXIT_RESET"] = 199, --主動退出
        ["REGISTER_ALREADY"] = 201, --已注册
        ["REGISTER_NOT"] = 202, --未注册
        ["LOGIN_FAIL"] = 203, --账号或者密码错误
        ["REGISTER_FAIL"] = 208, --登录失败,请重新登录
        ["PARAM_NIL"] = 209, --参数为空
        ["PARAM_ILLEGAL"] = 210, --参数非法
        ["TOKEN_ERR"] = 211, --token失效
        ["DBPUSH_ERR"] = 212, --系统错误-数据库-更新
        ["PASSWD_ERR"] = 213, --密码错误
        ["RES_VERSION_ERR"] = 214,  --资源版本号错误需要更新
        -- ["APP_VERSION_ERR"] = 215,  --APP版本号错误需要更新
        ["CALL_FAIL"] = 400,        -- 调用错误
        ["DB_FAIL"] = 401,      -- 数据库错误
        ["BAD_REQUEST"] = 402,      -- 错误请求
        ["UNAUTHORIZED"] = 403,     -- 认证失败
        ["INDEX_EXPIRED"] = 404,    -- 重连索引过期
        ["PLAYER_NOT_FOUND"] = 405, -- 找不到玩家
        ["FORBIDDEN"] = 406,        -- 登录繁忙
        ["ALREADY_LOGIN"] = 407,    -- 已经登录
        ["DECODE_FAIL"] = 408,      -- 解析protocbuf错误
        ["NAME_ALREADY"] = 409,     -- 已经存在该名字
        ["ACTION_ERROR"] = 410,     -- 操作错误
        ["PLAYER_EXISTS"] = 411,    -- 已经存在角色
        ["ACCOUNT_ERROR"] = 412,    -- 账号被冻结暂不能登录
        ["HEARTBEAT_BROKEN"] = 415,
        ["ACCOUNT_ERROR_5"] = 416, --账号被冻结5秒
        ["ACCOUNT_ERROR_10"] = 417, --账号被冻结10秒
        ["ACCOUNT_ERROR_20"] = 418, --账号被冻结20秒
        ["ACCOUNT_ERROR_600"] = 419, --账号被冻结600秒
        ["SERVER_NOTREADY"] = 420, --服务器未准备好
        ["FORBIDDEN_LOGIN"] = 421, --禁止登录
        ["FORBIDDEN_AREA_LOGIN"] = 422, --账号禁止在该区域登录
        ["DESK_NOT_FIND"] = 423, --账号禁止在该区域登录
        ["CHECKCODE_ERR"] = 425, --手机验证码失效
        ["BET_ERROR"] = 426, --限红5000
        ["RED_ERROR"] = 427, --不满足条件
        ["BIND_ERROR"] = 428, --绑定错误
        ["BIND_MOBILE_ALREAD"] = 429, --改手机号已被注册
        ["ERROR_LOGIN"] = 430, --IP被禁

        ["CLUB_IS_CREATE"] = 431,      -- 俱乐部已创建
        ["CREATE_ERROR"] = 432,      -- 俱乐部已创建
        ["CLUB_NOT_FIND"] = 433,      -- 俱乐部未发现
        ["CLUB_GAME_TYPE_ALREADY"] = 434,      -- 俱乐部该玩法已存在
        ["CLUB_NAME_EXIST"] = 435,      -- 俱乐部该玩法已存在
        ["DISTANCE_EXIST"] = 436,      -- 距离其它玩家少于200米
        ["CHECK_IP"] = 437,      -- 禁止同IP进入
        ["CLUB_NOT_EXIST"] = 438,      -- 不在该俱乐部
        ["CLUB_NOT_CREATE"] = 439,      -- 不是俱乐部创建人没有冻结权限
        ["CLUB_IS_FREEZE"] = 440,      -- 俱乐部已冻结
        ["PUT_MAX_CARD"] = 441,      -- 请出最大的牌
        ["PUT_MIN_CARD"] = 442,      -- 请包含最小的牌
        ["NOT_DESK_INFO"] = 443,      -- 当前未加入过游戏
        ["ITEM_ENOUGH"] = 501,      -- 物品不足
        ["AlREADY_READY"] = 502,    -- 该用户已准备
        ["GAME_NOT_SART"] = 503,    -- 游戏未开始
        ["FOLLOW_FAULT"] = 504,     -- 跟注错误
        ["COMPARE_FAULT"] = 505,    -- 比牌失败
        ["ALREADY_JOIN"]  = 506,    -- 已经加入
        ["ALCODE"]  = 507,    -- 已经加入
        ["COMPARE_SEECARD_ERROE"]  = 508, -- 不能跟自己比牌
        ["AlREADY_BACK"] = 509,    -- 用户已退出
        ["VIPDESK_PASSWD_FALSE"] = 510, --口令错误
        ["GAME_ALREADY_SART"] = 511,    -- 游戏已经开始
        ["GAME_ALREADY_END"] = 512,    -- 游戏已经结束
        ["GAME_NO_SEAT"] = 513,    -- 房间人数已满
        ["GAME_NOT_CURRENTITEM"] = 514, --未设置底注
        ["GAME_NOT_JOIN_GAME"] = 515, --未在桌子上
        ["SEE_CARD_ERROR"]  = 516, -- 看牌错误
        ["CHANG_DESK_ERROR"]  = 517, -- 加入错误
        ["LEVE_DESK_ERROR"]  = 518, -- 离开
        ["GAME_ING_ERROR"]  = 519, -- 该局游戏正在进行中
        ["CREATE_DESK_ERROR"]  = 520, -- 创建游戏信息有误
        ["SHOW_CARD_ERROR"]  = 521, -- 摊牌信息有误
        ["GAME_ALREADY_DELTE"]  = 522, -- 有人已经发起了解散
        ["CARD_TDAO_ERROR"]  = 523, -- 头道不能大于中道
        ["CARD_ZDAO_ERROR"]  = 524, -- 中道不能大于尾道
        ["ERRCODE"]  = 525,    -- 不存在改验证码
        ["CURSTART_ERROR"]  = 526,    -- 不存在改验证码
        ["USER_IN_GAME"]  = 527,    -- 玩家在游戏内，不让充值
        ["MAIL_NOT_FOUND"] = 604,   -- 邮件找不到
        ["NO_ACTION_ERROR"] = 605,    --不改你操作
        ["ERROR_ACTION_ERROR"] = 606,   --错误操作

        ["USER_AGENT_ERROR"] = 607,   --只有代理商可以查看哦
        ["USER_CASH_ZERO"]   = 608,   --可提现金额为0
        ["USER_CASH_FAIL"]   = 609,   --提现失败
        ["BET_NOT_ENOUGH"] = 610, --押注金币值错误
        ["BANKER_CANNOT_APPLY"]   = 611,   --您已经是庄家了

        ["BANK_USER_COIN_NOT_ENOUGH"] = 612, --玩家可使用的金币不足
        ['LOGIN_AREACODE'] = 613, --账号不能在此区域登录
        ["CALCOIN_LOG_MUST"] = 618,      --修改玩家金币的时候必须带日志
        ["ERROR_BANG_ING"] = 619,      --修改玩家金币的时候必须带日志

        ["DESKID_FAIL"]  = 700, -- 房间号错误
        ["PLAYER_EXISTS_DESK"] = 710,    -- 已经在该房间
        ["ROOMCARD_NOT_ENOUGH"] = 720,    -- 房卡不足
        ["DESK_TYPE_ERROR"] = 730,    -- 房间类型不存在
        ["NOT_OWER_ERROR"] = 740,    -- 不是房主 游戏未开始不能发起解散
        ["HUPAI_ERROR"] = 750,    -- 硬自摸 带财神 平胡不让胡

        ["MUST_RESTART"] = 801, --客户端必须重启
        ["ERROR_GAME_FIXING"] = 803, --游戏维护中
        
        ["COIN_NOT_ENOUGH"] = 804, --金币不足
        ["GIVE_UP_CARD"] = 805, --看牌失败，已经弃牌了
        ["FOLLOW_NOT_ALIVE"] = 806,     -- 跟注错误
        ["FOLLOW_COIN"] = 807, --下注金额错误
        ["FOLLOW_NOT_SEAT"] = 808, --不是此座位说话
        ["ROUND_NOT_ENOUGH"] = 809, --必闷轮数不够
        ["RESERVE_OR_LIMIT_NOT_ENOUGH"] = 810, --储备金或者提取额度不足
        ["BANK_COIN_NOT_ENOUGH"] = 811, --银行存款不足
        ["BANK_PASSWD_ERROR"] = 812, --银行密码错误
        ["ACT_AT_SAME_TIME"] = 898, --操作太频繁哦
        ["BANKER_CAN_NOT_BET"] = 899, --庄家不能下注哦
        ["EXISTS_BANNER"] = 900, --庄已存在
        ["NOT_BANKER"] = 901, --没选庄
        ["NOT_BET"] = 902, --没下注
        ["NOT_READY"] = 903, --没准备 没牌
        ["NOT_NORMAL_CARDS"] = 904, --牌数据错误
        ["NOT_IN_HANDLE"] = 905, --出牌不在手牌中

        ["NOT_IN_ACTION"] = 906, --不能执行此操作
        ["CAN_NOT_JOIN"] = 907, -- 没开启中途加入不能准备
        ["NOT_IN_SEAT"] = 908, --没坐下哦

        --龙争虎斗
        ["WAIT_NEXT_ROUND"] = 909, --等下一回合
        ["NOT_FOUND_PLACE"] = 910, --方位错误
        ["CAN_NOT_BET_AT_SAME_TIME"] = 911, --龙虎不能同时下

        ["EXCEED_BET_AMOUNT"]  = 912, --超过最大允许的押注
        ["GAME_NO_ALLOW_JOIN"] = 913,    -- 房间不允许中途加入
        ["USER_NOT_READY"] = 914,    --用户未准备
        ["USER_SEATID_NO_FOUND"] = 915,    --未找到该座位用户
        ["MULTIPLE_ERROR"] = 916, --倍数超范围
        ["BET_RANGE_ERRO"] = 917, --底注超范围
        ["LEFTCOIN_RANGE_ERRO"] = 918, --离场金币错误
        ["MINCOIN_RANGE_ERRO"] = 919, --入场金币错误
        ["TYPE_RANGE_ERRO"] = 920, --类型错误
        ["NOT_IN_ROOM"] = 921, --玩家不在房间内
        ["ERROR_HAD_SITDOWN"] = 922, --玩家已经坐下
        ["ERROR_MORETHAN_SEAT"] = 923, --座位号超过最大人数
        ['ERROR_SEAT_EXISTS_USER'] = 924, --此座位已经有人
        ["NOT_ROOM_OWNER"] = 925, --不是房主
        ["SOMEONE_NOT_READY"] = 926, --有人没准备

        ["PERSON_NOT_ENOUGH"] = 927, --人数不足
        ["DESK_NOT_ENOUGH"] = 928, --服务器房间数不够
        ["VIRTUAL_COIN_NOT_ENOUGH"] = 929, --体验币不足
        ["FB_AUTH_FAIL"] = 930, --FB玩家才可创建该房间
        ["RELOAD"] = 931, --房间不存在 玩家还卡在房间中
        ["SURPASS_MAX_MULT"] = 932, --水浒传加注倍数超过最大倍数
        ["SURPASS_MAX_SCORE"] = 933, --水浒传加注倍数超过最大金币

        ["JOINING_DESK"] = 934, --房间加载中
        ["ALREADY_AWARD"] = 935, --奖励已领取
        ["FGR_COIN_NOT_ENOUGH"] = 936, --开房金币不足
        ["PAY_FAILD"] = 937, --支付下单失败
        ["WECHAT_AUTH_FAILD"] = 940, --微信登录失败
        ["FACEBOOK_AUTH_FAILD"] = 941, --fb登录失败
        ["SURPASS_MAX_LINE"] = 943, --拉霸游戏超过最大押注线
        ["POOL_NOMAL_NOT_ENOUGH"] = 944, --normalpool余额不足
        
        --推广员错误码
        ["ACCOUNT_HAD_EXIST"] = 950, --用户名已经存在
        ["EMAIL_HAD_EXIST"]   = 951, --Email已经存在
        ["INVAlID_CODE"]      = 952, --邀请码不存在
        ["EMAIL_SEND_FAIL"]   = 953, --邮件发送失败
        ["INVAlID_CODE_FAIL"] = 954, --找回密码重设,验证码不存在或错误
        ["ACCOUNT_NOT_FOUND"] = 955, --账号不存在
        ["BALANCE_NOT_ENOUG"] = 956, --当前没有可提现收益
        ["PASSWD_ERROR"]      = 957, --支付密码错误
        ["TRANSFER_ERROR"]      = 958, --转账失败
        ["TRANSFER_RELATION_ERROR"] = 959, --必须是直接上下级关系才能转账

        ["ACCOUNT_TOO_SHORT"] = 960, --用户名必须为6位或以上字符
        ["PASSWD_IS_EMPTY"]   = 961, --用户名必须填写
        ["EMAIL_IS_EMPTY"]    = 962, --密码必须填写
        ["PCODE_IS_ERROR"]     = 963, --邀请码错误

        ["ENVELOPE_BALANCE_ENOUGH"]   = 964, --红包余额不足
        ["ENVELOPE_BALANCE_ALREADY"]   = 965, --红包已兑换

        ["MOBILE_IS_REGIST"] = 966,--该手机号已注册
        
        ["PUT_CARD_ERROR"] = 8928, --出牌操作错误
        ["SEATID_EXIST"] = 9929, --玩家已退出
        ["SHOW_CARD_ERROR"] = 9930, --摊牌异常
        ["KICK_ERROR"] = 9931, --不是房主不能踢

        
        ["DESK_ERROR"] = 1000, --房间数据异常
        

        ["PRODUCT_NOT_FOUND"] = 1404, --商品找不到
        ["ORDER_CREATED_FAIL"]= 1405, --IAP下单失败
        ["CAN_NOT_BET_TWO_PLACE"] = 1406, --不能同时下注2个方位
        ["CAN_NOT_REPORT_SELF"] = 1407, --不能举报自己
        ["REPORT_LACK_OF_DATA"] = 1408, --举报缺少资料
        ["REPORT_TOO_FREQUENT"] = 1409, --举报太频繁失败
        ["REPORT_FAILED"] = 1450, --举报失败

        ["ROUND_BET_SUM_COIN_NO_LEFT"] = 1051, --本轮投注额已满
        ['REPEAT_SUBMIT_FEEDBACK'] = 1052, --玩家重复提交
        ['PARAM_IS_EMPTY']  = 1055,  --玩家重复提交
        ['USER_HAD_CERTIF'] = 1056,  --玩家已认证过
        ["CAN_NOT_BET"] = 1057,      --自己是庄家 不能下注


        ["ORDER_PAID_EMPTY_PARAMS"] = 1058, --支付失败（订单等参数不能为空）
        ["ORDER_PAID_VERIFY_RECEIPT_FAILED"]= 1059, --支付验证凭证失败
        ["ORDER_PAID_VERIFY_PRODUCT_FAILED"]= 1060, --支付验证商品失败
        ["ORDER_PAID_ORDER_NOT_FOUND"] = 1061, --支付验证订单号错误
        ["ORDER_PAID_USER_ERROR"] = 1062, --支付验证订单归属错误
        ["ORDER_PAID_VERIFY_STATUS_FAILED"] = 1063, --支付验证, 未成功支付
        ["ORDER_PAID_UPDATE_FAILED"] = 1064, --支付验证，更新订单失败

        -- 以下错误码没给过客户端
        ["APPLY_OFF_BANKER_STATE_FAIL"] = 1065, --只能在空闲时间内下庄哦
        ["BET_COIN_NOT_ENOUGH"] = 1066, --金币不足，选用小一点的筹码
        ["ERROR_NO_JOINMIDDLE"] = 1067, --此房间不允许中途加入

        ["BIND_FB_VALIDATE"] = 1068, --绑定验证失败
        ["BIND_FB_DATA"]     = 1069, --绑定获取信息失败
        ["BIND_FB_AGAIN"]    = 1070, --此账号已经绑定过，不能重复绑定
        ["BIND_FB_USEAGAIN"] = 1071, --系统已存在此FB账号

        ["TASK_NOT_FINISH"] = 1072, --此任务还未完成
        ["NICKNAME_INCLUCE_ILLEGAL_CHARACTER"] = 1073, --您的昵称包含非法字，请重新修改
        ["NICKNAME_HAD_USED"] = 1074, --昵称已经被使用
        ["TOO_REPEAT"] = 1075, --频率太频繁
        ["CAN_NOT_BROADCAST"] = 1076, --用户没有发送权限
        ["BANKER_COIN_NOT_ENOUGH"] = 1077, --百人牛牛，上庄金币不足

        ["YABAO_COIN"] = 1078, --押宝金币不能小于0
        ["YABAO_PLACE"] = 1079, --押宝方位不对

        ["HBULL_COIN_NOT_ENOUGH"] = 1080, --剩余金币须大于50K才能下注
        ["WAIT_FOR_NEXT_TIME"] = 1081, --请等待下次哟

        --绑定微信
        ["BIND_WX_AGAIN"]    = 1082, --此账号已经绑定过微信，不能重复绑定
        ["BIND_WX_VALIDATE"] = 1083, --绑定微信验证失败
        ["BIND_WX_DATA"]     = 1084, --绑定微信获取信息失败
        ["BIND_WX_USEAGAIN"] = 1085, --系统已存在此微信账号

        ["DRAW_ERROR"] = 1086, --摸牌错误
        ["ERROR_PENG_ERROR"] = 1087, --碰牌错误
        ["ERROR_GANG_ERROR"] = 1088, --杠牌错误
        ["TASK_HAD_CLOSE"] = 1089, --该任务已经关闭
        ["APPLY_OFF_BANKER"] = 1090,      --该阶段不可下庄
        ["CANNOT_OFF_BANKER"] = 1091,     --您是庄家不能退出哦
        ["BENZ_COIN_NOT_ENOUGH"] = 1387, --剩余金币须大于50K才能下注
        ["ERROR_HUPAI_ERROR"] = 1089, --杠牌错误
        ["FINISHGAME_ERR"] = 1388, --业务游戏结算失败


        ["INVAlID_ERROR"] = 20000, --摸牌错误
        ["CREATE_AT_THE_SAME_TIME"] = 10005,

        ["PLAYER_HAD_ACT"] = 102101, --玩家已经操作过
        ["PLAYER_CANT_SPLIT"] = 102102, --玩家不能拆牌
        ["PLACE_ERROR"] = 102103, --玩家操作位置错误
        ["PLAYER_HAD_BET"] = 102104, --您已经要过牌了
        ["PLAYER_CANT_BUYSAFE"] = 102105, --您不能购买保险
        ["PLAYER_CANT_JUMPSAFE"] = 102106, --您不能跳过保险

        ["HULUJI_NOBETCOIN"] = 21601, --葫芦机玩法中 开堵的时候赌注总和为0
        ["NOT_NOT_SUBGAME"] = 10001, -- 拉霸小游戏已经玩过了，再请求就会报错
        ["ISBILLING"] = 3000001, --正在交易中
        ["ISBILLING"] = 3000001, --正在交易中
    }
}
return PDEFINE_ERRCODE