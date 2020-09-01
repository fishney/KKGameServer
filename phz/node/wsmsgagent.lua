local skynet = require "skynet"
local cluster = require "cluster"
local cjson = require "cjson"
local date = require "date"
local wbsocket = require "wbsocket"
local MessagePack = require "MessagePack"
local report_service = require "report_service"
local api_service = require "api_service"
local game_tool = require "game_tool"
local is_release = skynet.getenv('isrelease')
local heart_time = 20*60*100 --心跳检测时间 20分钟
skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
}

-- 功能模块
local player = require "player"
local club = require "club"

local module_list = {
    ["club"] = club,
    ["player"] = player,
}

local NODE_NAME = skynet.getenv("nodename") or "noname"
local APP = skynet.getenv("app") or 1
APP = tonumber(APP)

-- node节点的全局服务
-- 玩家信息
local gate
local UID, SUBID
local CLIENT_FD
local SECRET
local CLIENT_UUID
local tmp_data = {}
local online = false -- 在线标志
--local timeflag = false -- 定时器标志
local IP = ""
local cluster_desk = {}
local autoFuc
-- 接口函数组
local CMD = {}
local handle = {}
local OFFLINE = {}
local flag = false
local kicking = false --正在T人
local loginOver = false
local msgIdx = 0
local newcoin = -1 --从api拿到的最新的coin数据 负数表示没有收到这个数据的最新值 不需要处理
local TOKEN --token数据
local NOW_LANGUAGE = 1 --玩家当前使用的语言标识 暂时不用入库，如果之后有需求再看 默认为1 中文
local ACCOUNT --玩家账号
local lat
local lng
local city
local Login_StartCounTime --登录计时 开始时间 注意这个不是登录时间，因为多次登录的情况下 这个值是有可能被修改的 只是用于统计在线时长
local isjoinPlayer2Master = false --是否已经发送给master join信息了
-- local lgoutCnt = 5 --等待登出计数 --3次定时器等待还未处理处理完登录就退出
local isLogout = false --是否正在登出 如果在登出了 就不会新处理消息了
--心跳定时器
local function set_timeout(ti, f)
    -- LOG_INFO("set_timeout UID", UID)
    -- LOG_INFO(debug.traceback())

    local function t()
        -- LOG_INFO("excute_timeout UID", UID, f)
        if f then
            f()
        end
    end
    skynet.timeout(ti, t)
    return function() 
        -- LOG_INFO("set_timeout close UID", UID)
        -- LOG_INFO(debug.traceback())
        f=nil
    end
end

-- 定时器检测玩家登录工作是否已完成
local function set_login_over_timeout(ti, f)
    local function t()
        if f then
            f()
        end
    end
    skynet.timeout(ti, t)
    return function() 
        f=nil
    end
end


--重置正在处理消息计数
local function resetDealMsgCount()
    msgIdx = 0
end

--减少正在处理消息计数
local function isDealingMsg()
    if msgIdx > 0 then
        return true
    end
    return false
end

--设置登出状态
local function setLogoutFlag(flag)
    isLogout = flag
end

--获取登出状态
local function getLogoutFlag()
    return isLogout
end

local function logout_do( isjihao )
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " ------msgIdx-------",msgIdx, ' agentid:', skynet.self())
    local lgoutCnt = 20 --最多2秒
    while isDealingMsg() and lgoutCnt ~= 0 do
       lgoutCnt = lgoutCnt - 1
       LOG_INFO("---消息处理未完成----------",UID)
       skynet.sleep(10) --100ms之后再检测
    end
    resetDealMsgCount()

    LOG_INFO("---消息处理已完成----------",UID)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time())," wsmsgagent  中 logout UID user  logout:", UID, " subid:", SUBID)
    if nil == UID then
        return 
    end
    
    -- 通知gate登出并回收agent为空闲，不再exit()
    if gate then
        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time())," wsmsgagent  中 开始调用 gate中的logout:", UID, " subid:", SUBID)
        skynet.call(gate, "lua", "logout", UID, SUBID)
    else
        LOG_ERROR(string.format("%s logout but gate cannot find", UID))
    end

    --jackpot.closeAllTimer()

    --发出登出日志
    local onlinetime = os.time()-Login_StartCounTime
    if onlinetime < 0 then
        onlinetime = 0
    end 
    -- if not isjihao then
    --     pcall(api_service.callAPIMod, "logout", uid, TOKEN, onlinetime)
    -- end
    -- --检测是否有重复的agent wsgated里面存放的对应关系是最新的wsmsgagent不一定是自己
    -- skynet.call(gate, "lua", "resetloginstarttime", UID)

    if autoFuc then autoFuc() end

    local user_data = getPlayerInfo(UID)
    if user_data then
        pcall(cluster.call, "master", ".userCenter", "removePlayer", user_data)
        if cluster_desk then
            if not table.empty(cluster_desk) then
                pcall(cluster.call, cluster_desk.server, cluster_desk.address, "ofline",1,UID)
            end
        end
    else
        LOG_ERROR("logout_do user_data is nil")
        pcall(cluster.call, "master", ".userCenter", "removePlayer", {uid=UID})
    end

    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),"UID:",UID, " will set UID nil  before unload")
    CLIENT_FD = nil
    SUBID  = nil
    SECRET = nil
    msgIdx = 0
    UID    = nil
    gate   = nil
