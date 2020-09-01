local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local cjson = require "cjson"
local queue = require "skynet.queue"
local cs = queue() 
local CMD = {}
local clubList = {}
--成功返回
local function resp(retobj,param1)
    return PDEFINE.RET.SUCCESS, cjson.encode(retobj)
end


--玩家创建俱乐部时信息
function CMD.add(clubInfo)
	clubList[clubInfo.clubid] = clubInfo
end

--更新俱乐部状态
function CMD.updateState(clubid,state)
	clubList[clubid].state = state
end

--玩家创建俱乐部时信息
function CMD.del(clubid)
	clubList[clubid] = clubid
end

function CMD.addDeskAgent(cliubid,agent)
	clubList[cliubid].deskAgentList[agent] = agent
end

function CMD.delDeskAgent(cliubid,agent)
	clubList[cliubid].deskAgentList[agent] = nil
end

--通知大厅玩家刷新列表
function CMD.notyClubInfo(clubid,noty_retobj,puid)
	local onlinInfo = clubList[clubid].onlinInfo
	if puid then
		for uid,_ in pairs(onlinInfo) do
			if puid ~= uid then
				pcall(cluster.call, "master", ".userCenter", "noityUserMessage", uid, cjson.encode(noty_retobj))
			end
		end
	else
		for uid,_ in pairs(onlinInfo) do
			pcall(cluster.call, "master", ".userCenter", "noityUserMessage", uid, cjson.encode(noty_retobj))
		end
	end
end

--获取俱乐部成员是否在线
function CMD.getUserIsOnline(clubid,uid)
	local user = clubList[clubid].onlinInfo[uid]
	if user then
		return user.state
	end
	return 0
end

function CMD.setOnline(uid,clubid,state)
	if clubList[clubid] and clubList[clubid].onlinInfo[uid] then
		clubList[clubid].onlinInfo[uid].state = state
	end
end

function CMD.notyRead(uid,clubid,state)
	if clubList[clubid] and clubList[clubid].onlinInfo[uid] then
		clubList[clubid].onlinInfo[uid].state = state
	end
	local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DEL_DESK
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.deskId = deskid
	clubList[gameInfo.clubid].deskList[deskid] = nil
	clubList[gameInfo.clubid].gamedeskNum = clubList[gameInfo.clubid].gamedeskNum - 1
	CMD.notyClubInfo(gameInfo.clubid,noty_retobj)
end

--从桌子上删除对应的列表
function CMD.deltelUser(uid,clubid,deskId,isExit)
	local flag = nil
	for i,user in pairs(clubList[clubid].deskList[deskId].users) do
		if user.uid == uid then
			--通知大厅玩家改桌子发生变动
			table.remove(clubList[clubid].deskList[deskId].users,i)
			flag = true
			break
		end
	end
	if flag then
		clubList[clubid].usersId[uid] = nil
		local noty_retobj = {}
		noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DESK_CHANGE
		noty_retobj.response = {}
		noty_retobj.code = PDEFINE.RET.SUCCESS
		noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
		noty_retobj.response.hallDeskInfo = clubList[clubid].deskList[deskId]
		CMD.notyClubInfo(clubid,noty_retobj)
		pcall(cluster.call,"master",".agentdesk","removeDesk",uid)
		--clubList[clubid].onlinInfo[uid] = nil
		if #clubList[clubid].deskList[deskId].users == 0 then
			CMD.delDesk(clubList[clubid].deskList[deskId].config,deskId)
			--如果有新的桌子就需要回收,没有就不管
		end
	end
end

--更新桌子准备信息
function CMD.userReady(uid,clubid,deskId)
	for i,user in pairs(clubList[clubid].deskList[deskId].users) do
		if user.uid == uid then
			--通知大厅玩家改桌子发生变动
			clubList[clubid].deskList[deskId].users[i].state = 1
			break
		end
	end

	--通知大厅玩家改桌子发生变动
	local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DESK_CHANGE
	noty_retobj.response = {}
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.hallDeskInfo = clubList[clubid].deskList[deskId]
	CMD.notyClubInfo(clubid,noty_retobj)
end


