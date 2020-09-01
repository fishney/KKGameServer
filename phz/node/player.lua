local skynet = require "skynet"
local cluster = require "cluster"
local date = require "date"
local cjson = require "cjson"
local jsondecode = cjson.decode
local md5 = require "md5"
local snax = require "snax"
local api_service = require "api_service"
local player_tool = require "base.player_tool"
cjson.encode_sparse_array(true)
local player = {}
local handle
local UID
local SEND_COIN = 0 --初始账号赠送金币
local report_service = require "report_service"
local webclient = nil
local playerdatamgr = require "datacenter.playerdatamgr"
local game_tool = require "game_tool"
local growup_tool = require "growup_tool"

local APP = skynet.getenv("app") or 1
APP = tonumber(APP)

local lastfeedbacktime = 0
local eli30score = 0

--30天输赢分数(猜拳使用)
function player.getEli30score()
    return eli30score
end

function player.updateEli30score(addeli30score)
    eli30score = eli30score + addeli30score
end

function player.bind(agent_handle)
    handle = agent_handle
end

function player.heartBeat(recvobj)
    return PDEFINE.RET.SUCCESS
end

--成功返回
local function resp(retobj)
    return PDEFINE.RET.SUCCESS, cjson.encode(retobj)
end

-------- 生成密码 ------
local function genPasswd(str)
    return md5.sumhexa(str)
end

--libs 游戏排序 ord大的排前面
local function sortByOrd(a, b)
    if nil == a.ord then
        return false
    end

    return a.ord > b.ord
end

local function getip(clientIP)
    if nil == clientIP or #clientIP==0 then
        return ""
    end
    local tmp = string.split(clientIP, ":")
    return tmp[1]
end

-- 创建角色
function player.create(message, agent, clientIP)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " player.create get message data: ", message)
    local recvobj = cjson.decode(message)
    local uid = math.floor(recvobj.uid)
    local cmd = math.floor(recvobj.c)
    local code, playerInfo = playerdatamgr.create(uid, clientIP)
    if code ~= true then
        return code
    end
    skynet.call(agent, "lua", "create")
    --更新account用户表 注册账号完成
    pcall(cluster.call, "login", ".accountdata", "set_account_item",uid, "status", 1)
    return playerInfo
end

--大厅版本号
function player.getVersion(msg)
    local recvobj = cjson.decode(msg)
    local retobj = {}
    retobj.c     = math.floor(recvobj.c)
    retobj.code  = PDEFINE.RET.SUCCESS

    local ok, res = pcall(cluster.call, "master", ".configmgr", "get", "version")
    retobj.version = res.v
    return resp(retobj)
end

--协议接口获取玩家信息
function player.getUserInfo(msg)
    local recvobj = cjson.decode(msg)
    local uid = math.floor(recvobj.otheruid)

    local retobj = {}
    retobj.c     = math.floor(recvobj.c)
    retobj.code  = PDEFINE.RET.SUCCESS

    local userInfo = getPlayerInfo(uid)
    if userInfo == nil then
        local retobj = { c = cmd, code = PDEFINE.RET.ERROR.PLAYER_EXISTS}
        return resp(retobj)
    end
    local playerInfo = table.copy(userInfo)
    playerInfo.auth = 0
    if nil ~= playerInfo.realname and #playerInfo.realname > 0 then
        playerInfo.auth = 1
    end
    playerInfo.status      = nil
    playerInfo.create_time = nil
    playerInfo.login_time  = nil
    playerInfo.idcard = nil
    playerInfo.realname = nil
    playerInfo.bindcode = playerInfo.invit_uid or ""
    playerInfo.invit_uid = nil
    playerInfo.ip = getip(playerInfo.login_ip)
    playerInfo.login_ip = nil
    playerInfo.contact      = playerInfo.contact or ""
    playerInfo.contact_type = playerInfo.contact_type or 0
    playerInfo.coin = math.floor(playerInfo.coin)
    if nil ~= playerInfo.memo then
        playerInfo.memo = string.gsub(playerInfo.memo, "\n\r", "")
        playerInfo.memo = string.gsub(playerInfo.memo, "\n", "")
        playerInfo.memo = string.gsub(playerInfo.memo, "\r", "")
    end
    retobj.playerInfo = playerInfo

    return resp(retobj)
end

