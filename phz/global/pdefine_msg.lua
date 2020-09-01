PDEFINE_MSG = {}
--协议
-- 接口协议对应处理函数
PDEFINE_MSG.PROTOFUN = 
{
    ["11"] = "player.heartBeat",
    ["2"]  = "player.getLoginInfo",
    ["3"]  = "player.getLoginInfo", --断线重连使用


    --["SHARE_GAME"] = "player.shareGame",
 
    ["DELTE_GAME"] = "cluster.game.dsmgr.deltel", --解散房间
    ["AGREED_DELTE_GAME"] = "cluster.game.dsmgr.agreedDeltel", --同意解散
    ["NO_AGREED_DELTEL"] = "cluster.game.dsmgr.agreedNoDeltel", --拒绝解散
    ["EXIT_GAME"] = "cluster.game.dsmgr.exitG", --退出房间
    ["25"] = "jackpot.getHallAndJp", --获取大厅bigbang跟游戏奖金池
    ["26"] = "player.changepasswd", --修改玩家登陆密码
    ["27"] = "player.scoreLog",     --上下来
    

    ["28"] = "player.bindCode", --绑定邀请码
    ["29"] = "player.getCoin",  --获取玩家金币
    ["30"] = "player.getGameInfoList", --点击游戏icon 进入游戏大厅
    
    ["31"] = "cluster.game.dsmgr.createDeskInfo",--创建房间
    ["32"] = "cluster.game.dsmgr.joinDeskInfo",--加入房间

    ["33"] = "cluster.game.dsmgr.sitdown",     --坐下
    ["34"] = "player.getRoomList", --游戏大厅房间列表
    ["35"] = "cluster.game.dsmgr.ready",    --准备
    ["36"] = "cluster.game.dsmgr.grab",     --抢庄
    ["37"] = "cluster.game.dsmgr.bet",      --押注(闲)
    ["38"] = "cluster.game.dsmgr.read",     --搓牌
    ["39"] = "cluster.game.dsmgr.show",     --亮牌
    ["40"] = "cluster.game.dsmgr.exitG",    --退出房间
    ["41"] = "cluster.game.dsmgr.getGPS",   --查看房间GPS
    ["42"] = "cluster.game.dsmgr.getVistors", --查看房间围观群众
    ["43"] = "cluster.game.dsmgr.matchSess",  --匹配房间
    ["44"] = "cluster.game.dsmgr.start",      --开始游戏
    ["45"] = "cluster.game.dsmgr.setBaseMult", --下注倍数
    ["46"] = "cluster.game.dsmgr.joinSubGame", --加入小游戏
    ["47"] = "cluster.game.dsmgr.exitSubGame", --退出小游戏
    ["48"] = "cluster.game.dsmgr.yaBao", --压宝
    ["49"] = "cluster.game.dsmgr.marry", --小玛丽

     -----------------------拉霸所有的免费游戏选参数走这条协议-----------------------------
    ["50"] = "cluster.game.dsmgr.selectFreeParam",  -- 选择免费游戏参数
    --["51"] = "cluster.game.dsmgr.selectTestResultCards",  -- 选择免费游戏参数
    ["52"] = "cluster.game.dsmgr.seatUp",
    ["53"] = "player.getNotice",   --获取系统消息
    -- ["57"] = "player.readMgs",       --读取消息
    ["54"] = "cluster.game.dsmgr.getDeskList",
    ["55"] = "cluster.game.dsmgr.changeDesk",
    ["56"] = "cluster.game.dsmgr.getSinDouDeskList",
    ["57"] = "cluster.game.dsmgr.deskUserHistory",       --读取消息
    

    ["58"] = "player.exitG",         --退出游戏
    ["59"] = "player.pushmsg",       --大厅获取跑马灯
    ["60"] = "cluster.game.dsmgr.getBaccaratDeskList",
    
    ["61"]  = "cluster.game.dsmgr.enterNiu",  --获取个人信息
    ["62"]  = "player.getUserInfo",  --获取个人信息
    ["63"]  = "cluster.game.dsmgr.leaveNiu",  --获取个人信息
    ["64"]  = "cluster.game.dsmgr.getNiuniuDeskList",  --获取个人信息
    ["65"]  = "cluster.game.dsmgr.dissolve",  --发起解散
    ["66"]  = "cluster.game.dsmgr.agreeDissolve",  --同意解散
    ["67"]  = "cluster.game.dsmgr.refuseDissolve",  --拒绝解散
    ["68"] = "cluster.game.dsmgr.getNiuniuDeskInfo",       --大厅获取跑马灯
    ["95"] = "cluster.game.dsmgr.shoufen", --水浒传
    ["96"] = "player.getVersion", --获取大厅版本号
    ["99"] = "relieffund.getreliffund", --大厅救济金领取
    ["100"] = "cluster.game.dsmgr.getDeskInfoClient",

    ["7100"] = "luckyredenvelopes.requestRedEnvelopes", --请求幸运红包
    ["7101"] = "luckyredenvelopes.getRedEnvelopes", -- 开启一个幸运红包
    ["7102"] = "luckyredenvelopes.getRedEnvelopesRain", --获取红包雨

    ------------------------ 银行功能 ------------------------
    ["108"] = "cluster.game.dsmgr.chooseLin", --游戏内快速取款
    ["112"] = "cluster.game.dsmgr.sendChatMsg",           --房间内聊天

    ["113"] = "cluster.game.dsmgr.getPlayerGameInfo",           --房间内聊天
    ["114"] = "cluster.game.dsmgr.setControl",           --设置开奖结果
    ["115"] = "cluster.game.dsmgr.openRedPackge",           --设置开奖结果
    
    -------------------evo真人视讯--------------------------------
    ["120"] = "cluster.game.dsmgr.matchSess",
    ["121"] = "cluster.game.dsmgr.exitG",    --退出房间
    ["122"] = "cluster.game.dsmgr.getSeatDeskInfo",    --退出房间
    ["123"] = "player.getRedSwitch",    --退出房间
    ["124"] = "player.bindMobile",    --绑定手机号
    

    ----------------成长系统----------
    ["130"] = "player.getGrowupData",
    ["131"] = "player.getGrowupDetail",
    ["132"] = "player.getGrowupGift",
    ["133"] = "player.getPayInfo",
    -- ["133"] = "player.testAddScore",

    ["135"] = "player.promoter", --推广员信息
    ["136"] = "player.changePayPasswd", --推广员修改支付密码
    ["137"] = "player.chargeCommission", --推广员提取佣金
    ["138"] = "player.chargeCommissionLog", --推广员提取佣金记录 
    ["139"] = "player.getRelationUser", --推广员获取上下级玩家
    ["140"] = "player.getTransfersLog", --推广员获取转账记录
    ["141"] = "player.vPPassword", --推广员转账前验证支付密码
    ["142"] = "player.transfer", --推广员转账
    ["143"] = "player.resetChildPassword", --推广员直接重置下级密码

    ["150"] = "player.collection", --玩家收藏或取消收藏单个游戏

    ["151"] = "player.envelopeRed", --玩家领红包后存起来
    ["152"] = "player.envelopeGet", --玩家提现红包
    ["153"] = "player.envelopeGetNotes", --玩家提现红包记录
    ["154"] = "player.envelopeNum", --玩家提现红包记录
    ["155"] = "bank.getBankAndCoin", ---登陆银行系统
    ["156"] = "bank.bankCash", ---银行存款
    ["157"] = "bank.bankDebits", ---银行取款
    ["158"] = "bank.alterBankPasswd", ---修改银行密码
    ["159"] = "bank.getBankActionInfo", ---获取银行存款操作记录
    ["160"] = "player.getShopInfo", ---获取银行信息
    ["161"] = "player.ipayOrder", ---下单
    ["163"] = "player.gpsUpdate", --- gps更新
    ["164"] = "player.sendMobileCode", --- 发送验证码
    ["165"] = "player.getRecordBigInfo", --- 获取大战绩
    ["166"] = "player.getRecordSmallInfo", --- 获取战绩详情
    ["167"] = "cluster.game.dsmgr.baojin", --- 报警
    ["168"] = "cluster.game.dsmgr.backClubHall", --- 切换到大厅
    
    ---------------------------------
--[[
    --暂时无用
    ------------------------ 梭哈 特有 ------------------------
    ["51"] = "cluster.game.dsmgr.giveup", --弃牌
    ["52"] = "cluster.game.dsmgr.pass",   --过
    ["53"] = "cluster.game.dsmgr.suoha",  --梭哈
    ["54"] = "cluster.game.dsmgr.follow", --跟注
    ["55"] = "cluster.game.dsmgr.fill",   --加注
]]
    ------------------------ 百人牛牛 ------------------------
    ["600"] = "cluster.game.dsmgr.matchSess",           --匹配房间
    ["601"] = "cluster.game.dsmgr.applyOnBanker",       --申请上庄
    ["602"] = "cluster.game.dsmgr.cancelOnBanker",      --取消申请上庄
    ["603"] = "cluster.game.dsmgr.applyOffBanker",      --申请下庄
    ["604"] = "cluster.game.dsmgr.exitG",               --退出房间
    ["605"] = "cluster.game.dsmgr.bet",                 --玩家押注
    ["606"] = "cluster.game.dsmgr.trend",               --走势图
    ["607"] = "cluster.game.dsmgr.players",             --玩家列表
    ["608"] = "cluster.game.dsmgr.conbet",              --玩家续押
    ["609"] = "cluster.game.dsmgr.getGameUserList",             --玩家列表

    ["801"] = "cluster.game.dsmgr.deltel",              --解散房间
    ["803"] = "cluster.game.dsmgr.vote",                --解散投票
    ["804"] = "cluster.game.dsmgr.putCard",             --出牌
    ["805"] = "cluster.game.dsmgr.passCard",            --弃牌

    ["901"] = "cluster.game.dsmgr.seatDown",            --坐下
    ["902"] = "cluster.game.dsmgr.dealerStart",         --庄家开始游戏
    ["903"] = "cluster.game.dsmgr.twist",               --一键配牌
    ["904"] = "cluster.game.dsmgr.showCard",            --摊牌
    ["905"] = "cluster.game.dsmgr.quickSeatDown",            --快速坐下
    ["READ_DESK_GPS"] = "cluster.game.dsmgr.getGPS", --查看房间GPS


    ["THREE_READ_READY"] = "cluster.game.dsmgr.read",   --炸金花看牌
    ["THREE_GIVEUP_CARD"]= "cluster.game.dsmgr.giveup", --炸金花弃牌
    ["THREE_BET_CARD"]   = "cluster.game.dsmgr.bet",    --跟注或下注
    ["THREE_PK_CARD"]    = "cluster.game.dsmgr.pk",     --pk

    ["BULL_GRAB_BANKER"] = "cluster.game.dsmgr.grab", --牛牛抢庄
    ["BULL_BET_CARD"]    = "cluster.game.dsmgr.bet",  --闲押注
    ["BULL_READ_CARD"]   = "cluster.game.dsmgr.read", --搓牌
    ["BULL_SHOW_CARD"]     = "cluster.game.dsmgr.pk",   --亮牌

    ["PDK_OUTPUT_CARD"] = "cluster.game.dsmgr.output", --跑得快出牌

    --5张--
    ["FIVE_GIVEUP_CARD"] = "cluster.game.dsmgr.giveup", --弃牌

    ------------------------ 红黑大战 ------------------------
    ["1020"] = "cluster.game.dsmgr.matchSess",           --匹配房间
    ["1021"] = "cluster.game.dsmgr.exitG",               --退出房间
    ["1023"] = "cluster.game.dsmgr.bet",                 --玩家押注
    ["1024"] = "cluster.game.dsmgr.trend",               --走势图
    ["1025"] = "cluster.game.dsmgr.players",             --玩家列表

    ------------------------ 龙虎斗 ------------------------
    ["501"] = "cluster.game.dsmgr.matchSess",           --匹配房间
    ["502"] = "cluster.game.dsmgr.exitG",               --退出房间
    ["503"] = "cluster.game.dsmgr.bet",                 --玩家押注
    ["504"] = "cluster.game.dsmgr.trend",               --走势图
    ["505"] = "cluster.game.dsmgr.players",             --玩家列表

    ------------------------ 猜拳 ------------------------------
    ["1101"] = "cluster.game.dsmgr.setBaseScore",             --庄家设置底分
    ["1102"] = "cluster.game.dsmgr.action",             --操作结果
    ["1103"] = "cluster.game.dsmgr.kick",             --踢出玩家
    ["1104"] = "cluster.game.dsmgr.dealerStart",      --房主开始

    ------------------------ 奔驰宝马 ------------------------
    ["1300"] = "cluster.game.dsmgr.matchSess",           --匹配房间
    ["1301"] = "cluster.game.dsmgr.applyOnBanker",       --申请上庄
    ["1302"] = "cluster.game.dsmgr.cancelOnBanker",      --取消申请上庄
    ["1303"] = "cluster.game.dsmgr.applyOffBanker",      --申请下庄
    ["1304"] = "cluster.game.dsmgr.exitG",               --退出房间
    ["1305"] = "cluster.game.dsmgr.bet",                 --玩家押注
    ["1306"] = "cluster.game.dsmgr.trend",               --走势图
    ["1307"] = "cluster.game.dsmgr.players",             --玩家列表
    ["1308"] = "cluster.game.dsmgr.conbet",              --玩家续押
    ["1309"] = "cluster.game.dsmgr.queryRank",            --查询我在上庄队列中排名

    ------------------------ 二人麻将 ------------------------
    ["1401"] = "cluster.game.dsmgr.put",           --出牌操作
    ["1402"] = "cluster.game.dsmgr.draw",           --摸牌操作
    ["1403"] = "cluster.game.dsmgr.peng",           --碰牌操作
    ["1404"] = "cluster.game.dsmgr.gang",           --杠牌操作
    ["1405"] = "cluster.game.dsmgr.hupai",           --胡牌牌操作
    ["1407"] = "cluster.game.dsmgr.pass",           --过牌操作
    ["1408"] = "cluster.game.dsmgr.cancelAuto",           --取消托管
    ["1409"] = "cluster.game.dsmgr.chiPai",           --吃
    ["1410"] = "cluster.game.dsmgr.pdkPutCard",           --出牌操作
    ------------------------ 通比牛牛 ------------------------
    ["2201"] = "cluster.game.dsmgr.matchSess",           --匹配房间
    ["2202"] = "cluster.game.dsmgr.exitG",               --退出房间
    ["2203"] = "cluster.game.dsmgr.ready",               --准备开始
    ["2205"] = "cluster.game.dsmgr.show",                --摊牌
    ["2206"] = "cluster.game.dsmgr.entrust",             --玩家托管

        ------------------------ 梭哈 特有 ------------------------
    ["43"] = "cluster.game.dsmgr.matchSess",           --匹配房间
    ["35"] = "cluster.game.dsmgr.ready",               --准备
    ["2102"] = "cluster.game.dsmgr.giveup",              --弃牌
    ["2103"] = "cluster.game.dsmgr.pass",                --过
    ["2104"] = "cluster.game.dsmgr.allin",               --全押
    ["2105"] = "cluster.game.dsmgr.follow",              --跟注
    ["2106"] = "cluster.game.dsmgr.fill",                --加注
    ["2107"] = "cluster.game.dsmgr.seeCard",            --看牌

    ----------------------- 百家乐 ------------------------------
    ["43"] = "cluster.game.dsmgr.matchSess",           --匹配房间
    ["1601"] = "cluster.game.dsmgr.bet",               --下注
    ["1602"] = "cluster.game.dsmgr.applyBuck",         --申请上庄
    ["1603"] = "cluster.game.dsmgr.repealBuck",        --申请下庄

    ----------------------- 777百家乐 ------------------------------
    ["20101"] = "cluster.game.dsmgr.bet",               --下注
    ["20103"] = "cluster.game.dsmgr.trend",             --趋势

    ----------------------- 777霹雳猴 ------------------------------
    ["20201"] = "cluster.game.dsmgr.getnewinfo",               --新开一局
    ["20202"] = "cluster.game.dsmgr.bet",               --下注

    ----------------------- 777西游争霸 ------------------------------
    ["20301"] = "cluster.game.dsmgr.getnewinfo",               --新开一局
    ["20302"] = "cluster.game.dsmgr.bet",               --下注

    ----------------------- 777奔驰宝马 ------------------------------
    ["20501"] = "cluster.game.dsmgr.getnewinfo",               --新开一局
    ["20502"] = "cluster.game.dsmgr.bet",               --下注

    ----------------------- 777龙虎斗 ------------------------------
    ["20601"] = "cluster.game.dsmgr.bet",               --下注
    ["20602"] = "cluster.game.dsmgr.trend",             --趋势

    ----------------------- 777英超联赛 ------------------------------
    ["20701"] = "cluster.game.dsmgr.getnewinfo",         --新开一局
    ["20702"] = "cluster.game.dsmgr.bet",               --下注
    ----------------------- 鱼虾耗 ------------------------------
    ["2041"] = "cluster.game.dsmgr.settleForRound",      --当局结算

    ----------------------- 伟大的蓝色------------------------------
    ["1031"] = "cluster.game.dsmgr.chooseShellBet", --伟大的蓝色，选择贝壳
    ----------------------- 三国------------------------------
    ["1091"] = "cluster.game.dsmgr.sgFreeGame", --三国，免费游戏
     ----------------------- 金莲花------------------------------
    ["1111"] = "cluster.game.dsmgr.chooseLotusFlower", --金莲花，选择莲花
    ----------------------- 水果slots------------------------------
    ["1201"] = "cluster.game.dsmgr.setMaxBet", --水果slot设置最大的倍率，压线和倍率都会被设置到最大

    ["1112"] = "cluster.game.dsmgr.actionSubGame", --具体小游戏操作

    ["1113"] = "cluster.game.dsmgr.AllInCoin",
    ["1114"] = "cluster.game.dsmgr.selectFree",

    ---------------------- 捕鱼 ---------------------------------
    ["2401"] = "cluster.game.dsmgr.matchSess",          --匹配房间
    ["2402"] = "cluster.game.dsmgr.fire",               --玩家发射
    ["2403"] = "cluster.game.dsmgr.catch",              --玩家捕获
    ["2404"] = "cluster.game.dsmgr.ionEnd",             --离子炮结束
    ["2405"] = "cluster.game.dsmgr.bomb",               --炸弹
    ["2406"] = "cluster.game.dsmgr.luckdraw",           --抽奖
    
    ----------------------- 777 21点 ------------------------------
    ["21002"] = "cluster.game.dsmgr.bet",              --下注发牌
    ["21003"] = "cluster.game.dsmgr.split",            --拆牌
    ["21004"] = "cluster.game.dsmgr.surrender",             --投降
    ["21005"] = "cluster.game.dsmgr.addcard",          --要牌
    ["21006"] = "cluster.game.dsmgr.open",             --开牌
    ["21007"] = "cluster.game.dsmgr.double",           --加倍
    ["21008"] = "cluster.game.dsmgr.safe",             --保险
    ["21009"] = "cluster.game.dsmgr.jumpsafe",         --跳过保险
    ["21010"] = "cluster.game.dsmgr.newgame",          --新游戏
    ["21011"] = "cluster.game.dsmgr.stop",             --停牌

     ----------------------- 777 俄罗斯轮盘 ------------------------------
    ["20901"] = "cluster.game.dsmgr.bet",               --下注

     -----------------------777 经典水果机 ------------------------------
    ["21301"] = "cluster.game.dsmgr.start",
    ["21302"] = "cluster.game.dsmgr.betdaxiao",
    ["21303"] = "cluster.game.dsmgr.getscore",
    ["20902"] = "cluster.game.dsmgr.state",             --时间状态

    -----------------------777 豹子王 ------------------------------
    ["21401"] = "cluster.game.dsmgr.bet",
    ["21402"] = "cluster.game.dsmgr.state",             --时间状态

     -----------------------绝地求生 ------------------------------
    ["21501"] = "cluster.game.dsmgr.setTotalBet",
    ["21502"] = "cluster.game.dsmgr.start",
    ["21504"] = "cluster.game.dsmgr.chiji",

    -------------------------777 飞禽走兽----------
    ["120801"] = "cluster.game.dsmgr.bet",

    ----------------------- 777 葫芦机 ------------------------------
    ["21601"] = "cluster.game.dsmgr.hlj_start",   

    
    ----------------------- 777西游争霸在线类 ------------------------------
    ["22201"] = "cluster.game.dsmgr.bet",               --下注

    ----------------------- 战无不胜在线类 ------------------------------
    ["24501"] = "cluster.game.dsmgr.bet",               --下注

    ----------------------- 猜大小在线类 ------------------------------
    ["24601"] = "cluster.game.dsmgr.bet",               --下注
    ["24602"] = "cluster.game.dsmgr.trend",             --趋势

     ----五龙
    ["21701"] = "cluster.game.dsmgr.start",
    ["21702"] = "cluster.game.dsmgr.selectFree",

     ----------------------- 龙虎斗1 2 3 客户端那边不做区分 所以服务器这边都走这一个协议单机类 ------------------------------
    ["22601"] = "cluster.game.dsmgr.bet",               --下注
    
    ----五龙
    ["23801"] = "cluster.game.dsmgr.start",
    ["23802"] = "cluster.game.dsmgr.selectFree",
    
    ----------------------- 赛摩托车/赛马918下注 ------------------------------
    ["23601"] = "cluster.game.dsmgr.bet",               --下注
    ["23602"] = "cluster.game.dsmgr.getnewinfo",               --开启新一局

    -----------------------豹子王单机 ------------------------------
    ["22901"] = "cluster.game.dsmgr.bet",

    -----------------------新奔驰宝马单机 ------------------------------
    ["23701"] = "cluster.game.dsmgr.bet",--下注
    ["23702"] = "cluster.game.dsmgr.getnewinfo",--开启新一局

    -----------------------百家乐单机 ------------------------------
    ["23001"] = "cluster.game.dsmgr.bet",--下注
    ["23002"] = "cluster.game.dsmgr.trend",--下注

    -----------------------三卡扑克单机 ------------------------------
    ["23101"] = "cluster.game.dsmgr.bet",--下注
    ["23102"] = "cluster.game.dsmgr.choose",--玩家选择操作

    -----------------------牛牛单机 ------------------------------
    ["23401"] = "cluster.game.dsmgr.bet",--下注


    -----------------------单挑------------------------------
    ["23501"] = "cluster.game.dsmgr.start",--开始游戏
    
    -----------------------赌场单机 ------------------------------
    ["23201"] = "cluster.game.dsmgr.bet",--下注
    ["23202"] = "cluster.game.dsmgr.choose",--玩家选择操作

    -----------------------赌场战争扑克单机 ------------------------------
    ["23301"] = "cluster.game.dsmgr.bet",--下注
    ["23302"] = "cluster.game.dsmgr.choose",--玩家选择操作

    -----------------------俄罗斯轮盘24单机 ------------------------------
    ["22401"] = "cluster.game.dsmgr.bet",--下注

    -----------------------俄罗斯轮盘36单机 ------------------------------
    ["23901"] = "cluster.game.dsmgr.bet",--下注

    -----------------------俄罗斯轮盘mini单机 ------------------------------
    ["22301"] = "cluster.game.dsmgr.bet",--下注

    -----------------------俄罗斯轮盘72单机 ------------------------------
    ["22501"] = "cluster.game.dsmgr.bet",--下注

    ----------------------- 918西游争霸 ------------------------------
    ["24001"] = "cluster.game.dsmgr.getnewinfo",               --新开一局
    ["24002"] = "cluster.game.dsmgr.bet",               --下注

    ----------------------- 918战无不胜 ------------------------------
    ["24101"] = "cluster.game.dsmgr.getnewinfo",               --新开一局
    ["24102"] = "cluster.game.dsmgr.bet",               --下注

    -----------------------918 经典水果机 ------------------------------
    ["24201"] = "cluster.game.dsmgr.start",
    ["24202"] = "cluster.game.dsmgr.betdaxiao",
    ["24203"] = "cluster.game.dsmgr.getscore",


    ----------------------新游戏----------
    ["8801"] = "cluster.clubs.clubsaction.createCulb",--创建俱乐部
    ["8802"] = "cluster.clubs.clubsaction.applyCulb",--申请加入俱乐部
    ["8803"] = "cluster.clubs.clubsaction.agreeCulb",--同意加入俱乐部
    ["8804"] = "cluster.clubs.clubsmgr.getClubeOnlineUsers",--获取俱乐部在线玩家
    ["8805"] = "cluster.clubs.clubsmgr.addGame",--俱乐部创建游戏
    ["8806"] = "cluster.clubs.clubsmgr.deleteDesk",--删除俱乐部游戏
    ["8807"] = "cluster.clubs.clubsmgr.joinCulb",--进入俱乐部
    ["8808"] = "cluster.clubs.clubsmgr.getClubList",--获取俱乐部列表
    ["8809"] = "cluster.clubs.clubsaction.getApplyListCulb",--获取俱乐部申请列表
    ["8810"] = "cluster.clubs.clubsaction.allAgreeCulb",--全部同意加入俱乐部
    ["8811"] = "cluster.clubs.clubsaction.refuseCulb",--拒绝加入俱乐部

    ["8812"] = "cluster.clubs.clubsmgr.hallSeatDown",--俱乐部大厅中坐下
    ["8813"] = "cluster.game.dsmgr.getLocatingList",--获取定位数据

    
    ["8814"] = "cluster.clubs.clubsaction.freezeCulb",--冻结俱乐部
    ["8815"] = "cluster.clubs.clubsaction.dissolveCulb",--解散俱乐部

    ["8816"] = "cluster.clubs.clubsaction.exitCulb",  --退出俱乐部
    ["8817"] = "cluster.clubs.clubsaction.getExitListCulb",--获取俱乐部申请退出列表
    ["8818"] = "cluster.clubs.clubsaction.refuseExitCulb",--拒绝退出俱乐部
    ["8819"] = "cluster.clubs.clubsaction.allExitCulb",--全部同意退出俱乐部
    ["8820"] = "cluster.clubs.clubsaction.agreeExitCulb",--同意退出俱乐部
    ["8821"] = "cluster.clubs.clubsaction.getClubMember",--获取俱乐部成员列表
    ["8822"] = "cluster.clubs.clubsaction.kickClub",--踢出俱乐部
    ["8823"] = "cluster.clubs.clubsaction.backHall",--从俱乐部返回大厅
    
    
    
    

}