function CMD.updateRound(clubid,deskId,round)
	clubList[clubid].deskList[deskId].round = round
	clubList[clubid].deskList[deskId].state = 1
	for i,user in pairs(clubList[clubid].deskList[deskId].users) do
		clubList[clubid].deskList[deskId].users[i].state = 2
	end
	--通知大厅玩家改桌子发生变动
	local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DESK_CHANGE
	noty_retobj.response = {}
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.hallDeskInfo = clubList[clubid].deskList[deskId]
	CMD.notyClubInfo(clubid,noty_retobj)
end

--更新桌子准备信息
function CMD.deskGameStart(clubid,deskId,round)
	clubList[clubid].deskList[deskId].state = 1
	clubList[clubid].deskList[deskId].round = round
	local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DESK_ROUND
	noty_retobj.response = {}
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.round = round
	CMD.notyClubInfo(clubid,noty_retobj)
end

--服务器重启时重新加载所有俱乐部
local function reloadClubsInfo()
	local sql = string.format("select * from s_clubs")
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	for _,row in pairs(rs) do
		local createUser = getPlayerInfo(row.cuid)
		sql = string.format("select * from s_club_games where clubid = %d",row.clubid)
		local clubGameList = skynet.call(".mysqlpool", "lua", "execute", sql)
		
		local sql = string.format("select * from s_club_users where clubid = %d",row.clubid)
		local clubUsers = skynet.call(".mysqlpool", "lua", "execute", sql)

		local clubInfo = {}
		clubInfo.clubid = row.clubid
		clubInfo.name = row.name
		clubInfo.img = row.img
		clubInfo.ctime = row.ctime
		clubInfo.count = #clubUsers
		clubInfo.state = row.state  --俱乐部状态:1：正常  0：冻结
		clubInfo.createUid = row.cuid
		clubInfo.createIcon = createUser.usericon
		clubInfo.createPlayername = serializePlayername(createUser.playername)
		clubInfo.gamedeskNum = 0
		clubInfo.onlinInfo = {}
		clubInfo.clubGameList = clubGameList
		clubInfo.deskAgentList = {}
		clubInfo.deskList = {}
		clubInfo.usersId = {}
		for _,gameInfo in pairs(clubGameList) do
			gameInfo.createUserInfo = {uid = createUser.uid,playername = clubInfo.createPlayername, usericon = createUser.usericon}
	    	local deskInfo = {}
		    deskInfo.config = gameInfo
		    deskInfo.state = 0
		    deskInfo.round = 0
		    deskInfo.totalRound = gameInfo.gamenum
		    deskInfo.deskid = randomCode(6)
		    deskInfo.users = {}
		    clubInfo.deskList[deskInfo.deskid] = deskInfo
	    end
	    sql = string.format("select * from s_club_exit where clubid = %d",row.clubid)
		rs = skynet.call(".mysqlpool", "lua", "execute", sql)
		if #rs ~= 0 then
			clubInfo.exitHave = 1
		else
			clubInfo.exitHave = 0
		end
	    clubList[row.clubid] = clubInfo
	end
end

local function getClubOnlineNum(clubid)
	local onlineNum = 0
	for _, user in pairs(clubList[clubid].onlinInfo) do
		if user.state == 0 then
			onlineNum = onlineNum + 1
		end
	end
	return onlineNum
end

