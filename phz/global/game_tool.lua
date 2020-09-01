local skynet = require "skynet"
local protobuf = require "protobuf"
local random = require "random"
local MessagePack = require "MessagePack"
local cjson = require "cjson"
local api_service = require "api_service"
local game_tool = {}
--历史记录
local history = {}
------历史记录----------
--拼接redis key
local function getHistoryKey(gameid, uniid)
    local gameid = math.floor(gameid)

    if uniid == nil then
        uniid = ""
    end
    return string.format("%s:%s:%s", PDEFINE.REDISKEY.GAME.history, gameid, uniid)
end

--获取历史记录 redis的key game:history:gameid:uniid
--@param gameid
--@param uniid 自定义唯一id
--@param redis_uid redis分组使用的uid
function history.getGameHistory(gameid, uniid, redis_uid)
    local gameid = math.floor(gameid)

    local result = do_redis({"lrange", getHistoryKey(gameid, uniid), 0, -1}, redis_uid)
    local his = {}
    for i=1, #result do
        -- local tmp = {}
        local rstable = cjson.decode(result[i])
        -- for _,v in ipairs(rstable) do
        --     table.insert(tmp, math.floor(tonumber(v)))
        -- end
        table.insert(his, rstable)
    end
    return his
end

--丢入历史记录 redis的key game:history:
--@param gameid
--@param uniid 自定义唯一id
--@param data 历史数据(单个 table)
--@param redis_uid redis分组使用的uid
--@param maxnum 最大的数量
function history.pushGameHistory(gameid, uniid, data, maxnum, redis_uid, expire_time)
    local gameid = math.floor(gameid)

    if expire_time == nil then
        expire_time = 7 * 24 * 3600 -- 7天
    end
    local rkey = getHistoryKey(gameid, uniid)
    do_redis({"rpush", rkey, cjson.encode(data)}, redis_uid)
    if maxnum ~= nil and maxnum > 0 then
        do_redis({"ltrim", rkey, -maxnum, -1}, redis_uid)
    end
    do_redis({"setkeyex", rkey, expire_time}, redis_uid)
end

--删除历史记录
--@param gameid
--@param uniid 自定义唯一id
function history.delGameHistory(gameid, uniid, redis_uid)
    local gameid = math.floor(gameid)

    do_redis({"del", getHistoryKey(gameid, uniid)}, redis_uid)
end


--后台针对玩家的游戏设置
local gamesetting = {}

--获取针对玩家的某个游戏设置
--@param gameid
--@param uid
--@return 如果没有设置会返回一个空table，有返回{gameid=xx,state=xx,chips=xx}
function gamesetting.getGameSetting(gameid, uid)
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)
    --这里如果以后有瓶颈了就改成直接读redis
    local ok,rsdata = pcall(api_service.callAPIMod, "getGameSetting", gameid, uid)
    if not ok then
        --没有数据的话 就直接让玩家进游戏
        rsdata = {}
        rsdata.gameid = gameid
        rsdata.state = 0
        rsdata.chips = {}
    end
    return rsdata

    -- local ok,rsdata = pcall(do_redis_withprename, "api_", {"hgetall", gamesetting.getGameSettingRedisKey(uid)})
    -- if ok then
    --     rsdata = make_pairs_table(rsdata)--key gameid  value {"chips":[{"min":"2","max":"100"}],"state":"1"}
    --     if not table.empty(rsdata) and rsdata[gameid] ~= nil then
    --         rsdata = rsdata[gameid]
    --         rsdata.chips = cjson.decode(rsdata.chips)
    --         rsdata.state = math.floor(tonumber(rsdata.state))
    --         return rsdata
    --     end
    -- end

    -- rsdata = {}
    -- rsdata.gameid = gameid
    -- rsdata.state = 0
    -- rsdata.chips = {}
    -- return rsdata
end

--获取针对玩家的所有游戏设置
--@param uid
--@return {gameid={state=xx,chips=xx},gameid2={state=xx,chips=xx}}
function gamesetting.getAllGameSetting(uid)
    local uid = math.floor(uid)
    --这里如果以后有瓶颈了就改成直接读redis
    local ok,rsdata = pcall(api_service.callAPIMod, "getAllGameSetting", uid)
    if not ok then
        rsdata = {}
    end

    return rsdata
end


local data = {}

