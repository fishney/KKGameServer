local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
-- 登录流程中玩家的桌子信息等
local CMD = {}
local desk_uid = {}

function CMD.joinDesk(cluster_info, uid)
    uid = math.floor(tonumber(uid))
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " master CMD.joinDesk", uid, cluster_info)
    desk_uid[uid] = cluster_info
end

function CMD.removeDesk(uid)
    uid = math.floor(tonumber(uid))
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " master CMD.removeDesk", uid, desk_uid[uid])
    if nil ~= desk_uid[uid] then
        desk_uid[uid] = nil
    end
end

function CMD.getDesk(uid)
    uid = math.floor(tonumber(uid))
    LOG_INFO(os.date("%Y-%m-%d %H:%M:%S", os.time()), " master CMD.getDesk", uid)
    return desk_uid[uid]
end

function CMD.getAllDesk()
    return desk_uid
end

function CMD.callAgentFun(uid, fun, ...)
    uid = math.floor(tonumber(uid))
    local client_agent = assert(desk_uid[uid])
    if client_agent then
        return cluster.call(client_agent.server, client_agent.address, fun, ...)
    end
    return nil
end

--踢掉某个游戏的所有人  以后重写桌子管理的时候再改到那边去 这种方式很别扭
function CMD.apiKickGame( gameid )
    local kicktable = {}
    for uid,client_agent in pairs(desk_uid) do
        if client_agent.gameid == gameid then
            table.insert(kicktable,client_agent)
        end
    end

    for _,client_agent in pairs(kicktable) do
        cluster.call(client_agent.server, client_agent.address, "apiKickDesk")
    end

end

--获取某个游戏的在线数量
function CMD.getCurSeatByGameid( gameidarr )
    local gamenumarr = {}
    local allgamenumarr = {}
    -- LOG_DEBUG("desk_uid:",desk_uid)
    local checkonlinetable = {}
    if gameidarr == nil or #gameidarr == 0 then
        return gamenumarr
    end

    for uid,cluster_info in pairs(desk_uid) do
        table.insert(checkonlinetable,uid)
    end

    local onlinetable = skynet.call(".userCenter","lua","checkOnline", checkonlinetable)
    for uid,cluster_info in pairs(desk_uid) do
        local gameid = cluster_info.gameid
        --判断是否在线
        if onlinetable[uid] ~= nil then
            if allgamenumarr[gameid] == nil then
                allgamenumarr[gameid] = 0
            end
            allgamenumarr[gameid] = allgamenumarr[gameid] + 1
        end
    end

    -- LOG_DEBUG("getCurSeatByGameid gameidarr:",gameidarr)
    if gameidarr[1] == "-1" then
        local allgame = skynet.call(".gamemgr","lua","getAll")
        for i,gamedatarow in pairs(allgame) do
            local gameid = tonumber(gamedatarow.id)
            local onlinenum = allgamenumarr[gameid] or 0
            local gameinfo = {}
            gameinfo.gameid = gameid
            gameinfo.onlinenum = onlinenum
            table.insert(gamenumarr,gameinfo)
        end
    else
        for i,gameidstr in ipairs(gameidarr) do
            if gameidstr == "" then 
                break
            end

            local gameid = tonumber(gameidstr)
            local onlinenum = allgamenumarr[gameid] or 0
            local gameinfo = {}
            gameinfo.gameid = gameid
            gameinfo.onlinenum = onlinenum
            table.insert(gamenumarr,gameinfo)
        end
    end

    return gamenumarr
end

--清除掉缓存的桌子
function cleardesk( servername )
    for uid,cluster_info in pairs(desk_uid) do
        if cluster_info.server == servername then
            desk_uid[uid] = nil
        end
    end
end

function ongamechange( server )
    LOG_DEBUG("ongamechange start server:", server, "server_list:", server_list)
    --[[
        server的结构
        server={
            name=xx,
            status=xx,
            tag=xx,
            freshtime=xx,
            serverinfo = {}
        }
    ]]
    if server.status == PDEFINE.SERVER_STATUS.stop then
        --清除掉缓存的桌子
        cleardesk(server.name)
    else
        
    end

    LOG_DEBUG("ongamechange end server:", server, "server_list:", server_list)
end

function CMD.onserverchange( server )
    LOG_DEBUG("onserverchange server:",server)
    --[[
        server的结构
        server={
            name=xx,
            status=xx,
            tag=xx,
            freshtime=xx，
            serverinfo = {}
        }
    ]]
    if server.tag == "game" then
        ongamechange(server)
    end
end

--系统启动完成后的通知
function CMD.start_init( ... )
    local callback = {}
    callback.method = "onserverchange"
    callback.address = skynet.self()

    skynet.call(".servernode", "lua", "regEventFun", PDEFINE.SERVER_EVENTS.changestatus, callback)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)

    desk_uid = {}
    skynet.register(".agentdesk")
end)