--获取俱乐部在线人数 或者刷新在线人数
function CMD.getClubeOnlineUsers(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local onlineNum = 0
    local clubUsers = {}
    for _, user in pairs(clubList[clubid].onlinInfo) do
		if user.state == 0 then
			onlineNum = onlineNum + 1
			table.insert(clubUsers,user)
		end
	end
	local retobj = {}
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	retobj.response.onlineNum = onlineNum
	retobj.response.clubUsers = clubUsers
	return resp(retobj)
end

local function sortDeskList( a ,b)
	if #a.users < #b.users then
    	return true
    elseif #a.users == #b.users then
    	if a.config.playtype < b.config.playtype then
    		return true
    	else
    		return false
    	end
    else
    	return false
    end
end

-- --返回大厅
-- function CMD.backHall(msg)
-- 	local recvobj = cjson.decode(msg)
--     local uid     = math.floor(recvobj.uid)
--     local clubid     = math.floor(recvobj.clubid) --客户端返回到大厅的时候 把俱乐部ID 跟桌子ID传过来(如果本就没有桌子就传0)
--     local deskId     = math.floor(recvobj.deskId)
--     clubList[clubid].deskList[deskId].users
-- end

--进入俱乐部 
function CMD.joinCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local tmpDeskList = table.copy(clubList[clubid].deskList)
    local retDeskList = {}
    for _, deskInfo in pairs(tmpDeskList) do
    	table.insert(retDeskList,deskInfo)
    end
    table.sort(retDeskList, sortDeskList)
    setUserClubValue(clubid,uid,"fastTime",os.time())
    local playerInfo = getPlayerInfo(uid)
    playerInfo.state = 0
    clubList[clubid].onlinInfo[uid] = playerInfo
    local retobj = {}
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	retobj.response.deskList = retDeskList
	return resp(retobj)
end

--获取俱乐部列表
function CMD.localGetClubList(uid)
    local localclubList = {}
    local sql  = string.format("select * from s_club_users where uid = %d order by fastTime desc ",uid)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs > 0 then
    	for _,row in pairs(rs) do
		    local clubInfo = {}
			clubInfo.clubid = row.clubid
			clubInfo.createPlayername = clubList[row.clubid].createPlayername
			clubInfo.createIcon = clubList[row.clubid].createIcon
			clubInfo.name = clubList[row.clubid].name
			clubInfo.state = clubList[row.clubid].state
			clubInfo.img = clubList[row.clubid].img
			clubInfo.ctime = clubList[row.clubid].ctime
			clubInfo.count = clubList[row.clubid].count
			clubInfo.gamedeskNum = clubList[row.clubid].gamedeskNum
			clubInfo.createUid = clubList[row.clubid].createUid
			clubInfo.onlineNum = getClubOnlineNum(row.clubid)
			clubInfo.clubGameList = clubList[row.clubid].clubGameList

			local sql = string.format("select * from s_club_exit where clubid = %d",row.clubid)
			local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
			if #rs ~= 0 then
				clubInfo.exitHave = 1
			else
				clubInfo.exitHave = 0
			end
			table.insert(localclubList, clubInfo)
		end
	end
	return localclubList
end

--获取俱乐部列表
function CMD.getClubList(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubList = localGetClubList(uid)
   
	local retobj = {}
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	retobj.response.clubList = clubList
	return resp(retobj)
end
--
function CMD.addGame(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local gameInfo = recvobj.gameInfo
    print("-----addGame--------",gameInfo)
    local sql = string.format("select * from s_club_games where clubid = %d and gameid = %d and seat = %d and score = %d and param1 = %d and gamenum = %d ",gameInfo.clubid,gameInfo.gameid,gameInfo.seat,gameInfo.score,gameInfo.param1,gameInfo.gamenum)
	local clubGameInfo = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #clubGameInfo > 0 then
		return PDEFINE.RET.ERROR.CLUB_GAME_TYPE_ALREADY
	end

    --gameInfo.param1 --中庄家方式
    --gameInfo.trustee = param2
    local sql = string.format("select * from s_club_games where clubid = %d",gameInfo.clubid)
	local clubGameList = skynet.call(".mysqlpool", "lua", "execute", sql)
	local playtype = #clubGameList + 1
	gameInfo.playtype = playtype
	local createUser = getPlayerInfo(uid)
	gameInfo.createUserInfo = {uid = createUser.uid,playername = serializePlayername(createUser.playername), usericon = createUser.usericon}
	
    local sql = string.format("insert into s_club_games(clubid,gameid,state,seat,gamenum,ipcheck,distance,tname,playtype,score,isdissolve,param1,param2)values(%d,%d,%d,%d,%d,%d,%d,'%s',%d,%d,%d,%d,%d)",gameInfo.clubid,gameInfo.gameid,1,gameInfo.seat,gameInfo.gamenum,gameInfo.ipcheck,gameInfo.distance,gameInfo.tname,playtype,gameInfo.score,gameInfo.isdissolve,gameInfo.param1,gameInfo.trustee)
    skynet.call(".mysqlpool", "lua", "execute", sql)

    local deskInfo = {}
    deskInfo.config = gameInfo
    deskInfo.deskid = randomCode(6)
    deskInfo.users = {}
    deskInfo.state = 0
	deskInfo.round = 0
	deskInfo.totalRound = gameInfo.gamenum
    deskInfo.deskAgent = deskAgent
    clubList[gameInfo.clubid].deskList[deskInfo.deskid] = deskInfo

    local ok, dagent = pcall(cluster.call, "game", ".dsmgr", "getDeskAgent", gameInfo.gameid)
    local deskAgent
    if dagent then
    	deskAgent = {}
    	deskAgent.server = "game"
    	deskAgent.address = dagent
    	
    	pcall(cluster.call, deskAgent.server, deskAgent.address, "initDeskConfig", gameInfo, deskInfo.deskid)
    end
    

    local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_ADD_DESK
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.addDeskInfo = deskInfo

	--通知被申请者
	CMD.notyClubInfo(gameInfo.clubid,noty_retobj)
	--pcall(cluster.call, "master", ".userCenter", "noityUserMessage", uid, cjson.encode(noty_retobj))

	return PDEFINE.RET.SUCCESS
end

function CMD.delDesk(gameInfo,deskid,isExit)
	local deskAgent = clubList[gameInfo.clubid].deskList[deskid].deskAgent
    pcall(cluster.call, "game", ".dsmgr", "recycleAgent",deskAgent.address, deskid)
    local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DEL_DESK
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.deskId = deskid
	clubList[gameInfo.clubid].deskList[deskid] = nil
	CMD.notyClubInfo(gameInfo.clubid,noty_retobj)

	--通知被申请者
	--pcall(cluster.call, "master", ".userCenter", "noityUserMessage", uid, cjson.encode(noty_retobj))

	return PDEFINE.RET.SUCCESS
end

function CMD.deleteDesk(msg)
	local recvobj = cjson.decode(msg)
	local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local deskid = recvobj.deskid

    local gameInfo = clubList[clubid].deskList[deskid].config
    local sql = string.format("select * from s_club_games where clubid = %d and gameid = %d and seat = %d and score = %d and param1 = %d and gamenum = %d ",gameInfo.clubid,gameInfo.gameid,gameInfo.seat,gameInfo.score,gameInfo.param1,gameInfo.gamenum)
	local clubGameInfo = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #clubGameInfo > 0 then
		sql = string.format("delete from s_club_games where clubid = %d and gameid = %d and seat = %d and score = %d and param1 = %d and gamenum = %d ",gameInfo.clubid,gameInfo.gameid,gameInfo.seat,gameInfo.score,gameInfo.param1,gameInfo.gamenum)
		skynet.call(".mysqlpool", "lua", "execute", sql)
	end

    local deskAgent = clubList[clubid].deskList[deskid].deskAgent
    if deskAgent then
    	CMD.delDeskAgent(clubid,deskAgent)
    end
    local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DEL_DESK
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.deskId = deskid
	clubList[gameInfo.clubid].deskList[deskid] = nil
	clubList[gameInfo.clubid].gamedeskNum = clubList[gameInfo.clubid].gamedeskNum - 1
	CMD.notyClubInfo(gameInfo.clubid,noty_retobj)

	return PDEFINE.RET.SUCCESS
end

function CMD.addDesk(gameInfo,uid)
	print("---------addDesk----------",gameInfo)
    local deskInfo = {}
    deskInfo.config = gameInfo
    deskInfo.deskid = randomCode(6)
    deskInfo.users = {}
    deskInfo.state = 0
	deskInfo.round = 0
	deskInfo.totalRound = gameInfo.gamenum
    clubList[gameInfo.clubid].deskList[deskInfo.deskid] = deskInfo
	clubList[gameInfo.clubid].gamedeskNum = clubList[gameInfo.clubid].gamedeskNum + 1

    local ok, dagent = pcall(cluster.call, "game", ".dsmgr", "getDeskAgent", gameInfo.gameid)
    local deskAgent
    if dagent then
    	deskAgent = {}
    	deskAgent.server = "game"
    	deskAgent.address = dagent
    	
    	pcall(cluster.call, deskAgent.server, deskAgent.address, "initDeskConfig", gameInfo, deskInfo.deskid)
    end
    deskInfo.deskAgent = deskAgent

    local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_ADD_DESK
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.addDeskInfo = deskInfo
	skynet.sleep(100)
	CMD.notyClubInfo(gameInfo.clubid,noty_retobj,uid)
	--通知被申请者
	--pcall(cluster.call, "master", ".userCenter", "noityUserMessage", uid, cjson.encode(noty_retobj))

	return PDEFINE.RET.SUCCESS
end

function CMD.hallSeatDown(msg,cluster_info,ip, lat, lng)
	return cs(function()
		local recvobj = cjson.decode(msg)
	    local uid     = math.floor(recvobj.uid)
	    local clubid = math.floor(recvobj.clubid)
	    
	    local state = clubList[clubid].state
	    local deskId = recvobj.deskId
	    if clubList[clubid].usersId[uid] and clubList[clubid].usersId[uid] ~= deskId then
	    	return PDEFINE_ERRCODE.ERROR.GAME_ING_ERROR
	    end
	    
	    if not clubList[clubid].deskList[deskId] then
	    	return PDEFINE.RET.ERROR.NOT_DESK_INFO
	    end

	    local tmpDeskAgent = clubList[clubid].deskList[deskId].deskAgent
	    local gameInfo = clubList[clubid].deskList[deskId].config
	    if not tmpDeskAgent then
	    	local ok, dagent = pcall(cluster.call, "game", ".dsmgr", "hallSeatDown", gameInfo.gameid,deskId)
		    local deskAgent
		    if dagent then 
		    	deskAgent = {}
		    	deskAgent.server = "game"
		    	deskAgent.address = dagent
		    	
		    	pcall(cluster.call, deskAgent.server, deskAgent.address, "initDeskConfig", gameInfo, deskId)
		    	tmpDeskAgent = deskAgent
		    	clubList[clubid].deskList[deskId].deskAgent = tmpDeskAgent
		    end
	    end
	    local ok, code, deskInfo,user = pcall(cluster.call, tmpDeskAgent.server, tmpDeskAgent.address, "hallJoin", uid, cluster_info, ip, lat, lng, state)
	    if code ~= PDEFINE.RET.SUCCESS then
	    	return code
	    end

	    if clubList[clubid].usersId[uid] then
		    local retobj = {}
			retobj.response = {}
			retobj.response.errorCode = PDEFINE.RET.SUCCESS
			retobj.response.deskInfo = deskInfo
			return PDEFINE.RET.SUCCESS, cjson.encode(retobj), tmpDeskAgent
		else
			if user then
		    	table.insert(clubList[clubid].deskList[deskId].users,user)
		    	clubList[clubid].usersId[uid] = deskId
		    	pcall(cluster.call,"master",".agentdesk","joinDesk",tmpDeskAgent,uid)
		    end
		end
	    

	    --通知大厅玩家改桌子发生变动
	    local noty_retobj = {}
	    noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DESK_CHANGE
		noty_retobj.response = {}
		noty_retobj.code = PDEFINE.RET.SUCCESS
		noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
		noty_retobj.response.hallDeskInfo = clubList[clubid].deskList[deskId]
	   	CMD.notyClubInfo(clubid,noty_retobj)

	    local retobj = {}
		retobj.response = {}
		retobj.response.errorCode = PDEFINE.RET.SUCCESS
		retobj.response.deskInfo = deskInfo
		local isAddDesk = true
		for _,desk in pairs(clubList[clubid].deskList) do
			if desk.config.playtype == gameInfo.playtype then
				if #desk.users == 0 then
					isAddDesk = false
					break
				end
			end
		end
		if isAddDesk then
			CMD.addDesk(gameInfo,uid)
		end
		return PDEFINE.RET.SUCCESS, cjson.encode(retobj), tmpDeskAgent
	end)
end


function CMD.modifGame(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid = math.floor(recvobj.clubid)
    local gameInfo = recvobj.gameInfo
end

function CMD.start()
	reloadClubsInfo()
end


skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.retpack(f(...))
	end)
	skynet.register(".clubsmgr")
end)