end

local function logout(isjihao)
    if getLogoutFlag() then
        return false
    end
    setLogoutFlag(true)
    pcall(logout_do, isjihao)
    CMD.exit()
    -- setLogoutFlag(false)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),"UID:",UID, " had set UID nil ")
    return true
end

--更新房间gps信息
function handle.gpsUpdate(slat,slng)
    lat = slat
    lng = slng
    if table.empty(cluster_desk) then
        return false
    end
    pcall(cluster.call, cluster_desk.server, cluster_desk.address, "gpsUpdate", UID, lat,lng)
    
end

--检查是否有房间
function handle.checkhasdesk()
    if table.empty(cluster_desk) then
        return false
    end
    return true
end

function CMD.stdesk()
    if table.empty(cluster_desk) then
        return 0
    end
    return 1
end

--获取玩家桌子对象
function CMD.getClusterDesk()
    if not table.empty(cluster_desk) then
        return cluster_desk
    end
    return {}
end

--获取玩家桌子对象
function CMD.setClusterDesk(source, desk)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " 设置cluster_desk  desk:", desk)
    cluster_desk = desk
end


local function disconnect_heart()
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),"------heartBeat:-disconnect_heart---- agentid:", skynet.self(), UID)
    --
    CMD.afk()
end

function CMD.login(source, userinfo, sid, secret, deskAgent)
    local uid = userinfo.uid
    local clientid = userinfo.client_uuid
    local newcoin_para = userinfo.playercoin  or 0
    local token = userinfo.access_token
    local language = userinfo.language
    if language == nil then
        language = 1
    end
    LOG_INFO("uid:", uid, "登陆啦 , wsmsgagent CMD.login uid:", uid, " secret:", secret, " subid:", sid, ' agentid:', skynet.self(), " deskAgent:", deskAgent, " language:", language, " ACCOUNT:", ACCOUNT)
    LOG_DEBUG("CMD.login:", userinfo)
    gate   = source
    UID    = math.floor(uid)
    SUBID  = sid
    SECRET = secret
    CLIENT_UUID = clientid
    newcoin = tonumber(newcoin_para)
    TOKEN = token
    NOW_LANGUAGE = language
    ACCOUNT = userinfo.account
    Login_StartCounTime = os.time()
    local sql = string.format("select * from s_user_city where uid = %d",UID)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs == 1 then
        city = rs[1].city
    end
    if nil ~= deskAgent then
        CMD.setClusterDesk(source, deskAgent)
        pcall(cluster.call, cluster_desk.server, cluster_desk.address, "updateUserClusterInfo", UID, skynet.self())
    else
        cluster_desk = {}
    end

    if autoFuc then 
        autoFuc() 
    end
    autoFuc = set_timeout(heart_time, disconnect_heart)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), "uid:", uid, " 从登录服过来登陆啦 , wsmsgagent CMD.login end -----------~~~~~~~~~~~~")
end

function CMD.logout()
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " wsmsgagent 中 uid:", UID, "退出啦 , wsmsgagent CMD.logout ", " agentid:", skynet.self())
    if nil == UID then
        return true
    end
    skynet.error(string.format("%s is logout", UID))
    return logout()
end

function autoExit()
    collectgarbage("collect")
    LOG_INFO("----------------delete--agent---- agentid:", skynet.self())
    skynet.exit()
end

function CMD.exit()
    LOG_INFO("----------------用户对象被释放了---- agentid:", skynet.self())
    if autoFuc then autoFuc() end
    skynet.timeout(10, autoExit) --主要作用是等当前消息处理完成 下一次处理来exit
end

local function recycleDeskAgent()
    pcall(cluster.call, cluster_desk.server, cluster_desk.address, "resetDesk")
end

function CMD.afk(_)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), "uid:", UID, "========================== CMD.afk ==========================", " agentid:", skynet.self())
    if UID == nil then
        return
    end
    online = false
    CMD.logout()
