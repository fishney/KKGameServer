local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local cjson = require "cjson"
local CMD = {}
--成功返回
local function resp(retobj)
    return PDEFINE.RET.SUCCESS, cjson.encode(retobj)
end

function CMD.bind(agent_handle)
    handle = agent_handle
end

--创建俱乐部
function CMD.createCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local name     = recvobj.name
	--查看该玩家俱乐部是否已经创建过俱乐部
	local sql = string.format("select * from s_clubs where uid = %d",uid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs >= 15 then
		return PDEFINE.RET.ERROR.CLUB_IS_CREATE
	end
	--查看该改俱乐部是否已经存在
	sql = string.format("select * from s_clubs where name = '%s'",name)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs == 1 then
		return PDEFINE.RET.ERROR.CLUB_NAME_EXIST
	end
	local createUser = getPlayerInfo(uid)
	local clubInfo = {}
	clubInfo.name = name
	clubInfo.cuid = uid
	clubInfo.img = "1" --TODO玩家的头像
	clubInfo.ctime = os.time()
	clubInfo.count = 1
	clubInfo.state = 1  --俱乐部状态:1：正常  0：冻结
	clubInfo.exitHave = 0 --有没有申请退出的 0：没有 1：有
	clubInfo.gamedeskNum = 0
	clubInfo.createPlayername = createUser.playername
	clubInfo.createIcon = createUser.usericon
	clubInfo.createUid = uid
	clubInfo.onlinInfo = {}
	clubInfo.clubGameList = {}
	clubInfo.deskAgentList = {}
	clubInfo.deskList = {}
	clubInfo.usersId = {}
	local clubid = getClubid(uid)
	assert(clubid)
	clubInfo.clubid = clubid
	local flag = creatClub(clubInfo)
	if flag  then
		skynet.call(".clubsmgr", "lua", "add", clubInfo)
		local clubList = skynet.call(".clubsmgr", "lua", "localGetClubList", uid)
		
		local retobj = {}
		retobj.code = PDEFINE.RET.SUCCESS
		retobj.response = {}
		retobj.response.errorCode = PDEFINE.RET.SUCCESS
		retobj.response.clubList = clubList
		return resp(retobj)
	end
	return PDEFINE.RET.ERROR.CREATE_ERROR
end

--申请俱乐部
function CMD.applyCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local clubInfo = getClubInfo(clubid)
    if not clubInfo then
    	return PDEFINE.RET.ERROR.CLUB_NOT_FIND
    end
    local cuid = clubInfo.cuid
	--是否已经在该俱乐部中
	sql = string.format("select * from s_club_users where clubid = %d and uid = %d",clubid,uid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs == 1 then
		return PDEFINE.RET.SUCCESS
	end

	--是否已经申请过
	sql = string.format("select * from s_club_apply where clubid = %d and uid = %d",clubid,uid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs == 1 then
		return PDEFINE.RET.SUCCESS
	end
	
	local info = {}
	info.cuid = cuid
	info.uid = uid
	info.clubid = clubid
	applyCulb(info)


	 --是否已经申请过
	sql = string.format("select * from s_club_apply where clubid = %d and cuid = %d order by applyTime asc",clubid,clubInfo.cuid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local applyList = {}
	local noty_retobj = {}
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.c =  8809
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			local applyInfo = {}
			applyInfo.uid = userInfo.uid
			applyInfo.applytime = os.date("%Y-%m-%d %H:%M", row.applyTime)
			applyInfo.playername = userInfo.playername
			applyInfo.usericon = userInfo.usericon
			
			table.insert( applyList, applyInfo )
		end
	end
	noty_retobj.response.applyList = applyList
	--通知被申请者
	pcall(cluster.call, "master", ".userCenter", "noityUserMessage", clubInfo.cuid, cjson.encode(noty_retobj))
	--通知房主
	return PDEFINE.RET.SUCCESS
end

--退出俱乐部
function CMD.exitCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local clubInfo = getClubInfo(clubid)
    if not clubInfo then
    	return PDEFINE.RET.ERROR.CLUB_NOT_FIND
    end
   	--是否在该俱乐部中
	local sql = string.format("select * from s_club_users where clubid = %d and uid = %d",clubid,uid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs < 1 then
		return PDEFINE.RET.ERROR.CLUB_NOT_EXIST
	end

	local cuid = clubInfo.cuid
	--是否已经在该俱乐部中
	sql = string.format("select * from s_club_exit where clubid = %d and uid = %d",clubid,uid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs == 1 then
		return PDEFINE.RET.SUCCESS
	end

	local info = {}
	info.cuid = cuid
	info.uid = uid
	info.clubid = clubid
	exitCulb(info)


	 --是否已经申请过
	--[[local sql = string.format("select * from s_club_exit where clubid = %d and cuid = %d order by applyTime asc",clubid,clubInfo.cuid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local exitList = {}
	local noty_retobj = {}
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.c =  8817
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			local applyInfo = {}
			applyInfo.uid = userInfo.uid
			applyInfo.applytime = os.date("%Y-%m-%d %H:%M", row.applyTime)
			applyInfo.playername = userInfo.playername
			applyInfo.usericon = userInfo.usericon
			
			table.insert( exitList, applyInfo )
		end
	end
	noty_retobj.response.exitList = exitList]]

	local noty_retobj = {}
	noty_retobj.c =  PDEFINE.NOTIFY.NOTY_APPLY_EXIT_CLUB
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.clubid = clubid
	--通知被申请者
	pcall(cluster.call, "master", ".userCenter", "noityUserMessage", clubInfo.cuid, cjson.encode(noty_retobj))
	--通知房主
	return PDEFINE.RET.SUCCESS
end

--获取申请俱乐部列表
function CMD.getApplyListCulb(msg)
	local recvobj = cjson.decode(msg)
	local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    --是否已经申请过
	local sql = string.format("select * from s_club_apply where clubid = %d and cuid = %d order by applyTime asc",clubid,uid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local applyList = {}
	local retobj = {}
	retobj.code = PDEFINE.RET.SUCCESS
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			local applyInfo = {}
			applyInfo.uid = userInfo.uid
			applyInfo.applytime = os.date("%Y-%m-%d %H:%M", row.applyTime)
			applyInfo.playername = userInfo.playername
			applyInfo.usericon = userInfo.usericon
			
			table.insert( applyList, applyInfo )
		end
	end
	retobj.response.applyList = applyList
	return resp(retobj)
end

--获取申请退出俱乐部列表
function CMD.getExitListCulb(msg)
	local recvobj = cjson.decode(msg)
	local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    --是否已经申请过
	local sql = string.format("select * from s_club_exit where clubid = %d and cuid = %d order by applyTime asc",clubid,uid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local exitList = {}
	local retobj = {}
	retobj.code = PDEFINE.RET.SUCCESS
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			local applyInfo = {}
			applyInfo.uid = userInfo.uid
			applyInfo.applytime = os.date("%Y-%m-%d %H:%M", row.applyTime)
			applyInfo.playername = userInfo.playername
			applyInfo.usericon = userInfo.usericon
			
			table.insert( exitList, applyInfo )
		end
	end
	retobj.response.exitList = exitList
	return resp(retobj)
end

--同意退出俱乐部
function CMD.agreeExitCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local exitUid     = math.floor(recvobj.applyUid)
    local playerInfo = getPlayerInfo(uid)
  	local sql = string.format("delete from s_club_users where clubid = %d and uid = %d",clubid,exitUid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

	sql = string.format("delete from s_club_exit where clubid = %d and uid = %d",clubid,exitUid)
	skynet.call(".mysqlpool", "lua", "execute", sql)

	sql = string.format("select * from s_club_exit where clubid = %d and cuid = %d order by applyTime asc",clubid,uid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local exitList = {}
	local retobj = {}
	retobj.code = PDEFINE.RET.SUCCESS
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			local exitInfo = {}
			exitInfo.uid = userInfo.uid
			exitInfo.applytime = os.date("%Y-%m-%d %H:%M", row.applyTime)
			exitInfo.playername = userInfo.playername
			exitInfo.usericon = userInfo.usericon
			
			table.insert( exitList, exitInfo )
		end
	end
	retobj.response.exitList = exitList

	local clubList = skynet.call(".clubsmgr", "lua", "localGetClubList", exitUid)
	local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_GET_CLUB_LIST
	noty_retobj.response = {}
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.clubList = clubList
	--通知被申请者
	pcall(cluster.call, "master", ".userCenter", "noityUserMessage", exitUid, cjson.encode(noty_retobj))

    return resp(retobj)
end

--同意进去俱乐部
function CMD.agreeCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local applyUid     = math.floor(recvobj.applyUid)
    local playerInfo = getPlayerInfo(uid)
    local sql = string.format("insert into s_club_users(clubid,uid,cuid,fastTime,joinTime)values(%d,%d,%d,%d,%d)",clubid,applyUid,uid,os.time(),os.time())
	skynet.call(".mysqlpool", "lua", "execute", sql)

	sql = string.format("delete from s_club_apply where clubid = %d and uid = %d",clubid,applyUid)
	skynet.call(".mysqlpool", "lua", "execute", sql)

	sql = string.format("select * from s_club_apply where clubid = %d and cuid = %d order by applyTime asc",clubid,uid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local applyList = {}
	local retobj = {}
	retobj.code = PDEFINE.RET.SUCCESS
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			local applyInfo = {}
			applyInfo.uid = userInfo.uid
			applyInfo.applytime = os.date("%Y-%m-%d %H:%M", row.applyTime)
			applyInfo.playername = userInfo.playername
			applyInfo.usericon = userInfo.usericon
			
			table.insert( applyList, applyInfo )
		end
	end
	retobj.response.applyList = applyList

	local clubList = skynet.call(".clubsmgr", "lua", "localGetClubList", applyUid)
	local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_GET_CLUB_LIST
	noty_retobj.response = {}
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.clubList = clubList
	--通知被申请者
	pcall(cluster.call, "master", ".userCenter", "noityUserMessage", applyUid, cjson.encode(noty_retobj))

    return resp(retobj)
end

--全部同意进去俱乐部
function CMD.allAgreeCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local applyList     = recvobj.applyList
    for _,applyUid in pairs(applyList) do
	    local sql = string.format("insert into s_club_users(clubid,uid,cuid,fastTime,joinTime)values(%d,%d,%d,%d,%d)",clubid,applyUid,uid,os.time(),os.time())
		skynet.call(".mysqlpool", "lua", "execute", sql)

		sql = string.format("delete from s_club_apply where clubid = %d and uid = %d",clubid,applyUid)
		local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

		local clubList = skynet.call(".clubsmgr", "lua", "localGetClubList", applyUid)
		local noty_retobj = {}
		noty_retobj.c = PDEFINE.NOTIFY.NOTY_GET_CLUB_LIST
		noty_retobj.code = PDEFINE.RET.SUCCESS
		noty_retobj.response = {}
		noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
		noty_retobj.response.clubList = clubList
		--通知被申请者
		pcall(cluster.call, "master", ".userCenter", "noityUserMessage", applyUid, cjson.encode(noty_retobj))
	end
	return PDEFINE.RET.SUCCESS
end

--全部同意退出俱乐部
function CMD.allExitCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local exitList     = recvobj.applyList
    for _,exitUid in pairs(exitList) do
		local sql = string.format("delete from s_club_users where clubid = %d and uid = %d",clubid,exitUid)
		local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

		sql = string.format("delete from s_club_exit where clubid = %d and uid = %d",clubid,exitUid)
		rs = skynet.call(".mysqlpool", "lua", "execute", sql)

		local clubList = skynet.call(".clubsmgr", "lua", "localGetClubList", exitUid)
		local noty_retobj = {}
		noty_retobj.c = PDEFINE.NOTIFY.NOTY_GET_CLUB_LIST
		noty_retobj.code = PDEFINE.RET.SUCCESS
		noty_retobj.response = {}
		noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
		noty_retobj.response.clubList = clubList
		--通知被申请者
		pcall(cluster.call, "master", ".userCenter", "noityUserMessage", exitUid, cjson.encode(noty_retobj))
	end
	return PDEFINE.RET.SUCCESS
end

--拒绝进入俱乐部
function CMD.refuseCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local applyUid     = math.floor(recvobj.applyUid)

	local sql = string.format("delete from s_club_apply where clubid = %d and uid = %d",clubid,applyUid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

	sql = string.format("select * from s_club_apply where clubid = %d and cuid = %d order by applyTime asc",clubid,uid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local applyList = {}
	local retobj = {}
	retobj.code = PDEFINE.RET.SUCCESS
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			local applyInfo = {}
			applyInfo.uid = userInfo.uid
			applyInfo.applytime = os.date("%Y-%m-%d %H:%M", row.applyTime)
			applyInfo.playername = userInfo.playername
			applyInfo.usericon = userInfo.usericon
			
			table.insert( applyList, applyInfo )
		end
	end
	retobj.response.applyList = applyList
    return resp(retobj)
end

--拒绝退出俱乐部
function CMD.refuseExitCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local exitUid     = math.floor(recvobj.applyUid)

	local sql = string.format("delete from s_club_exit where clubid = %d and uid = %d",clubid,exitUid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

	sql = string.format("select * from s_club_exit where clubid = %d and cuid = %d order by applyTime asc",clubid,uid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local exitList = {}
	local retobj = {}
	retobj.code = PDEFINE.RET.SUCCESS
	retobj.response = {}
	retobj.response.errorCode = PDEFINE.RET.SUCCESS
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			local exitInfo = {}
			exitInfo.uid = userInfo.uid
			exitInfo.applytime = os.date("%Y-%m-%d %H:%M", row.applyTime)
			exitInfo.playername = userInfo.playername
			exitInfo.usericon = userInfo.usericon
			
			table.insert( exitList, exitInfo )
		end
	end
	retobj.response.exitList = exitList
    return resp(retobj)
end

--解除冻结俱乐部
--冻结俱乐部
function CMD.freezeCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local state     = math.floor(recvobj.state) --0 冻结 1解冻
    local clubInfo = getClubInfo(clubid)
    if not clubInfo then
    	return PDEFINE.RET.ERROR.CLUB_NOT_FIND
    end
    
    if uid ~= clubInfo.cuid then
    	return PDEFINE.RET.ERROR.CLUB_NOT_CREATE
    end

    local sql = string.format("update s_clubs set state = %d where clubid = %d and uid = %d",state,clubid,uid)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

    skynet.call(".clubsmgr", "lua", "updateState", clubid,state)
    

    local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_FREEZE
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.clubid = clubid
	noty_retobj.response.state = state
	skynet.call(".clubsmgr", "lua", "notyClubInfo", clubid, noty_retobj)
	local retobj = {}
	retobj.code = PDEFINE.RET.SUCCESS
	retobj.errorCode = PDEFINE.RET.SUCCESS
	retobj.state = state
	return resp(retobj)
end

--解散俱乐部
function CMD.dissolveCulb(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local clubInfo = getClubInfo(clubid)
    if not clubInfo then
    	return PDEFINE.RET.ERROR.CLUB_NOT_FIND
    end
    
    if uid ~= clubInfo.cuid then
    	return PDEFINE.RET.ERROR.CLUB_NOT_CREATE
    end

    local noty_retobj = {}
	noty_retobj.c = PDEFINE.NOTIFY.NOTY_CLUB_DISSOLVE
	noty_retobj.code = PDEFINE.RET.SUCCESS
	noty_retobj.response = {}
	noty_retobj.response.errorCode = PDEFINE.RET.SUCCESS
	noty_retobj.response.clubid = clubid
	
	skynet.call(".clubsmgr", "lua", "notyClubInfo", clubid, noty_retobj)

	skynet.call(".clubsmgr", "lua", "del", clubid)
	local sql = string.format("delete from s_club_users where clubid = %d",clubid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

    sql = string.format("delete from s_clubs where clubid = %d and cuid = %d",clubid,uid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)

	sql = string.format("delete from s_club_games where clubid = %d",clubid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)

	return PDEFINE.RET.SUCCESS
end

--获取俱乐部成员
function CMD.getClubMember(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid) 
    local clubid     = math.floor(recvobj.clubid)
    local selectTime = recvobj.selectTime
    local clubInfo = getClubInfo(clubid)

    if not clubInfo then
    	return PDEFINE.RET.ERROR.CLUB_NOT_FIND
    end

    if uid ~= clubInfo.cuid then
    	return PDEFINE.RET.ERROR.CLUB_NOT_CREATE
    end

    local sql = string.format("select * from s_club_users where clubid = %d",clubid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local memberList = {}
	if #rs > 0 then
		for _, row in pairs(rs) do
			local userInfo = getPlayerInfo(row.uid)
			sql = string.format("select * from s_big_record where uid = %d and selectTime = '%s' and clubid = %d order by time asc  ",row.uid,selectTime,clubid)
			local bigRecodeList = skynet.call(".mysqlpool", "lua", "execute", sql)
			local bigWinCnt = 0
			local totalScore = 0
			local jushu = 0
			for _, data in pairs(bigRecodeList) do
				if data.isBigWin == 1 then
					bigWinCnt = bigWinCnt + 1
				end
				totalScore = totalScore + data.score
				jushu = jushu + 1
			end
			local isOnLine = skynet.call(".clubsmgr", "lua", "getUserIsOnline", clubid, row.uid)
			
			local memberInfo = {}
			memberInfo.isOnLine = isOnLine --1表示在线 0表示空闲
			memberInfo.jushu = jushu
			memberInfo.totalScore = totalScore
			memberInfo.cost = 0
			memberInfo.uid = row.uid
			memberInfo.bigWinCnt = bigWinCnt
			memberInfo.playername = userInfo.playername
			memberInfo.usericon = userInfo.usericon
			table.insert( memberList, memberInfo )
		end
	end
	local retobj  = {}
    retobj.c = math.floor(recvobj.c)
    retobj.code   = PDEFINE.RET.SUCCESS
    retobj.uid    = uid
    retobj.clubid = clubid
    retobj.memberList = memberList
	return resp(retobj)
end

--踢出俱乐部
function CMD.kickClub(msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid) 
    local clubid     = math.floor(recvobj.clubid)
    local kickUid = math.floor(recvobj.kickUid)
    local clubInfo = getClubInfo(clubid)

    if not clubInfo then
    	return PDEFINE.RET.ERROR.CLUB_NOT_FIND
    end

    if uid ~= clubInfo.cuid then
    	return PDEFINE.RET.ERROR.CLUB_NOT_CREATE
    end

    local sql = string.format("delete from s_club_users where clubid = %d and uid = %d",clubid,kickUid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)

	return PDEFINE.RET.SUCCESS
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.retpack(f(...))
	end)
	skynet.register(".clubsaction")
end)