--------我是1条测试公告。-------------
local function getNotice(uid)
    local token = handle.getToken()
    local ok, ret, rs = pcall( api_service.callAPIMod, "getnotice", uid, token)
    --[[
    {
       "clinotice": "这是一条客户端公告"
    }
    ]]

    if not ok or ret ~= PDEFINE.RET.SUCCESS  then
        --调用失败
        return ""
    end

     if not rs then
        --没有测试公告
        return ""
    end
    
    return rs.clinotice
    -- local str = "<color=green>你好</color>由四川过湖南去，靠东有一条官路。这官路将近湘西边境到了一个地方名为'茶峒'的小山城时，有一小溪，溪边有座白色小塔，塔下住了一户单独的人家。这人家只一个老人，一个女孩子，一只<size=20>黄狗</>。" .. uid
    -- return str
end

--从db获取游戏信息
local function getGameList(sort, uid)
    local sql = string.format("select * from s_game_type where state = 1 order by hot desc")
    return skynet.call(".mysqlpool", "lua", "execute", sql)
end


function player.getRedSwitch(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local switch = do_redis({"get","{bigbang}:red:switch"})
    if switch then
      switch = true
    else
        switch = false      
    end
    local retobj = { c = math.floor(recvobj.c),switch = switch, code = PDEFINE.RET.SUCCESS}
    return resp(retobj)
end

-------- 修改玩家登陆密码 --------
function player.changepasswd(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local old     = recvobj.oldpass 
    local new     = recvobj.newpass 
    local userInfo = getPlayerInfo(uid)
    if userInfo == nil then
        local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.ERROR.PLAYER_EXISTS}
        return resp(retobj)
    end
    if userInfo.token == nil or #userInfo.token == 0 then
        local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.ERROR.TOKEN_ERR}
        return resp(retobj)
    end
    local ok, ret, rs = pcall( api_service.callAPIMod, "alterpassword", uid, userInfo.token, old, new)
    if not ok or ret ~= PDEFINE.RET.SUCCESS then
        --调用失败
        if ret == PDEFINE.RET.ERROR.LOGIN_FAIL then
            ret = PDEFINE.RET.ERROR.PASSWD_ERR
        end
        local retobj = { c = math.floor(recvobj.c), code = ret}
        return resp(retobj)
    end
    local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.SUCCESS}
    return resp(retobj)
end

--获取商城信息
function player.getShopInfo(msg, params)
    local pid = params.pid
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local platform = recvobj.platform or 1 --平台 1安卓 2IOS
    platform = math.floor(platform)

    local shopInfoList = {}
    local sql = string.format("select * from s_shop where platform = %d order by itemId asc", platform)
    local shopInfoList = skynet.call(".mysqlpool", "lua", "execute", sql)

    local coin = handle.moduleCall("player","getPlayerCoin", uid)
    coin = math.floor(coin)
    local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.SUCCESS, shoplist = shopInfoList, coin = coin}
    return resp(retobj)
end

--IAP 下单
function player.ipayOrder(msg)
    local recvobj = cjson.decode(msg)
    print("--------recvobj-------------",recvobj)
    local uid     = math.floor(recvobj.uid)
    local data  = recvobj.data --产品id
    local platform = recvobj.platform or 1 --默认gp 
    local sign  = recvobj.sign
    platform = math.floor(platform)
    local ok,data = pcall(jsondecode,data)

    local itemId = tonumber(math.floor(data.productId)) 
    local orderid = data.orderId
    local purchaseState = data.purchaseState
    
    -- --验证订单是否合法
    -- local url = "https://orders-dra.iap.hicloud.com".."/applications/purchases/tokens/verify"
    -- local purchaseToken = data.purchaseToken
    -- local productId = data.productId
    -- print( "getykaccesstoken purchaseToken:", purchaseToken, " productId:", productId )
    -- if nil == webclient then
    --     webclient = skynet.newservice("webreq")
    -- end

    -- local ok, body = skynet.call(webclient, "lua", "request", url, nil, {purchaseToken=purchaseToken,productId=productId}, false, TIME_OUT)
    -- print("body:", body)
    -- if not ok then
    --     print("getykaccesstoken url:", url, "Verify token from you9apisdk error!getykaccesstoken")
    --     return PDEFINE.RET.ERROR.REGISTER_FAIL
    -- end
    -- local ok,retp = pcall(jsondecode,body)
    -- if not ok then
    --     print("flush version error2!" , url)
    --     return PDEFINE.RET.ERROR.REGISTER_FAIL
    -- end
    

    local sql = string.format("select * from s_shop where itemId=%d and platform =%d", itemId,platform)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs == 0 then 
        return PDEFINE.RET.ERROR.PRODUCT_NOT_FOUND
    end
    local shop = rs[1]

    local playerInfo = handle.moduleCall("player","getPlayerInfo", uid)
    local now = os.time()

    local sql = string.format("insert into s_shop_order(orderid,uid,itemId,itemCount,price,status,platform,token,ctime,utime)values('%s',%d,%d,%d,%f,%d,%d,'%s',%d,%d)", orderid, uid, itemId, shop.itemCount,shop.price,purchaseState,platform,data.purchaseToken,now,0)
    local ret  = skynet.call(".mysqlpool", "lua", "execute", sql)
    if ret then
        local order = {}
        order["orderid"] = orderid
        order["itemId"] = shop.itemId
        order["uid"] = uid
        order["price"] = shop.price
        order["token"] = data.purchaseToken
        local retobj = {c = math.floor(recvobj.c), code = PDEFINE.RET.SUCCESS, order = order}
        return resp(retobj)
    end
    return PDEFINE.RET.ERROR.ORDER_CREATED_FAIL