end

function CMD.setUserCardType(_, gameid, multi, count)
    if cluster_desk and not table.empty(cluster_desk) then
        if cluster_desk.gameid == 12 then
            pcall(cluster.call, cluster_desk.server, cluster_desk.address, "setUserCardType",multi, count, UID)
        end    
    end
end

--后台获取用户信息
function CMD.apiUserInfo()
    local playerInfo = getPlayerInfo(UID)
    if nil == playerInfo then
        return PDEFINE.RET.ERROR.CALL_FAIL
    end
    playerInfo.gameid = 0
    playerInfo.deskid = 0
    if cluster_desk then
        playerInfo.gameid = cluster_desk.gameid
        playerInfo.deskid = cluster_desk.deskid
    end
    return PDEFINE.RET.SUCCESS, playerInfo
end

local function sendToClient(retobj)
    LOG_DEBUG("sendToClient CLIENT_FD:", CLIENT_FD, "retobj:", retobj)
    if CLIENT_FD ~= nil then
        local info = '00000000'.. MessagePack.pack(retobj)
        wbsocket:send_binary(CLIENT_FD, info)
    end
end

-- 离线事件处理
local function offlineCmd(offlineTable)
    if nil == UID then
        return
    end
    local sql = "select id,cmd,param from "..offlineTable.." where uid="..UID
    local rs = do_mysql_direct(sql)
    local ids = {}
    for _,data in pairs(rs) do
        local f = OFFLINE[data.cmd]
        LOG_DEBUG("OFFLINE. data.cmd:",data.cmd,"data.param:",data.param)
        if not f then
            LOG_ERROR(string.format("unknown cmd %s", data.cmd))
        else
            local params = string.split(data.param, ",")
            LOG_DEBUG("OFFLINE. data.cmd:",data.cmd,"params:",params)
            f(table.unpack(params))
        end
        table.insert(ids, data.id)
    end
    if #rs > 0 and not table.empty(ids) then
        sql = "delete from "..offlineTable.." where id in (".. table.concat(ids,",")  ..")"
        LOG_INFO(sql)
        do_mysql_direct(sql)
    end
end



-- 心跳包续传可继续加入中心服
local function heartBeat()
    if autoFuc then autoFuc() end
    if not online then
         print("----2222---cluster_desk-------",cluster_desk)
        if not table.empty(cluster_desk) then
            pcall(cluster.call, cluster_desk.server, cluster_desk.address, "ofline",1,UID)
        end
        online = true
    end
    autoFuc = set_timeout(heart_time,disconnect_heart)
end

--获取玩家join到master的信息
function CMD.getUser2MasterInfo()
    local cluster_info = {server = NODE_NAME, address = skynet.self(), gateaddress = gate}
    local user_data = getPlayerInfo(UID) 
    if user_data == nil then
        return PDEFINE.RET.ERROR.PLAYER_NOT_FOUND
    end
    return PDEFINE.RET.SUCCESS, {cluster_info = cluster_info, data = user_data}
end

--获取这个用户从加载以来是否发送过joinplayer给master
function CMD.getIsjoinPlayer2Master( ... )
    return isjoinPlayer2Master
end

-- local LINGSHI_CLEARCOIN = true

function CMD.loaduser( _, fd, ip )
    LOG_DEBUG("CMD loaduser:", TOKEN, UID, fd, ip)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " 已加载完玩家数据 UID: ", UID)
    local user_data = getPlayerInfo(UID)
    if user_data then
        --注意  下面joinPlayer 必须最开始执行，牵扯到金币修改对queue的锁
        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " master_userCenter  joinPlayer: ", UID)
        local code,user2masterdata = CMD.getUser2MasterInfo()
        pcall(cluster.call, "master", ".userCenter", "joinPlayer", user2masterdata.cluster_info, user2masterdata.data)
        isjoinPlayer2Master = true

        offlineCmd("d_offline_multi_cmd")

        --金币总排行
        user_data.coin = user_data.coin or 0
        --比较自己数据与api数据是否有差别
        -- if newcoin >= 0 then
        --     if user_data.coin ~= newcoin then
        --         --暂时只记录 不做任何处理 因为现在理论上来说正常情况下也会出现这个问题
        --         LOG_ERROR("===>UID:",UID," coin num error.user_data.coin=", user_data.coin, " api newcoin=", newcoin)
        --         if is_release == nil or is_release == false then
        --             --正式环境不开放这行代码
        --             handle.dcCall("user_dc", "setvalue", UID, "coin", newcoin)
        --         end
        --     end
        --     --比较完后修改状态 不进行多次比较
        --     newcoin = -1
        -- end
        setPlayerValue(UID, "login_time",os.time())
    end
    CLIENT_FD = fd
    LOG_INFO("CLIENT_FD:", CLIENT_FD, "UID:", UID)
    if autoFuc then 
        autoFuc() 
    end
    autoFuc = set_timeout(heart_time, disconnect_heart)

    LOG_INFO("-----connect2---")
    print("----3333---cluster_desk-------",cluster_desk)
    if not table.empty(cluster_desk) then
        pcall(cluster.call, cluster_desk.server, cluster_desk.address, "ofline",0,UID) --上线
    end
    LOG_INFO("-----connectmsg finish---")
