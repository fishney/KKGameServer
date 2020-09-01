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
local CMD = {}
local handle
local UID
local SEND_COIN = 0 --初始账号赠送金币
local report_service = require "report_service"
local webclient = nil
local playerdatamgr = require "datacenter.playerdatamgr"
local game_tool = require "game_tool"
local growup_tool = require "growup_tool"

--成功返回
local function resp(retobj)
    return PDEFINE.RET.SUCCESS, cjson.encode(retobj)
end

--获取玩家信息
local function getPlayerInfo(uid)
	local playerData = handle.dcCall("user_dc", "get", uid)
	assert(playerData)
	return playerData
end

function CMD.bind(agent_handle)
    handle = agent_handle
end

--创建俱乐部
function CMD.createCulb(source, msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local name     = recvobj.name
	--查看该玩家俱乐部是否已经创建过俱乐部
	local sql = string.format("select * from s_clubs where uid = %d",uid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs == 1 then
		return PDEFINE.RET.ERROR.CLUB_IS_CREATE
	end
	--查看该改俱乐部是否已经存在
	sql = string.format("select * from s_clubs where name = '%s'",name)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs == 1 then
		return PDEFINE.RET.ERROR.CLUB_NAME_EXIST
	end
	local clubInfo = {}
	clubInfo.name = name
	clubInfo.cuid = uid
	clubInfo.img = "1" --TODO玩家的头像
	clubInfo.ctime = os.time()
	clubInfo.count = 1
	sql = string.format("insert into s_clubs(cuid,name,img,ctime,count)values(%d,'%s','%s',%d,%d)",clubInfo.cuid,clubInfo.name,clubInfo.img,clubInfo.ctime,clubInfo.count)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if rs.insert_id > 0 then
		clubInfo.clubid = rs.insert_id
		local retobj = {}
		retobj.response = {}
		retobj.response.errorCode = PDEFINE.RET.SUCCESS
		retobj.response.clubInfo = {}
		retobj.response.clubInfo = clubInfo
		return resp(retobj)
	end
end

--申请俱乐部
function CMD.applyCulb(source, msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local clubid     = math.floor(recvobj.clubid)
    local sql = string.format("select * from s_clubs where clubid = %d",clubid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs ~= 1 then
		return PDEFINE.RET.ERROR.CLUB_NOT_FIND
	end
	--是否已经在该俱乐部中
	sql = string.format("select * from s_club_users where clubid = %d",clubid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs == 1 then
		return PDEFINE.RET.SUCCESS
	end
	--是否已经申请过
	sql = string.format("select * from s_club_apply where clubid = %d",clubid)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	if #rs == 1 then
		return PDEFINE.RET.SUCCESS
	end
	local cuid = rs[1].cuid
	local app_time = os.time()
	sql = string.format("insert into s_club_apply(cuid,clubid,uid,app_time)values(%d,%d,%d,%d)",cuid,clubid,uid,app_time)
	rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	return PDEFINE.RET.SUCCESS
end

--同意进去俱乐部
function CMD.agreeCulb(source, msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    local applyUid     = math.floor(recvobj.applyUid)
    local playerInfo = getPlayerInfo(uid)
    if playerInfo.clubid > 0 then
    	local sql = string.format("insert into s_club_users(clubid,uid,jtime,playername,usericon)values(%d,%d,%d)")
    end
end

--进入俱乐部
function CMD.joinCulb(source, msg)
	local recvobj = cjson.decode(msg)
    local uid     = math.floor(recvobj.uid)
    getPlayerInfo(uid)
end
return CMD