end

--TODO 调用api接口
-------- 玩家上下分记录 --------
function player.scoreLog(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    -- local page = math.floor(recvobj.page)
    local list = {}

    local userInfo = getPlayerInfo(uid)
    if userInfo == nil then
        local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.ERROR.PLAYER_EXISTS, data = list}
        return resp(retobj)
    end
    if userInfo.token == nil or #userInfo.token == 0 then
        local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.ERROR.TOKEN_ERR, data = list}
        return resp(retobj)
    end
    local ok, ret, str = pcall( api_service.callAPIMod, "gettransferreord", uid, userInfo.token, 1, 20)
    --[[
        {
            "list": [
                {
                    "coin_befor": "0.00",           上分前余额
                    "coin_after": "300000.00",      上分后余额
                    "coin_change": 300000,          上分额度
                    "coin_time": "1544607453"       上分时间戳
                }
            ]
        }
    ]]
    if not ok or ret ~= PDEFINE.RET.SUCCESS then
        --调用失败
        local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.ERROR.CALL_FAIL, data = list}
        return resp(retobj)
    end
    
    for k,v in pairs(str.list) do
        local item = {}
        item["account"] = userInfo.playername 
        item["coin"] = tonumber(v.coin_change)
        if v.coin_time == nil or v.coin_time == 'null' then
            item["time"] = "unknown"
        else
            item["time"] = os.date("%Y-%m-%d", v.coin_time)
        end
        item["status"] = 2
        
        table.insert(list, item)
    end

    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
    
    local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.SUCCESS, data = list}
    return resp(retobj)
end

--发送手机号
function player.sendMobileCode(message)
    local recvobj = cjson.decode(message)
    local uid = math.floor(recvobj.uid)
    local mobile = math.floor(recvobj.mobile)
     local sql = string.format("select * from d_account where user = '%s' and type = 3",tostring(mobile))
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs == 1 then
        return PDEFINE.RET.ERROR.MOBILE_IS_REGIST --手机号已被注册
    end
    local code = tostring(randomCode(6))
    --获取user信息
    if nil == webclient then
        webclient = skynet.newservice("webreq")
    end
    
    local timestamp = os.date("%Y%m%d%H%M%S", os.time())
    local content = string.format("【闲友】验证码%d,请注意保存",code)
    local userid = 4606
    local pass = 123456
    local sign = md5.sumhexa(userid..pass.."testmima"..timestamp)
    local ok, body = skynet.call(webclient, "lua", "request", "http://39.104.28.149:8888/v2sms.aspx",nil,{action="isend", userid=4606,timestamp=timestamp,sign=sign,mobile=18525855928,content=content,sendTime="",extno=""}, nil,false)
    print("-----ok----",ok)
    print("-----body----",body)
    local sql = string.format("insert into s_user_bind()values(uid,code)values(%d,'%s')",uid,code)
    skynet.call(".mysqlpool", "lua", "execute", sql)
    --TODO 接验证码平台
    return PDEFINE.RET.SUCCESS
end