end

function CMD.connect(sth, fd, ip)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " agent connect ... 开始加载玩家数据 UID: ", UID, ' agentid:', skynet.self(), "fd:", fd)
    skynet.error(string.format("AGENT FD"))
    online = true
    local params = string.split(ip, ":")
    IP = params[1]
    LOG_INFO(string.format("%d is real login", UID))
    LOG_DEBUG("CMD connect:", fd, ip)
    CMD.getuserqueue(sth, "", "loaduser", fd, ip)

    -- local func = {iscluster = true, node = NODE_NAME, addr = skynet.self(), fuc_name="loaduser"}
    -- pcall(cluster.call, "master", ".userCenter", "alterUserQueue", UID, func, fd, ip)
end

function CMD.getuserqueuebak( sth, func )
    LOG_INFO("getuserqueuebak", func)
    local modname = func.modparam.modname
    local modfuc = func.modparam.modfuc
    if modname == "" then
        --本地方法
        return CMD[modfuc](sth, table.unpack(func.func_param))
    else
        --模块方法
        return handle.moduleCall(modname, modfuc, table.unpack(func.func_param))
    end
end

function CMD.getuserqueue(_, modname, modfuc, ...)
    if modname == nil then
        modname = ""
    end
    param = {...}
    local func = {
        iscluster = true, 
        node = NODE_NAME, 
        addr = skynet.self(), 
        fuc_name= "getuserqueuebak", 
        func_param = param, 
        modparam = {modname = modname, modfuc = modfuc}
    }
    return pcall(cluster.call, "master", ".userCenter", "alterUserQueue", UID, func)
end

function CMD.create()
    local user_data = getPlayerInfo(UID)
    if nil~=user_data and not table.empty(user_data) then
        local code,user2masterdata = CMD.getUser2MasterInfo()
        -- 加入中心管理服务器
        pcall(cluster.call, "master", ".userCenter", "joinPlayer", user2masterdata.cluster_info, user2masterdata.data)
    end
end

function CMD.kick(_, clientid)
    local islogout = true
    kicking = true
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),"--- wsmsgagent --CMD.kick -异地登录了 ----UID: ", UID, " clientid:", clientid, " CLIENT_UUID:", CLIENT_UUID  , " agentid:", skynet.self())
    LOG_INFO(string.format("%s is kick", UID))

    if clientid == nil or clientid ~= CLIENT_UUID then
        local retobj    = {}
        retobj.code     = PDEFINE.RET.SUCCESS
        retobj.c        = PDEFINE.NOTIFY.otherlogin
        retobj.uid      = UID
        sendToClient(cjson.encode(retobj))
        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),"------发T人广告了 : ", UID)
    end
    if nil ~= UID then
        islogout = logout(true)
    end
    kicking = false
    return islogout
end

-- 通知
function CMD.sendToClient(_, info)
    sendToClient(info)
end

--检查是否语言相符 并通知
function CMD.sendToClientCheckLan(_, language, info )
    --LOG_DEBUG("uid", UID,"sendToClientCheckLan language:", language, " NOW_LANGUAGE:", NOW_LANGUAGE)
    if tonumber(NOW_LANGUAGE) == tonumber(language) then
        sendToClient(info)
    end
end

-- 退出桌子
function CMD.deskBack(_, gameid)
    print("deskBack 玩家退出桌子咯, UID:", UID, " agentid", skynet.self(), string.format("deskBack gameid: %s vs cluster_desk.gameid: %s", gameid, cluster_desk.gameid))
    cluster_desk = {}
    pcall(cluster.call, "master", ".agentdesk", "removeDesk", UID)
    -- if math.floor(gameid) == math.floor(cluster_desk.gameid) then
    --     print(UID, string.format("deskBack gameid: %s == cluster_desk.gameid: %s 把玩家的cluster_desk设置为{}", gameid, cluster_desk.gameid))
    --     cluster_desk = {}

    --     LOG_INFO(" CMD.deskBack", UID, " agentid", skynet.self(), gate)

    --     pcall(cluster.call, "master", ".agentdesk", "removeDesk", UID)
    -- else
    --     LOG_INFO(UID, string.format("deskBack gameid: %s vs cluster_desk.gameid: %s", gameid, cluster_desk.gameid))
    -- end