PDEFINE_MSG.NOTIFY =
{
    msg     = 1001, --新邮件，消息，跑马灯通知
    online  = 1002, --上线通知指令
    join    = 1003, --加入房间
    sitdown = 1004, --坐下
    ready   = 1005, --准备
    start   = 1006, --开始
    sendcard= 1007, --发牌
    grab    = 1008, --抢庄
    banker  = 1009, --庄家来了
    coin    = 1010, --玩家金币减少
    show    = 1011, --玩家亮牌
    blance  = 1012, --一局结算
    leave    = 1013, --有人离开房间  围观群众离开
    bet     = 1014, --有人押注
    betfinish = 1015, --全部现家押注完
    exit      = 1016, --玩家离开
    otherlogin = 1017,--你的账号已在其它设备上登陆
    deskstate  = 1018,--桌子状态变化
    senddissolve  = 1019,--发起解散
    agreedissolve = 1020,--同意解散
    refusedissolve = 1021,--拒绝解散
    bigblance  = 1022, --大结算
    succeddissolve  = 1023, --成功解散
    choosebanker  = 1024, --取消解散
    downcards   = 1025, --放牌
    -- 梭哈
    giveup     = 1030, --有人弃牌
    nextaction = 1031, --下一个人说话
    pass       = 1032, --过
    follow     = 1033, --跟注
    fill       = 1034, --加注

    BUY_OK = 1035, --购买成功
    REWARD_ONLINE = 1036,-- 在线奖励通知
    UQEST_DONE = 1037,--任务有完成
    REWARD_PRAISE = 1038,-- 可以好评了
    NOTIFY_USER_STATE = 1039,--通知玩家状态发生变化
    MUST_RESTART = 801, --必须重启
    NOTIFY_NOTICE_ALL_NOTICE = 100049,
    ALL_GET_OUT = 100050, --后台API 解散房间 T回大厅
    NOTIFY_NOTICE_HALL = 100051, --大厅推送消息
    NOTIFY_NOTICE_GAME = 100052, --游戏跑马灯消息
    NOTIFY_MAIL = 100053,     --邮件通知
    NOTIFY_SYS_KICK = 100054, --系统T掉某个人 T到登录界面
    NOTIFY_NOTICE_ALL = 100055, --全服推送
    NOTIFY_CAHT_ALL = 100056, --全服推送chat
    NOTIFY_USER_INFO = 100057, --玩家信息更新

    
    NOTIFY_LEVEL_INFO    = 100058, --段位信息配置变化
    NOTIFY_GAMELIST_INFO = 100059, --子游戏状态更新
    NOTIFY_BIGBANG       = 100060, --bigbang更新
    NOTIFY_RELOGIN       = 100061, --通知客户端重新走一遍登录
    NOTIFY_DESKUSER_INFO = 100062, --通知客户端更新游戏内的玩家信息

    --牛牛
    NOTIFY_BULL_ROOM_SHOP        = 100201, --房间内，金币不够弹出商城框

    --百人牛牛
    NOTIFY_HBULL_START           = 100600, --开始游戏
    NOTIFY_HBULL_START_BET       = 100601, --开始下注
    NOTIFY_HBULL_CHANGE_BANKER   = 100603, --换庄
    NOTIFY_HBULL_EXIT_ROOM       = 100604, --座位玩家退出房间
    NOTIFY_HBULL_CHANGE_DESKINFO = 100605, --更新桌子信息
    NOTIFY_HBULL_EXIT_QUEUE      = 100606, --被退出上庄队列

    NOTIFY_HBULL_ONLINE          = 100610, --上线或下线
    NOTIFY_HBULL_STOP_BET        = 100611, --停止下注
    NOTIFY_HBULL_OPEN_CARD       = 100612, --开牌
    NOTIFY_HBULL_OVER_GAME       = 100613, --结算
    NOTIFY_HBULL_CHANGE_SEAT     = 100614, --房间座位人员信息变更
    NOTIFY_HBULL_EXIT            = 100615, --房间掉线后 定时T出去
    NOTIFY_HBULL_TIME_FREE       = 100616, --空闲时间


    NOTIFY_READY = 2000, --准备通知
    NOTIFY_PUT_CARD = 2001,--出牌通知
    NOTIFY_PASS_CARD = 2002,--通知弃牌
    NOTIFY_NO_READY_DELTE_GAME = 2003, --游戏未开始房主直接解散
    NOTIFY_READY_DELTE_GAME = 2004,     --游戏开始发起解散
    NOTIFY_VOTE = 2005,                 --投票解散
    NOTIFY_CHAT = 2006,                 --聊天通知
    ROUND_OVER = 2007,                   --小结算
    ROOM_OVER = 2008,                   --大结算
    NOTIFY_ONLINE = 2009,               --在线或者离线通知

    NOTIFY_ROOM_CHAT = 100112,          --聊天通知
    --牛牛
    NOTIFY_BULL_CHAT            = 100202, --房间内聊天

    --8张13水
    NOTIFY_SEAT_DOWN = 100901,               --通知坐下
    NOTIFY_DEALER_START = 100902,               --通知庄家点开始
    NOTIFY_SHOW_CARDS = 100904,               --通知摊牌
    NOTIFY_BALANCE = 100905,               --通知结算
    NOTIFY_KICK = 100906,             --踢掉不准备玩家
    NOTIFY_READY_AUTO_TIME = 100907,             --通知玩家准备剩余时间
    NOTIFY_SEAT_UP = 100908,               --通知坐下
    --猜拳
    NOTIFY_SET_BASESCORE = 101101,      --通知设置底分
    NOTIFY_FGR_ACTION = 101102,       --通知操作结果
    NOTIFY_DEALER_KICK = 101103,               --提出玩家
    NOTIFY_READY_DEALER_START = 101104,       --通知庄家对方已准备并弹出开始按钮
    NOTIFY_FGR_START = 101105,       --通知游戏开始
    NOTIFY_FGR_OVER = 101106,               --游戏结束
    NOTIFY_DEALER_OVER = 101107,               --房主解散游戏

    --红黑大战 百人炸金花
    NOTIFY_REDB_START           = 101000, --开始游戏 vs
    NOTIFY_REDB_START_BET       = 101001, --开始下注
    NOTIFY_REDB_STOP_BET        = 101002, --停止下注
    NOTIFY_REDB_OPEN_CARD       = 101003, --开牌
    NOTIFY_REDB_OVER_GAME       = 101004, --结算信息
    NOTIFY_REDB_CHANGE_DESKINFO = 101005, --更新桌子信息
    NOTIFY_REDB_EXIT_ROOM       = 101006, --座位玩家退出房间 广播
    NOTIFY_REDB_EXIT            = 101007, --房间掉线后 定时T出去 只发给被T的人
    NOTIFY_REDB_CHANGE_SEAT     = 101008, --房间座位人员信息变更
    NOTIFY_REDB_ONLINE          = 101010, --上线或下线

    --龙虎斗
    NOTIFY_TIGER_START           = 100500, --开始游戏 vs
    NOTIFY_TIGER_START_BET       = 100501, --开始下注
    NOTIFY_TIGER_STOP_BET        = 100502, --停止下注
    --NOTIFY_TIGER_OPEN_CARD       = 100503, --开牌
    NOTIFY_TIGER_OVER_GAME       = 100504, --结算信息
    NOTIFY_TIGER_CHANGE_DESKINFO = 100505, --更新桌子信息
    NOTIFY_TIGER_EXIT_ROOM       = 100506, --座位玩家退出房间 广播
    NOTIFY_TIGER_EXIT            = 100507, --房间掉线后 定时T出去 只发给被T的人
    NOTIFY_TIGER_CHANGE_SEAT     = 100508, --房间座位人员信息变更
    NOTIFY_TIGER_ONLINE          = 100509, --上线或下线
    NOTIFY_TIGER_MANAGE_CHANGE_DESKINFO = 100510, --管理员收到的下注信息

    --奔驰宝马
    NOTIFY_BENZ_START_BET       = 101301, --开始下注
    NOTIFY_BENZ_CHANGE_BANKER   = 101303, --换庄
    NOTIFY_BENZ_APPLY_BANKER    = 101304, --有人申请庄
    NOTIFY_BENZ_CHANGE_DESKINFO = 101305, --有人下注
    NOTIFY_BENZ_CONBET_DESKINFO = 101306, --有人下注
    NOTIFY_BENZ_STOP_BET        = 101311, --停止下注
    NOTIFY_BENZ_OVER_GAME       = 101312, --结算
    NOTIFY_BENZ_CHANGE_PLAYERS  = 101313, --玩家人数修改
    NOTIFY_BENZ_EXIT            = 101315, --房间掉线后 定时T出去
    NOTIFY_BENZ_TIME_FREE       = 101316, --空闲时间
    NOTIFY_BENZ_RANK_BANKER       = 101317, --上庄列表排名
    --红中麻将
    NOTIFY_HZ_SHOW_ACTION          = 101400, --通知玩家显示出碰或者杠或者胡牌的按钮
    NOTIFY_HZ_PUT          = 101401, --通知玩家出牌
    NOTIFY_HZ_DRAW          = 101402, --通知玩家摸排
    NOTIFY_HZ_PENG          = 101403, --通知玩家碰牌
    NOTIFY_HZ_GANG          = 101404, --通知玩家杠牌
    NOTIFY_HZ_HUPAI          = 101405, --通知玩家胡牌
    NOTIFY_HZ_PUT_ERROR          = 101406, --出牌错误回收打出去的牌
    NOTIFY_HZ_LIUJU         = 101407, --流局通知
    NOTIFY_HZ_PASS         = 101408, --通知过牌
    NOTIFY_HZ_CANCE        = 101409,--取消托管
    NOTIFY_HZ_CHI          = 101410, --通知玩家吃

    NOTIFY_HZ_PAO             = 101411, --通知玩家跑起
    NOTIFY_HZ_KAN             = 101412, --通知玩家扫
    NOTIFY_HZ_TILONG          = 101413, --通知玩家踢龙
    NOTIFY_HZ_DRAW_PUT          = 101414, --通知玩家摸打
    NOTIFY_HZ_OVER =           101415,--大结算
    NOTIFY_HZ_DEL_HAND_CARD        = 101416,--通知删除手牌
    NOTIFY_HZ_PUT_PDK          = 101417, --通知玩家出牌

    --通比牛牛
    NOTIFY_TBNN_START           = 102200, --开局
    NOTIFY_TBNN_SITDOWN         = 102201, --有玩家坐下
    NOTIFY_TBNN_EXIT            = 102202, --有玩家退出房间
    NOTIFY_TBNN_READY           = 102203, --有玩家点了开始
    NOTIFY_TBNN_SEND_CARD       = 102204, --发牌
    NOTIFY_TBNN_SHOW_CARD       = 102205, --开牌
    NOTIFY_TBNN_OVER_GAME       = 102207, --结算信息
    NOTIFY_TBNN_ONLINE          = 102208, --上线或下线
    NOTIFY_TBNN_CHAT            = 102209, --房间内聊天

        --梭哈
    NOTIFY_STUD_JOIN       = 1003, --通知有玩家进入房间
    NOTIFY_STUD_KICK       = 100906, --踢出不准备的玩家
    NOTIFY_STUD_READY      = 2000, --准备 
    NOTIFY_STUD_START      = 1006, --通知游戏开始
    NOTIFY_STUD_GIVEUP     = 103004, --弃牌
    NOTIFY_STUD_PASS       = 103005, --过
    NOTIFY_STUD_FOLLOW     = 103006, --跟注
    NOTIFY_STUD_FILL       = 103007, --加注
    NOTIFY_STUD_ALLIN      = 103008, --全押
    NOTIFY_STUD_BALANCE    = 1012, --通知结算
    NOTIFY_STUD_SENDCARD   = 1007, --发牌
    NOTIFY_STUD_EXIT       = 1016, --通知有玩家退出房间
    NOTIFY_STUD_SEECARD    = 103009,--通知看牌

        --百家乐
    NOTIFY_BACCARA_JOIN          = 1003, --通知有玩家进入房间
    NOTIFY_BACCARA_START         = 104000, --通知游戏开始
    NOTIFY_BACCARA_START_BET     = 104001, --通知玩家开始下注
    NOTIFY_BACCARA_STOP_BET      = 104002, --通知玩家停止下注
    NOTIFY_BACCARA_BET           = 104003, --通知下注
    NOTIFY_BACCARA_APPLY_BUCK    = 104005,--通知上庄 
    NOTIFY_BACCARA_REPEAL_BUCK   = 104006,--通知下庄

    -------- 777 百家乐 --------
    BACCARAT_START           = 120101, --开始游戏
    BACCARAT_CHANGE_DESKINFO = 120102, --有人下注更新桌子信息
    BACCARAT_OVER_GAME       = 120103,  --结算
    BACCARAT_TIME_FREE       = 120104, --空闲时间

    -------- 777西游争霸 ------
    MONKEYSTORY_GOLD       = 120301, --同步彩金

    -------- 777 龙虎斗 --------
    DRAGONTIGER_START           = 120601, --开始游戏
    DRAGONTIGER_CHANGE_DESKINFO = 120602, --有人下注更新桌子信息
    DRAGONTIGER_OVER_GAME       = 120603, --结算
    DRAGONTIGER_TIME_FREE       = 120604, --空闲时间

    -------- 777 俄罗斯轮盘 --------
    ROULETTE_START           = 120901, --开始游戏
    ROULETTE_CHANGE_DESKINFO = 120902, --有人下注更新桌子信息
    ROULETTE_OVER_GAME      = 120903, --结算

    -- 捕鱼
    NOTIFY_FISH_JOIN        = 1003, --通知有玩家进入房间
    NOTIFY_FISH_EXIT        = 1016, --通知有玩家退出房间
    NOTIFY_FISH_ADD_FISH    = 102405, --增加鱼
    NOTIFY_FISH_SWITCH_SNENE= 102406, --切换场景
    NOTIFY_FISH_TIDE        = 102407, --鱼潮
    NOTIFY_FISH_STATE       = 102408, --房间状态
    NOTIFY_FISH_PROG        = 102409, --鱼的击杀进度
    NOTIFY_FISH_EVENT       = 102410, --捕鱼特定事件通知

    -------- 777 百家乐 --------
    
    BEASTS_CHANGE_DESKINFO = 120802, --有人下注更新桌子信息
    BEASTS_OVER_GAME       = 120803,  --结算
    BEASTS_TIME_FREE       = 120804, --空闲时间
    BEASTS_START_BET       = 120805, --开始下注
    BEASTS_STOP_BET        = 120806, --停止下注
    -------- 777 豹子王 --------
    GODOFWEALTH_START           = 121401, --开始游戏
    GODOFWEALTH_CHANGE_DESKINFO = 121402, --有人下注更新桌子信息
    GODOFWEALTH_OVER_GAME       = 121403, --结算
    -------- 777英超联赛 ------
    PREMIER_GOLD       = 121201, --同步彩金
    JACKPOT_HALL_GOLD       = 121202, --通知大厅奖金池
    JACKPOT_GAME_GOLD       = 121203, --通知游戏奖金池

    -------- 777 西游争霸在线类 --------
    MONKEYSTORYONLINE_START           = 122201, --开始游戏
    MONKEYSTORYONLINE_CHANGE_DESKINFO = 122202, --有人下注更新桌子信息
    MONKEYSTORYONLINE_OVER_GAME       = 122203, --结算
    MONKEYSTORYONLINE_TIME_FREE       = 122204, --空闲时间

    
    -------- 战无不胜在线类 --------
    INVINCIBLE_ONLINE_START           = 125301, --开始游戏
    INVINCIBLE_ONLINE_CHANGE_DESKINFO = 125302, --有人下注更新桌子信息
    INVINCIBLE_ONLINE_OVER_GAME       = 125303, --结算
    INVINCIBLE_ONLINE_TIME_FREE       = 125304, --空闲时间

    -------- 猜大小 --------
    GUESSBIGSMALL_START           = 124601, --开始游戏
    GUESSBIGSMALL_CHANGE_DESKINFO = 124602, --有人下注更新桌子信息
    GUESSBIGSMALL_OVER_GAME       = 124603, --结算
    GUESSBIGSMALL_TIME_FREE       = 124604, --空闲时间

    -- slot类型
    SLOT_SELECT_FREE = 11130,


    NOTY_GET_CLUB_LIST= 18803,
    NOTY_CLUB_ADD_DESK= 18804,
    NOTY_CLUB_DESK_CHANGE = 18805,
    NOTY_CLUB_DESK_READY = 18806, --通知俱乐部桌子玩家准备状态
    NOTY_CLUB_DESK_ROUND = 18807,
    NOTY_CLUB_DEL_DESK = 18808,
    NOTIFY_GPS_UPDATE = 18809,
    NOTY_CLUB_DISSOLVE = 18810,  --通知俱乐部解散
    NOTY_CLUB_FREEZE = 18811,   --通知俱乐部冻结或解冻
    NOTY_APPLY_EXIT_CLUB = 18812,   --通知有人申请退出
    NOTY_CLUB_ROUND_CHANGE = 18813, --通知俱乐部大厅桌子局数变动
    NOTY_ZHADAN_SCORE_CHANGE = 18814, --打炸弹时通知积分变动

    NOTY_UPDATE_DESKINFO = 18815,--通知桌子信息
}

return PDEFINE_MSG