--手机号绑定
function player.bindMobile(message)
    local recvobj = cjson.decode(message)
    local uid = math.floor(recvobj.uid)
    local mobile = tostring(math.floor(recvobj.mobile))
    local code = tostring(math.floor(recvobj.code))

    local sql = string.format("select * from d_account where user = '%s' and type = 3",mobile)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs == 1 then
        return PDEFINE.RET.ERROR.MOBILE_IS_REGIST --手机号已被注册
    end
    sql = string.format("select * from s_user_code where user = '%s' and state = 0",mobile)
    rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if not rs or rs[1].code ~= code then
        return PDEFINE.RET.ERROR.INVAlID_CODE_FAIL --验证码错误
    end

    sql = string.format("update s_user_code set state = 1 where user = '%s' and code = '%s' ",mobile,code)
    rs = skynet.call(".mysqlpool", "lua", "execute", sql)

    local sql = string.format("insert into d_account(user,uid,type)  values ('%s',%d, 3)",mobile,uid)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
   
     local retobj  = {}
    retobj.c      = math.floor(recvobj.c)
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.mobile = mobile
    return resp(retobj)
end

local function getPlayerClubInfo(uid)
    local ok, clubList = pcall(cluster.call, "clubs", ".clubsmgr", "localGetClubList",uid)
    return clubList
end

local function getNotiyList()
   local sql = string.format("select * from d_notiy ")
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

    local notiyList = {}
    if #rs > 0 then
        for _,row in pairs(rs) do
            if os.time() >= row.stime and os.time() < row.etime then
                local notiyInfo = {}
                notiyInfo.id = row.id
                notiyInfo.noity = row.notiy
                table.insert(notiyList,notiyInfo)
            end
        end
    end
    return notiyList
end

local function getDaojuList()
   local sql = string.format("select * from s_anim_icon")
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

    local daojuList = {}
    if #rs > 0 then
        for _,row in pairs(rs) do
            local daojuInfo = {}
            daojuInfo.id = row.id
            daojuInfo.costGlod = row.costGlob
            table.insert(daojuList,daojuInfo)
        end
    end
    return daojuList
end

-- 请求登录信息
function player.getLoginInfo(message, deskAgent, agent, clientIP, city)
    LOG_INFO(" player.getLoginInfo get message data: ", message)
    local recvobj = cjson.decode(message)
    local uid = math.floor(recvobj.uid)
    local cmd = math.floor(recvobj.c)
    local lat = recvobj.lat
    lat = tonumber(lat)
    local lng = recvobj.lng
    lng = tonumber(lng)
    local data = {}
    data.c = 2
    data.uid = uid
    data.ip = handle.getIP()
    data.account = handle.getAccount()
    local userInfo = getPlayerInfo(uid)
    if not userInfo then
        data.code = PDEFINE.RET.ERROR.PLAYER_NOT_FOUND
        report_service.Report( PDEFINE.REPORTMOD.login_c2, data )
        LOG_ERROR(" player.getLoginInfo11111 找不到玩家 ", message)
        return PDEFINE.RET.ERROR.PLAYER_NOT_FOUND
    end

    local retobj = {}
    retobj.code  = PDEFINE.RET.SUCCESS

    local playerInfo = {}

    local sql = string.format("select * from d_account where uid = %d and type = 3",uid)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    local mobile = ""
    if #rs == 1 then
        mobile = rs[1].user
    end
    playerInfo.status = userInfo.status
    playerInfo.coin   = tonumber(userInfo.coin)
    playerInfo.uid    = userInfo.uid
    playerInfo.roomcard = userInfo.roomcard
    playerInfo.playername = serializePlayername(userInfo.playername)
    playerInfo.city = city or ""
    playerInfo.mobile = mobile or ""
    playerInfo.usericon   = userInfo.usericon
    if playerInfo.status ~= 1 then
        return PDEFINE.RET.ERROR.ACCOUNT_ERROR --玩家被禁掉了
    end
    local ip = getip(clientIP)
    setPlayerValue(uid,"login_ip",ip)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " 从 account_dc 获取玩家信息, account: ", account, "uid:",uid)
    local ok,deskInfo = nil
    if not table.empty(deskAgent) then
        retobj.deskFlag = 1
        ok,deskInfo = pcall(cluster.call, deskAgent.server, deskAgent.address, "getDeskInfo", message) --可能需要展示当前玩家的牌
        if not ok or deskInfo == nil then
            LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " 获取房间数据异常, 错误信息:", deskInfo, "uid:",uid)
            retobj.deskFlag = 0
            handle.deskBack()
        else
            retobj.deskInfo = deskInfo
        end  
    else
        retobj.deskFlag = 0
    end
    retobj.playerInfo = playerInfo
    retobj.gamelist = getGameList() --大厅游戏列表 按照ord排序
    retobj.clubs = getPlayerClubInfo(uid)
    retobj.noityList = getNotiyList()
    retobj.daojuList = getDaojuList()
    print("------------------9999999999999999999----------尼玛又断线了---",retobj)
    return resp(retobj)