end

-- 退出桌子
function CMD.deskBackByName(_, servername)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),"deskBack 玩家退出桌子咯, UID:", UID, " agentid", skynet.self(), string.format("deskBack gameid: %s vs cluster_desk.gameid: %s", gameid, cluster_desk.gameid))
    if servername == cluster_desk.server then
        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), "---------- UID ------>:",UID)
        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),UID, string.format("deskBack servername: %s == cluster_desk.gameid: %s 把玩家的cluster_desk设置为{}", servername, cluster_desk.gameid))
        cluster_desk = {}

        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " CMD.deskBack", UID, " agentid", skynet.self())

        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " CMD.deskBack call master removeDesk", UID, gate)
        pcall(cluster.call, "master", ".agentdesk", "removeDesk", UID)
    else
        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),UID, string.format("deskBack servername: %s vs cluster_desk.gameid: %s", servername, cluster_desk.gameid))
    end

end

-- 远程节点调用模块
function CMD.clusterModuleCall(_, module, fun, ...)
    return module_list[module][fun](...)
end

--有新邮件
function CMD.addMail(_, mail)
    --assert(mail)
    -- 发送邮件通知
    local retobj = {c =  PDEFINE.NOTIFY.NOTIFY_MAIL, code = PDEFINE.RET.SUCCESS}
    sendToClient(cjson.encode(retobj))
end

-------- 是否在创建猜拳的白名单中(可以不用绑定fb) --------
local function isInWhiteList(uid, type)
	local result = false
    local key
    if type == "FB" then
        key = "nofblist"
    end
	local ok, filterItem = pcall(cluster.call, "master", ".configmgr", "get", key)
	if ok and not table.empty(filterItem) then
		local filterList = string.split(filterItem.v, ',')
        for _, setuid in pairs(filterList) do
            LOG_INFO("----------------------------")
            LOG_INFO(" setuid vs uid:", setuid, uid)
			if tonumber(setuid) == tonumber(uid) then
				result = true 
				break
			end
		end
	end
	return result
end

-- 远程调用游戏模块接口
local function clusterGameModuleCall(f_method,recvobj)
    -- 调用远程服务
    local cluster_info = { server = NODE_NAME, address = skynet.self()}
    local retok, retcode, retobj, deskAddr
    local cluster_name, cluster_service, cluster_method = f_method:match("([^.]+).([^.]+).(.+)")
    local msg = cjson.encode(recvobj)
    if cluster_method == "joinDeskInfo" then 
        retok, retcode, retobj, deskAddr = pcall(cluster.call, "game", ".dsmgr", cluster_method, cluster_info, msg, IP, lat, lng)
        print("--joinDeskInfo--retok-----",retok)
        print("----retcode-----",retcode)
        print("----deskAddr-----",deskAddr)
        print("----retobj-----",retobj)
        if retcode == 200 then
            cluster_desk = deskAddr
        end
    elseif cluster_method == "createDeskInfo" then
        retok, retcode, retobj, deskAddr = pcall(cluster.call, "game", ".dsmgr", cluster_method, cluster_info, msg, IP, lat, lng)
         print("--createDeskInfo--retok-----",retok)
        print("----retcode-----",retcode)
        print("----deskAddr-----",deskAddr)
        if retcode == 200 then
            cluster_desk = deskAddr
        end
    else 
        if not table.empty(cluster_desk) then --房间不存在 就不调用房间
            retok, retcode, retobj = pcall(cluster.call, cluster_desk.server, cluster_desk.address, cluster_method, msg)
             if cluster_method == "exitG" and retcode == PDEFINE.RET.EXIT_RESET then --如果用户确实不在房间卡死在房间中,点退出照样给用户退出去
                retcode = PDEFINE.RET.SUCCESS
                pcall(cluster.call, cluster_desk.server, ".dsmgr", "recycleAgent", cluster_desk.address,cluster_desk.deskId)
                retobj = nil
                cluster_desk = {}
            end
        else
            if cluster_method == "exitG" then --如果用户确实不在房间卡死在房间中,点退出照样给用户退出去
                retok = true
                retcode = 200
            else
                retok = true
                retcode = 931
            end
        end
    end
    return retok, retcode, retobj
end

local function __TRACKBACK__(errmsg)
    local track_text = debug.traceback(tostring(errmsg), 6)
    print(track_text)
    LOG_ERROR(track_text)
    return false