local function getRedisLoanDataKey( gameid, uid )
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)

    local redis_key = string.format("%s:%s:%s", PDEFINE.REDISKEY.GAME.loandata, gameid, uid)
    return redis_key
end

--根据rediskey字符串获取gameid和uid
function data.getinfofromRedisKey(key)
    local info = string.gsub(key, PDEFINE.REDISKEY.GAME.loandata, "")
    info = string.split(info, ':')
    local gameid
    local uid
    if #info >= 2 then
        gameid = math.floor(tonumber(info[1]))
        uid = math.floor(tonumber(info[2]))
    end
    return gameid,uid
end

--删除redis里面记录的借款内容
--@param gameid
--@param uid
--@return 是否有真实的删除操作
function data.delLoanData( gameid, uid)
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)
    local redis_key = getRedisLoanDataKey(gameid, uid)

    local delcount = do_redis({"zrem", PDEFINE.REDISKEY.GAME.expire_sortedset, redis_key})
    LOG_DEBUG("delcount:", delcount)
    --如果没有删到 就是其他地方处理了
    if delcount > 0 then
        do_redis({"del", redis_key})
        return true
    end
    return false
end

--将借款数据缓存到redis
--@param gameid
--@param uid
--@param deskdata
--@param REDIS_EXPIRETIME 如果不存在默认设置是1天
--@param loan_data={expire_time=xxx,bet_coin=xx,loan_coin=xx,uniid=xx,deskid=xx,poolround_id=xx}
function data.pushLoanData( gameid, uid, deskdata, loan_data)
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)
    local param = string.format("%d %d %s %s", gameid, uid, tostring(deskdata), tostring(loan_data))
    assert(loan_data, string.format("%s %s", "push2Redis loan_datanil", param))
    -- assert(loan_data.expire_time>0, string.format("%s %s", "push2Redis expire_time<=0", param))
    assert(loan_data.deskid, string.format("%s %s", "push2Redis deskidnil", param))

    if loan_data.loan_coin == nil then
        loan_data.loan_coin = 0
    end
    if loan_data.expire_time == nil then
        loan_data.expire_time = 24*3600 --1天
        -- loan_data.expire_time = 30 --1天
    end
    deskdata.loan_data = loan_data
    deskdata.key_gameid = gameid
    deskdata.key_uid = uid

    local expire_time = os.time() + loan_data.expire_time
    local redis_key = getRedisLoanDataKey(gameid, uid)

    do_redis({"set", redis_key, cjson.encode(deskdata)})
    do_redis({"zadd", PDEFINE.REDISKEY.GAME.expire_sortedset, expire_time, redis_key})--排序数据
end

--从redis加载借款数据
--@param gameid
--@param uid
--@param REDIS_EXPIRETIME -1表示不重新修改过期时间
--@return 如果不存在则返回nil
function data.reloadLoanData(gameid, uid, REDIS_EXPIRETIME)
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)
    if REDIS_EXPIRETIME == nil then
        REDIS_EXPIRETIME = 24*3600 --1天
    end
    local expire_time = os.time() + REDIS_EXPIRETIME
    local redis_key = getRedisLoanDataKey(gameid, uid)
    --数据先删再增加保证数据有效性
    local delcount = do_redis({"zrem", PDEFINE.REDISKEY.GAME.expire_sortedset, redis_key})
    LOG_DEBUG("delcount:", delcount)
    --如果没有删到 就是其他地方处理了这个事件 redis不用去拿数据了
    if delcount > 0 then
        local deskdata = do_redis({"get", redis_key})
        if deskdata ~= nil then
            deskdata = cjson.decode(deskdata)
            if REDIS_EXPIRETIME > 0 then
                deskdata.loan_data.expire_time = expire_time
                --刷新sortedset里面的过期时间key
                do_redis({"set", redis_key, cjson.encode(deskdata)})
            else
                expire_time = deskdata.loan_data.expire_time
            end
            
            do_redis({"zadd", PDEFINE.REDISKEY.GAME.expire_sortedset, expire_time, redis_key})--排序数据
            return deskdata
        end
    end
    
    return nil
end

local function getRedisDeskDataKey( gameid, uid )
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)

    local redis_key = string.format("%s:%s:%s", PDEFINE.REDISKEY.GAME.deskdata, gameid, uid)
    return redis_key
