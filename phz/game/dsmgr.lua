local msgserver = require "snax.msg_server"
local skynet = require "skynet"
local cluster = require "cluster"
local cjson   = require "cjson"
local md5     = require "md5"
cjson.encode_sparse_array(true)
cjson.encode_empty_table_as_object(false)

local CMD = {}
local servername
local agent_pool = {}

local max_ph_dagent = 400
local us_ph_dagent = 0
local max_poolsize = 200
local desks = {}
local deskIds = {}
local GAME_NAME = skynet.getenv("gamename") or "game"
local use_agent = 0
local function addAgent(size,gameid)
	for i=1,size do
		local agent = nil
		local agentName = PDEFINE_GAME.TYPE_INFO[gameid].AGENT
		agent = skynet.newservice (agentName)
		table.insert(agent_pool[gameid], agent)
	end
end

local function getAgent(gameid)
	local ret = table.remove(agent_pool[gameid])
	return ret
end


local function exitAgent(agent)
	pcall(skynet.call, agent, "lua", "exit")
    use_agent = use_agent - 1
end

local function exit_agent_timeout(ti, f,parme)
	local function t()
	    if f then 
	    	f(parme)
	    end
	 end
	skynet.timeout(ti, t)
	return function(parme) f=nil end
end

-- 回收桌子
function CMD.recycleAgent(agent,deskId)
	--直接释放掉 不回收 创建的agent花销的时间太长
    -- desks[agent] = nil
    -- if nil ~= deskIds[deskId] then
    --     deskIds[deskId] = nil
    -- end
    print("-----agent------",agent)
    print("-----deskId------",deskId)
    print("-----deskId------",type(deskId))
    print("-----deskIds[deskId]------",deskIds)
    if deskIds[deskId] then
    	deskIds[deskId] = nil
    end
    exit_agent_timeout(500,exitAgent,agent)
end

function CMD.getDeskAgent(gameid)

	local ret = getAgent(gameid)
	if not ret then
		use_agent = use_agent + 1
		addAgent(1,gameid)
		return getAgent(gameid)
	else
		use_agent = use_agent + 1
		return ret
	end
end

function CMD.hallSeatDown(gameid,deskId)
	local agent = CMD.getDeskAgent(gameid)
	if agent then
		deskIds[deskId] = agent
		return agent
	end
end


--从预分配的桌子信息中取出一个空闲的桌子
function CMD.createDeskInfo(cluster_info,msg,ip,lat,lng)
	local recvobj  = cjson.decode(msg)
	print("-----------createDeskInfo------------",recvobj)
	local uid = math.floor(recvobj.uid)
	local user = getPlayerInfo(uid)
	recvobj.gameInfo.createUserInfo = {}
	recvobj.gameInfo.createUserInfo.uid = uid
	recvobj.gameInfo.createUserInfo.usericon = user.usericon
	recvobj.gameInfo.createUserInfo.playername = user.playername
	local gameid = recvobj.gameInfo.gameid
	local agent = CMD.getDeskAgent(gameid)

	local deskId = randomCode(6)
	deskIds[deskId] = agent

	local code,deskInfo,user = skynet.call(agent, "lua", "create", cluster_info,recvobj,ip,deskId,lat,lng)
	if code ~= 200 then
		CMD.recycleAgent(agent,deskId)
		return code
	end
	-- --创建成功把改房间通知到管理类中
	-- pcall(cluster.call, "master", ".mgrdesk", "apendDsmgr", GAME_NAME,deskId)

	local retobj = {}
	retobj.gameid = gameid
	retobj.errorCode = PDEFINE.RET.SUCCESS
	retobj.deskInfo = deskInfo
	local cluster_desk = {server = GAME_NAME,address = agent,gameid = gameid,deskId = deskId}
	pcall(cluster.call,"master",".agentdesk","joinDesk",cluster_desk,uid)

	return PDEFINE.RET.SUCCESS,cjson.encode(retobj),cluster_desk
end

function CMD.joinDeskInfo(cluster_info,msg,ip,lat,lng)
	local recvobj  = cjson.decode(msg)
	local deskId = recvobj.deskId
	local uid = math.floor(recvobj.uid)
	local agent = deskIds[deskId]
	if not agent then return 700 end 
	local code,deskInfo = skynet.call(agent, "lua", "join", cluster_info,recvobj,ip,lat,lng)
	if code ~= 200 then
		return code
	end
	local retobj = {}
	retobj.gameid = gameid
	retobj.errorCode = PDEFINE.RET.SUCCESS
	retobj.deskInfo = deskInfo

	local cluster_desk = {server = GAME_NAME,address = agent,deskId = deskId}
	pcall(cluster.call,"master",".agentdesk","joinDesk",cluster_desk,uid)
	return PDEFINE.RET.SUCCESS,cjson.encode(retobj),cluster_desk
end

function CMD.start()
	local gameList = PDEFINE_GAME.TYPE_INFO
	for _,gameInfo in pairs(gameList) do
		if gameInfo.STATE == 1 then
			agent_pool[gameInfo.ID] = {}
			addAgent(10,gameInfo.ID) 
		end
	end

	pcall(cluster.call, "master", ".mgrdesk", "joinDsmgr", GAME_NAME)
end

function CMD.insertUid()
	for i = 1, 10000 do
		local uidstr = randomCode(6)
		if #uidstr == 6 then 
			local uid = tonumber(uidstr)
			local sql = string.format("insert into s_user_id_list(uid)values(%d)",uid)
			local res = skynet.call(".mysqlpool", "lua", "execute", sql)
		end
	end
end

function test_mobile()
    local uid = 100176
    local mobile = 18525855928
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
    local content = string.format("【闲友】您的手机验证码:%d。若非本人操作,请忽略本短信。",code)
    local userid = 4679
    local user = 18525855928
    local pass = "xy101213"
    local sign = md5.sumhexa(user..pass..timestamp)
    local ok, body = skynet.call(webclient, "lua", "request", "http://39.104.28.149:8888/v2sms.aspx",nil,{action="send", userid=userid,timestamp=timestamp,sign=sign,mobile=mobile,content=content,sendTime="",extno=""}, nil,false)
    local sql = string.format("insert into s_user_bind()values(uid,code)values(%d,'%s')",uid,code)
    skynet.call(".mysqlpool", "lua", "execute", sql)
    --TODO 接验证码平台
    return PDEFINE.RET.SUCCESS
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)
	--test_mobile()
	--CMD.insertUid()
	skynet.register("."..SERVICE_NAME)
end)