end

local function clusterClubsModuleCall(cluster_service,cluster_method,msg)
    local cluster_info = { server = NODE_NAME, address = skynet.self()}
    local retok, retcode, retobj, deskAddr = pcall(cluster.call, "clubs", "."..cluster_service, cluster_method, msg, cluster_info, IP, lat, lng)
    if retcode == 200 and deskAddr then
        cluster_desk = deskAddr
    end 
    return retok, retcode, retobj
end

--msg 是table
local function processClient(message)
    local begin = skynet.time()
    local recvobj = cjson.decode(message) --json object
    
    local cmd = math.floor(recvobj.c)
    if 11 == cmd then
        heartBeat()
    else
        print("---------recvobj----------",recvobj)
    end
    if 12 == cmd then --12退出游戏
        CMD.logout()
        return
    end
    if 2 == cmd then
        if autoFuc then autoFuc() end
        autoFuc = set_timeout(heart_time, disconnect_heart)
    end
    if kicking and (2 == cmd or 3 == cmd) then
        return {c= cmd, uid =UID, code=PDEFINE.RET.ERROR.FORBIDDEN }
    end

    if not recvobj then
        return {c= 400, uid =UID, code=408}
    end

    --参数中的uid必须是自己
    --local uid = recvobj.uid
    --if uid ~= nil then
    --    uid = math.floor(uid)
    --    if uid ~= UID then
    --        return {c= 400, uid =UID, code=403}
    --    end
    --end

    if 11 ~= cmd then --心跳包不带uid
        local uid = recvobj.uid
         uid = math.floor(uid)
        if not uid or uid ~= UID then
            if UID == nil then
                LOG_ERROR("uid is nil or uid=%d is not equal UID", uid)
            else
                LOG_ERROR("uid is nil or uid=%d is not equal UID=%d", uid , UID)
            end
            return {c= 11, code=408}
        end
    end

    local f = PDEFINE.PROTOFUN[tostring(cmd)]
    if f then
        local retok, retcode, retobj
        local f_module, f_method = f:match "([^.]*).(.*)"
        if f_module == "cluster" then
            -- 调用远程服务
            local cluster_name, cluster_service, cluster_method = f_method:match("([^.]+).([^.]+).(.+)")
           
            if cluster_name == "clubs" then
                retok, retcode, retobj = clusterClubsModuleCall(cluster_service,cluster_method,message)
            else
                -- 玩家前提条件判断
                retok, retcode, retobj = clusterGameModuleCall(f_method,recvobj)
            end
        else
            -- 调用本地模块函数
            local m = module_list[f_module]
            if not m then
                LOG_ERROR(string.format("unknown module %s", f_module))
            else
                --retok, retcode, retobj = pcall(
                --    m[f_method], message, cluster_desk, skynet.self(), IP
                --)
                local messageRecv = cjson.decode(message)
                if messageRecv.lat then
                    lat = messageRecv.lat
                end
                if messageRecv.lng then
                    lng = messageRecv.lng
                end
                retok, retcode, retobj = xpcall(
                        m[f_method], __TRACKBACK__, message, cluster_desk, skynet.self(), IP, city
                )
            end
        end

        LOG_DEBUG(string.format("process %s time used %f s ", f, (skynet.time()-begin), UID))
        -- 结果发包
        cjson.encode_empty_table_as_object(false)
        if retok then
            if tonumber(retcode) ~= 200 then
                local gameid = retobj
                retobj = {c = cmd, code = retcode}
                if retcode == PDEFINE.RET.ERROR.CREATE_AT_THE_SAME_TIME then
                    retobj.gameid = gameid
                end
                return cjson.encode(retobj)
            end
            if retobj == nil then
                retobj = {c = cmd, code = retcode}
            else
                local tmp = cjson.decode(retobj)
                tmp.c = cmd
                if nil == tmp.code then
                    tmp.code = PDEFINE.RET.SUCCESS
                end
                retobj = tmp
            end
            if cmd ~= 11 then
                print("----opcode-----",cmd,"-----retobj----",retobj)
            end
            return cjson.encode(retobj)
        else
            LOG_ERROR(string.format("%s call_fail", cmd))
            return cjson.encode({c = cmd, uid = UID, code= 400})
        end
    else
        LOG_ERROR(string.format("%s no function", recvobj.c))
    end
end

------ 玩家在拉米匹配场(体验场除外)增加人气值 --------
function OFFLINE.addRenqi(num)
    handle.moduleCall("player", "addRenqi", UID, tonumber(num))
end