end

--Gps位置更新
function player.gpsUpdate(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local city    = recvobj.city
    local lat     = recvobj.lat
    lat = tonumber(lat)
    local lng     = recvobj.lng
    lng = tonumber(lng)
    handle.gpsUpdate(lat,lng)
    if city and lat and lng then
        local sql = string.format("select * from s_user_city where uid = %d",uid)
        local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
        if #rs == 1 then
            if rs[1].city ~= city or math.floor(lat) ~= math.floor(rs[1].lat) or math.floor(lng) ~= math.floor(rs[1].lng) then
                sql = string.format("update s_user_city set city = '%s',lat = %.6f,lng =  %.6f where uid = %d",city,lat,lng,uid)
                skynet.call(".mysqlpool", "lua", "execute", sql)
            end
        else
            sql = string.format("insert into s_user_city(uid,city,lat,lng)values(%d,'%s',%.6f, %.6f)",uid,city,lat,lng)
            skynet.call(".mysqlpool", "lua", "execute", sql)
        end
    end
    local retobj  = {}
    retobj.c      = math.floor(recvobj.c)
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.city = city
    print("-----gpsUpdate-----retobj--------",retobj)
    return resp(retobj)
end

--游戏大厅界面(二级界面，展示游戏的场次信息)
function player.getGameInfoList(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local gameid  = math.floor(recvobj.gameid) --游戏id

    local retobj  = {}
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.gameid = gameid
    --游戏场次列表
    local sessionListInfo = {}

    local ok, rs = pcall(cluster.call, "master", ".sessmgr", "getAll")
    if ok and #rs ~= 0 then
        for _,row in pairs(rs) do
            if row.status==1 and row.gameid==gameid then
                local itemInfo = {}
                itemInfo.id = row.id
                itemInfo.level = row.level
                itemInfo.title = row.title
                itemInfo.basecoin = row.basecoin
                itemInfo.mincoin = row.mincoin
                itemInfo.leftcoin = row.leftcoin
                itemInfo.integral = row.integral or 0
                itemInfo.hot = row.hot
                itemInfo.ord = row.ord
                table.insert(sessionListInfo, itemInfo)
            end
        end
        table.sort(sessionListInfo, sortByOrd)
    end
    retobj.sesslist = sessionListInfo
    return resp(retobj)
end

--获取房间列表(游戏大厅) 或展示全部房间
function player.getRoomList(msg)
    local recvobj = cjson.decode(msg)
    local uid    = math.floor(recvobj.uid)
    local gameid = math.floor(recvobj.gameid)
    local ssid   = recvobj.ssid or 0
    ssid  = math.floor(ssid)
    local all    = math.floor(recvobj.all) --1未满 2全部

    local retobj  = {}
    retobj.gameid = gameid
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.c      = math.floor(recvobj.c)

    local retok, retcode, result = pcall(cluster.call, "master", ".mgrdesk", "getDeskList", 'fgame', gameid, all)
    if not retok then
        retobj.roomlist = {}
        return resp(retobj)
    end
    retobj.roomlist = cjson.decode(result)

    return PDEFINE.RET.SUCCESS, cjson.encode(retobj)
end

--获取玩家金币
function player.getCoin(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local coin = playerdatamgr.getPlayerCoin(uid)
    local retobj  = {}
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.c      = math.floor(recvobj.c)
    retobj.uid    = uid
    retobj.coin   = coin
    return PDEFINE.RET.SUCCESS, cjson.encode(retobj)
end

--获取玩家金币
function player.getPayInfo(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    
    local retobj  = {}
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.c      = math.floor(recvobj.c)
    retobj.uid    = uid
    local ok, res = pcall(cluster.call, "master", ".configmgr", "get", "paySwitch")
    retobj.paySwitch = res.v

    ok, res = pcall(cluster.call, "master", ".configmgr", "get", "payUrl")
    retobj.payUrl = res.v

    return PDEFINE.RET.SUCCESS, cjson.encode(retobj)
end

--大厅跑马灯
function player.pushmsg(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)

    pcall(cluster.call, "master", ".userCenter", "joinHall", uid)

    local retobj = { c = math.floor(recvobj.c), code = PDEFINE.RET.SUCCESS, notices = {}}
    local rs = do_redis({ "zrevrange", "pushnotices" , 0, 1 }, nil)
    if #rs > 0 then
        for _, noticeid in pairs(rs) do
            local msg   = do_redis({"hget", "push_notice:" .. noticeid, "msg"}, nil) --消息内容
            local speed   = do_redis({"hget", "push_notice:" .. noticeid, "speed"}, nil) --消息速度
            table.insert(retobj.notices, { speed = speed, msg = msg})
            break
        end
    end

    return resp(retobj)
end

function player.getPlayerCoin(uid)
    return playerdatamgr.getPlayerCoin(uid)
end


local function brodcastcoin(uid, altercoin, coin, issend2game)
    if issend2game then
        handle.notifySyncAlterCoin(altercoin, coin)
    end
end

--广播金币变化给客户端
function player.brodcastcoin2client(uid, altercoin)
    local coin = player.getPlayerCoin(uid)
    --如果玩家在大厅才通知客户端金币修改了
    LOG_INFO("brodcastcoin2client", "handle.checkhasdesk():", handle.checkhasdesk())
    if not handle.checkhasdesk() then
        local retobj  = {}
        retobj.c      = PDEFINE.NOTIFY.coin
        retobj.code   = PDEFINE.RET.SUCCESS
        retobj.uid    = uid
        retobj.deskid = 0
        retobj.count  = altercoin
        retobj.coin   = coin
        retobj.type   = 2
        handle.sendToClient(cjson.encode(retobj))
    end
end

-------- 计算玩家金币(累加累减) --------
function player.calUserCoin(uid_p, altercoin, log, type, isSync)
    local code, beforecoin, coin = playerdatamgr.calUserCoin(uid_p, altercoin, log, type, isSync)
    if code ~= PDEFINE.RET.SUCCESS then
        return code
    end

    brodcastcoin(uid_p, altercoin, coin, isSync)
    return PDEFINE.RET.SUCCESS,beforecoin,coin
end

--调用apiservice
function player.callapiservice(modname, ...)
    local UID = handle.getUid()
    local token = handle.getToken()
    if token == nil or token == "" then
        return PDEFINE.RET.ERROR.TOKEN_ERR
    end
    return api_service.callAPIMod( modname, UID, token, ... )
end

--获取战绩信息
function player.getRecordBigInfo(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local selectTime = recvobj.selectTime
    local clubid = math.floor(recvobj.clubid)
    local sql = ""
    if clubid == 0 then --请求个人
        sql = string.format("select * from s_big_record where uid = %d and selectTime = '%s' and clubid = %d order by time desc  ",uid,selectTime,clubid)
    else
        sql = string.format("select * from s_big_record where uid = %d and selectTime = '%s' and clubid > 0 order by time desc  ",uid,selectTime)
    end
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    
    local bigWinCnt = 0
    local totalScore = 0
    local jushu = 0
    for _, data in pairs(rs) do
        if data.isBigWin == 1 then
            bigWinCnt = bigWinCnt + 1
            totalScore = totalScore + data.score
        end
        jushu = jushu + 1
    end

    local retobj  = {}
    retobj.c = math.floor(recvobj.c)
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.uid    = uid
    retobj.clubid = clubid
    retobj.data   = rs
    retobj.jushu = jushu
    retobj.bigWinCnt = bigWinCnt
    retobj.totalScore = totalScore
    print("-----getRecordBigInfo----111111111111--------")
    return resp(retobj)
end

--获取战绩信息
function player.getRecordSmallInfo(msg)
    local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local deskid = math.floor(recvobj.deskid)
  
    local sql = string.format("select * from s_small_record where uid = %d and deskid = %d  order by time desc ",uid,deskid)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    local retobj  = {}
    retobj.c = math.floor(recvobj.c)
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.uid    = uid
    retobj.data   = rs
    print("-----getRecordSmallInfo----111111111111--------")
    return resp(retobj)
end

return player