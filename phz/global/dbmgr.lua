local skynet = require "skynet"

function getPlayerInfo(uid)
	local sql = string.format("select * from d_user where uid = %d",uid)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs == 1 then
    	return rs[1]
    end
    return nil
end

function setPlayerValue(uid,filed,value)
	local sql
	if type(value) == 'string' then
		sql = string.format("update d_user set %s = '%s' where uid = %d ",filed, value, uid)
	end
	if type(value) == 'number' then
		sql = string.format("update d_user set %s = %d where uid = %d ",filed, value, uid)
	end
	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function getPlayerClubs(uid)
	local sql = string.format("select * from s_club_users where uid = %d order by fastTime asc ",uid)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs ~= 0 then
    	return rs
    end
    return {}
end

function getClubInfo(clubid)
	local sql = string.format("select * from s_clubs where clubid = %d",clubid)
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs == 1 then
    	return rs[1]
    end
    return nil
end

function setClubValue(clubid,filed,value)
	local sql
	if type(value) == 'string' then
		sql = string.format("update s_clubs set %s = '%s' where clubid = %d ",filed, value, clubid)
	end
	if type(value) == 'number' then
		sql = string.format("update s_clubs set %s = %d where clubid = %d ",filed, value, clubid)
	end
	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function setUserClubValue(clubid,uid,filed,value)
	local sql
	if type(value) == 'string' then
		sql = string.format("update s_club_users set %s = '%s' where clubid = %d and uid = %d ",filed, value, clubid, uid)
	end
	if type(value) == 'number' then
		sql = string.format("update s_club_users set %s = %d where clubid = %d and uid = %d ",filed, value, clubid, uid)
	end
	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function creatClub(clubInfo)
	print("---creatClub---clubInfo--------",clubInfo)
	local sql = string.format("insert into s_clubs(clubid,cuid,name,img,ctime,count)values(%d, %d,'%s','%s',%d,%d)",clubInfo.clubid,clubInfo.cuid,clubInfo.name,clubInfo.img,clubInfo.ctime,clubInfo.count)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	print("---creatClub---rs--------",rs)
	if rs.affected_rows > 0 then
		local sql = string.format("insert into s_club_users(clubid,uid,cuid,fastTime,joinTime)values(%d,%d,%d,%d,%d)",clubInfo.clubid,clubInfo.cuid,clubInfo.cuid,os.time(),os.time())
	    skynet.call(".mysqlpool", "lua", "execute", sql)
	    return true
	end
	return nil
end

function applyCulb(info)
	local sql = string.format("insert into s_club_apply(cuid,clubid,uid,applyTime)values(%d,%d,%d,%d)",info.cuid,info.clubid,info.uid,os.time())
	print("---------------sql----------",sql)
	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function exitCulb(info)
	local sql = string.format("insert into s_club_exit(cuid,clubid,uid,applyTime)values(%d,%d,%d,%d)",info.cuid,info.clubid,info.uid,os.time())
	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function getClubid(uid)
	local sql = string.format("select * from s_clubs_id_list where state = 0 limit 1 ")
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    print("---getClubid---rs--------",rs)
    if #rs ~= 0 then
    	sql = string.format("update s_clubs_id_list set state = 1,uid = %d where clubid = %d ", uid, rs[1].clubid)
    	skynet.call(".mysqlpool", "lua", "execute", sql)
    	return rs[1].clubid
    end
end

function getUid()
	local sql = string.format("select * from s_user_id_list where state = 0 limit 1 ")
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    print("---getUid---rs--------",rs)
    if #rs ~= 0 then
    	sql = string.format("update s_user_id_list set state = 1 where uid = %d ", rs[1].uid)
    	skynet.call(".mysqlpool", "lua", "execute", sql)
    	return rs[1].uid
    end
end



function getGameList()
	local sql = string.format("select * from s_game_type")
	return skynet.call(".mysqlpool", "lua", "execute", sql)
end