------ 玩家游戏过程中，掉线被T，牌型中扣费改为离线处理,下次登录会设置 累计加减金币 --------
function OFFLINE.calUserCoin(altercoin, alterlog, type)
    LOG_DEBUG("OFFLINE.calUserCoin altercoin:",altercoin," alterlog:",alterlog," type:", type)
    handle.moduleCall("player", "calUserCoin", UID, tonumber(altercoin), alterlog, tonumber(type))
end

--玩家游戏过程中，掉线被T，牌型中扣费改为离线处理,下次登录会设置
function OFFLINE.setPlayerCoin(coin)
    handle.moduleCall("player","setPlayerCoin",UID,tonumber(coin))
end

function OFFLINE.updateQuest(questid, count)
    handle.moduleCall("quest","updateQuest",UID, 1, tonumber(questid), tonumber(count))
end

function OFFLINE.reloadPlayerInfo(uid)
    handle.moduleCall("player","reloadPlayerInfo",UID)
end

function OFFLINE.setevoaccount(evoaccount)
    -- LOG_DEBUG("setevoaccount:",evoaccount,"UID:",UID)
    handle.dcCall("user_dc","setvalue", UID, "evoaccount", evoaccount)
end


function handle.moduleCall(module, fun, ...)
    local ret
    ret = {module_list[module][fun](...)}
    return table.unpack(ret)
end

function handle.setPlayerTmpData(key, value)
    tmp_data[key] = value
end

function handle.getPlayerTmpData(key, value)
    return tmp_data[key]
end

function handle.sendToClient(retobj)
    sendToClient(retobj)
end


function handle.getUid()
    return UID
end

function handle.getIP()
    return IP
end

function handle.getAccount()
    return ACCOUNT
end

--供player里回收桌子使用
function handle.deskBack()
    if not table.empty(cluster_desk) then
        CMD.deskBack(nil, cluster_desk.gameid)
    end
end

function handle.isInWhiteList(uid, type)
    return isInWhiteList(uid, type)
end

--同步金币变化 changecoin：金币修改值 nowcoin：金币最终值
function handle.notifySyncAlterCoin(changecoin, nowcoin)
    LOG_DEBUG("notifySyncAlterCoin", changecoin, nowcoin, cluster_desk)
    --Game同步金币
    -- if changecoin > 0 then
        if cluster_desk ~= nil and not table.empty(cluster_desk) then
            pcall(cluster.call, cluster_desk.server, cluster_desk.address, "addCoinInGame", UID, changecoin)
        end
    -- end
    --
end

function CMD.brodcastcoin( _,coin )
    --广播金币变化
    local playerInfo = getPlayerInfo(UID)
    local retobj  = {}
    retobj.c      = PDEFINE.NOTIFY.coin
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.uid    = UID
    retobj.deskid = 0
    retobj.count  = coin
    retobj.coin   = playerInfo.coin
    retobj.type   = 1
    handle.sendToClient(cjson.encode(retobj))

    --通知桌子里加金币
    if coin > 0 then
        handle.notifySyncAlterCoin(coin, retobj.coin)
    end
end

--后台玩家充值
-- function CMD.apiAddPlayerCoin(source, coin, brodcast)
--     LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), "后台玩家充值 玩家:", UID , '----------添加金币-------:', coin, brodcast)
--     if coin < 0 and not table.empty(cluster_desk) then
--         return PDEFINE.RET.ERROR.USER_IN_GAME
--     end
    
--     local ret = handle.moduleCall("player", "calUserCoin", UID, coin, "后台充值金币:"..coin, 0, true)

--     if table.empty(cluster_desk) then
--         if nil ~= brodcast then
--             --后台支付渠道通知过来的要广播
--             local playerInfo = handle.moduleCall("player","getPlayerInfo",UID)
--             local retobj  = {}
--             retobj.c      = PDEFINE.NOTIFY.coin
--             retobj.code   = PDEFINE.RET.SUCCESS
--             retobj.uid    = UID
--             retobj.deskid = 0
--             retobj.count  = coin
--             retobj.coin   = playerInfo.coin
--             retobj.type   = 1
--             handle.sendToClient(cjson.encode(retobj))