end

--将数据缓存到redis
--@param gameid
--@param uid
--@param deskdata
--@param REDIS_EXPIRETIME 如果不存在默认设置是1天
function data.push2Redis( gameid, uid, deskdata, REDIS_EXPIRETIME)
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)
    local param = string.format("%d %d %s %s", gameid, uid, tostring(deskdata), REDIS_EXPIRETIME)
    if REDIS_EXPIRETIME == nil then
        REDIS_EXPIRETIME = 24*3600
        -- REDIS_EXPIRETIME = 120
    end
    local redis_key = getRedisDeskDataKey(gameid, uid)

    do_redis({"setex", redis_key, cjson.encode(deskdata), REDIS_EXPIRETIME}, uid)
end

--从redis加载数据
--@param gameid
--@param uid
--@param REDIS_EXPIRETIME -1表示不重新修改过期时间
--@return 如果不存在则返回nil
function data.reloadRedisData( gameid, uid)
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)
    local deskdata = do_redis({"get", getRedisDeskDataKey(gameid, uid)}, uid)
    if deskdata ~= nil then
        deskdata = cjson.decode(deskdata)
        return deskdata
    end
    return nil
end

--删除redis里面记录的内容
--@param gameid
--@param uid
function data.delRedis( gameid, uid)
    local uid = math.floor(uid)
    local gameid = math.floor(gameid)
    local redis_key = getRedisDeskDataKey(gameid, uid)
    do_redis({"del", redis_key}, uid)
end

function data.setFreeGameDate( gameid, uid, freeCnt)
    gameid = math.floor(gameid)
    uid = math.floor(uid)
    local cfgDesk = require ("tiger.slots.slot_"..gameid)
    local line = cfgDesk.getLine(gameid)
    -- local cfgAddMult = nil
    -- local addMult = 1
    -- if cfgDesk.gameConf.freeGameConf.addMult then
    --     cfgAddMult = cfgDesk.gameConf.freeGameConf.addMult
    -- else
    --     if cfgDesk.gameConf.freeGameConf.normal then
    --         cfgAddMult = cfgDesk.gameConf.freeGameConf.normal.addMult
    --     end
    --     if cfgDesk.gameConf.freeGameConf.sp then
    --         cfgAddMult = cfgDesk.gameConf.freeGameConf.sp.addMult
    --     end
    -- end

    -- if cfgAddMult then
    --     if type(cfgAddMult) == "table" then
    --         if cfgAddMult[3] == 1 then
    --             addMult = math.random(cfgAddMult[1],cfgAddMult[2])
    --         end
    --     else
    --         addMult = cfgAddMult
    --     end
    -- end
    print("gameid:",gameid," freeGame======领取免费游戏=====>uid: ",uid, "freeCnt===>",freeCnt)
    local key = tostring("tiger_gameid_"..gameid.."uid_"..uid)
    local dBfreeGameData = game_tool.data.reloadLoanData(gameid,uid)
    if dBfreeGameData then
        dBfreeGameData.addSysFreeCnt = freeCnt
        game_tool.data.delLoanData(gameid, uid)
    else
        dBfreeGameData = {
            freeGameData = {
                restFreeCount = 0, -- 剩余次数
                addSysFreeCnt = freeCnt,
                allFreeCount = 0, -- 总次数
                bigGameWinCoin = 0,
                freeWinCoin = 0,   --总免费赢的钱
                addMult = 1,       -- 免费游戏额外增加的倍数
                freeType = 100,     -- 免费类型
                triFreeData = {triFreeCnt = 0,freeInfo = {}},
                doubleAward = {},
                isNormalStart = true,
            },
            currmult = 1,     -- 当前选择的押注额档位数
            line = line,         -- 之前选的线
            uid = uid,
            gameId = gameid,
            processIdList = {bigCoin = 0,freeCoin = 0,subCoin = 0,big_poolround_id = nil,free_poolround_id = nil,sub_poolround_id = nil},
        }
    end
    
    local loan_data = {expire_time=100,bet_coin=0,loan_coin=0,uniid=00000,deskid=111111,poolround_id=nil}
    game_tool.data.pushLoanData(gameid,uid,dBfreeGameData,loan_data)
end


game_tool.history = history
game_tool.gamesetting = gamesetting
game_tool.data = data

return game_tool