--             local retobj  = {}
--             retobj.c      = PDEFINE.NOTIFY.BUY_OK
--             retobj.code   = PDEFINE.RET.SUCCESS
--             retobj.uid    = UID
--             retobj.coin   = coin
--             retobj.type   = 1
--             handle.sendToClient(cjson.encode(retobj))
--         end
--         LOG_INFO("--------return ret:", ret)
--         return PDEFINE.RET.SUCCESS
--     else
--         -- if coin > 0 then
--             -- LOG_INFO("readyaddCoinInGame cluster_desk.server:", cluster_desk.server," cluster_desk.address:", cluster_desk.address, " UID:", UID, " coin:", coin)
--             -- local ok, ret = pcall(cluster.call, cluster_desk.server, cluster_desk.address, "addCoinInGame", UID, coin)
--             -- LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), "------------- 要给  玩家:", ok)
--             -- if ok then 
--             --     --广播金币变化
--             --     local playerInfo = handle.moduleCall("player","getPlayerInfo",UID)
--             --     local retobj  = {}
--             --     retobj.c      = PDEFINE.NOTIFY.coin
--             --     retobj.code   = PDEFINE.RET.SUCCESS
--             --     retobj.uid    = UID
--             --     retobj.deskid = cluster_desk.desk_id
--             --     retobj.count  = coin
--             --     retobj.coin   = playerInfo.coin
--             --     retobj.type   = 1
--             --     handle.sendToClient(cjson.encode(retobj))

--                 return PDEFINE.RET.SUCCESS
--             -- end
--         -- end
--         -- --游戏内，不让从充值
--         -- return PDEFINE.RET.ERROR.USER_IN_GAME
--     end
-- end

--后台玩家充值
function CMD.apiAddPlayerCoin(source, coin, brodcast)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), "后台玩家充值 玩家:", UID , '----------添加金币-------:', coin, brodcast)
    local ret = handle.moduleCall("player", "calUserCoin", UID, coin, "后台充值金币:"..coin, 0, true)
    local playerInfo = getPlayerInfo(UID)
    local retobj  = {}
    retobj.c      = PDEFINE.NOTIFY.coin
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.uid    = UID
    retobj.deskid = 0
    retobj.count  = coin
    retobj.coin   = playerInfo.coin
    retobj.type   = 1
    handle.sendToClient(cjson.encode(retobj))

    local retobj  = {}
    retobj.c      = PDEFINE.NOTIFY.BUY_OK
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.uid    = UID
    retobj.coin   = coin
    retobj.type   = 1
    handle.sendToClient(cjson.encode(retobj))
end


--给桌子上玩家加金币
function handle.addCoinInGame(coin)
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), "------------- 要给  玩家:", UID , '----------添加金币-------:', coin)
    if not table.empty(cluster_desk) then
        local ok, ret = pcall(cluster.call, cluster_desk.server, cluster_desk.address, "addCoinInGame", UID, coin)
        LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), "------------- 要给  玩家:", ok)
        if ok then 
            return PDEFINE.RET.SUCCESS
        end
    end
    return PDEFINE.RET.ERROR.USER_IN_GAME
end

function CMD.resetloginstarttime( )
    Login_StartCounTime = os.time()
end

-- 通知客户端重新登录
function CMD.callrelogin()
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()),"callrelogin 通知玩家重新登录, UID:", UID, " agentid", skynet.self())
    local retobj  = {}
    retobj.c      = PDEFINE.NOTIFY.NOTIFY_RELOGIN
    retobj.code   = PDEFINE.RET.SUCCESS
    handle.sendToClient(cjson.encode(retobj))

    CMD.kick(0, CLIENT_UUID)
end


function CMD.getUid()
    return UID
end

function CMD.getNowLanguage( ... )
    if NOW_LANGUAGE == nil then
        NOW_LANGUAGE = 1
    end
    NOW_LANGUAGE = math.floor(tonumber(NOW_LANGUAGE))
    return NOW_LANGUAGE
end

function handle.getNowLanguage( ... )
    if NOW_LANGUAGE == nil then
        NOW_LANGUAGE = 1
    end
    NOW_LANGUAGE = math.floor(tonumber(NOW_LANGUAGE))
    return NOW_LANGUAGE
end

function handle.getToken( ... )
    return TOKEN
end

function CMD.getToken( ... )
    return TOKEN
end

-- 通知刷新gamelist
function CMD.changeGamelist(_, info)
    info.gamelist = handle.moduleCall("player","resetGamelist",info.gamelist, UID)
    handle.sendToClient(cjson.encode(info))
end

skynet.start(function()
    -- If you want to fork a work thread , you MUST do it in CMD.login
    skynet.dispatch("lua", function(session, source, command, ...)
        local f = assert(CMD[command])
        skynet.retpack(f(source, ...))
    end)


    skynet.dispatch("client", function(session, address, msg)
        local retobj = processClient(msg)
        skynet.ret(retobj)
    end)

    -- 绑定各模块
    for _, m in pairs(module_list) do
        m.bind(handle)
    end

    -- 启动agent自己的数据中心
    cluster_desk = {}
    collectgarbage("collect")
end)
