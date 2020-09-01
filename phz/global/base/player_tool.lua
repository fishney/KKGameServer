local cluster   = require "cluster"
local cjson     = require "cjson"
local api_service = require "api_service"
local JIANGRONG = false

--获取玩家信息
local function getPlayerInfo( uid )
    local ok,playerinfo = pcall(cluster.call, "master", ".userCenter", "getPlayerInfo", uid)
    if not ok then
        return nil
    end
    --把playerinfo的小数位限制到2位
    -- playerinfo.coin = math.floor(playerinfo.coin*10000+0.00000001)/10000
    return playerinfo
end

local function brodcastcoin2client( uid, altercoin )
    pcall(cluster.call, "master", ".userCenter", "brodcastcoin2client", uid, altercoin)
end

--修改玩家金币
--@param ctype 参考PDEFINE.ALTERCOINTAG
--@param issync 可以不传 默认为false
--@param uid
--@param altercoin
--@param alterlog
--@param gameid
--@param pooltype
--@param subgameid
--@param deskuuid
local function calUserCoin_do( uid, altercoin, alterlog, ctype, gameid, pooltype, deskuuid, subgameid, issync, poolround_id, not2client, extend1, water_before)
    local paramlog = concatStr(uid,altercoin,alterlog,ctype,gameid,pooltype,deskuuid,subgameid,issync,poolround_id)
    assert(ctype, "ctypenil "..paramlog)
    assert(ctype >= 1 and ctype <= PDEFINE.ALTERCOINTAG.CHARGE2THIRDGAMEFAIL, "ctypeerr "..paramlog)
    assert(uid, "uidnil "..paramlog)
    assert(altercoin, "altercoinnil "..paramlog)
    assert(alterlog, "alterlognil "..paramlog)
    assert(pooltype, "pooltypenil "..paramlog)
    if gameid == nil then
        gameid = 0
    end
    if subgameid == nil then
        subgameid = 0
    end
    if deskuuid == nil then
        deskuuid = 0
    end
    if issync == nil then
        issync = false
    end

    local altercoin_para={
        alter_coin=altercoin,
        type=ctype,
        alterlog=alterlog,
    }
    local gameinfo_para={
        gameid=gameid,
        subgameid=subgameid,
    }
    local poolround_para = {
        uniid = deskuuid, --唯一id
        pooltype = pooltype, --pooltype  PDEFINE.POOL_TYPE
        poolround_id = poolround_id, --pr的唯一id
    }
    local ok, code, beforecoin, aftercoin, altercoin_id = pcall(cluster.call, "master", ".userCenter", "calUserCoin",
         uid, issync, nil, altercoin_para, gameinfo_para, poolround_para, extend1, water_before)
    if not ok then
        LOG_ERROR("calUserCoin callfail", paramlog)
        return false,PDEFINE.RET.ERROR.CALL_FAIL
    end
    if code ~= PDEFINE.RET.SUCCESS then
        LOG_ERROR("calUserCoin code", code, paramlog)
        return false,code
    end
    if not not2client then
        brodcastcoin2client( uid, altercoin )
    end
    return true, code, altercoin_id, beforecoin, aftercoin
end


--修改玩家金币
--@param ctype 参考PDEFINE.ALTERCOINTAG
--@param issync 可以不传 默认为false
--@param uid
--@param altercoin
--@param alterlog
--@param gameid
local function calUserCoin_nogame(uuid, uid, altercoin, alterlog, ctype, gameid, pooltype, issync, not2client, extend1)
    local paramlog = concatStr(uid,altercoin,alterlog,ctype,gameid,pooltype,issync)
    assert(ctype, "ctypenil "..paramlog)
    assert(ctype >= 1 and ctype <= PDEFINE.ALTERCOINTAG.CHARGE2THIRDGAMEFAIL, "ctypeerr "..paramlog)
    assert(uid, "uidnil "..paramlog)
    assert(altercoin, "altercoinnil "..paramlog)
    assert(alterlog, "alterlognil "..paramlog)
    if gameid == nil then
        gameid = 0
    end
    if pooltype == nil then
        pooltype = PDEFINE.POOL_TYPE.none
    end
    if issync == nil then
        issync = false
    end
    local ok, code, altercoin_id, beforecoin, aftercoin = calUserCoin_do(uid, altercoin, alterlog, ctype, gameid, pooltype, uuid, 0, issync, nil, not2client, extend1)
    
    return ok,code, beforecoin, aftercoin
end

--修改玩家金币 game用的
local function calUserCoin( uid, altercoin, alterlog, ctype, deskInfo, pooltype, water_before)
    local paramlog = concatStr(uid,altercoin,alterlog,ctype,deskInfo,pooltype)
    if JIANGRONG then
        if type(deskInfo)=="number" then
            --老接口 第一个参数是gameid
            return true,PDEFINE.RET.SUCCESS
        end
    end
    assert(deskInfo, "deskInfonil "..paramlog)
    local subgameid = 0
    -- if deskInfo.subGame ~= nil then
    --  if deskInfo.subGame.subGameId ~= nil and deskInfo.subGame.subGameId > 0 then
    --      subgameid = deskInfo.subGame.subGameId
    --  end
    -- end
    if pooltype == nil then
        pooltype = PDEFINE.POOL_TYPE.none
    end

    --5龙里押注 押满的情况
    local extend1 = nil
    if ctype == PDEFINE.ALTERCOINTAG.BET or ctype == PDEFINE.ALTERCOINTAG.WIN then 
        if deskInfo.isbetfull ~= nil and deskInfo.isbetfull == PDEFINE.BET_TYPE.FULL then 
            extend1 = 'fullbet' --slots游戏 下注，押满
        end
    end

    return calUserCoin_do( uid, altercoin, alterlog, ctype, deskInfo.gameid, pooltype, deskInfo.uuid, subgameid, nil, nil, nil , extend1, water_before)
end

--修改玩家金币 game用的
local function calUserCoinSlot(uid, altercoin, alterlog, ctype, deskInfo, poolround_id)
    local paramlog = concatStr(uid,altercoin,alterlog,ctype,deskInfo,pooltype)
    local pooltype = PDEFINE.POOL_TYPE.none
    assert(deskInfo, "deskInfonil "..paramlog)
    local subgameid = 0
    -- if deskInfo.subGame ~= nil then
    --  if deskInfo.subGame.subGameId ~= nil and deskInfo.subGame.subGameId > 0 then
    --      subgameid = deskInfo.subGame.subGameId
    --  end
    -- end
    local extend1 = nil
    if ctype == PDEFINE.ALTERCOINTAG.BET or ctype == PDEFINE.ALTERCOINTAG.WIN then 
        if deskInfo.isbetfull ~= nil and deskInfo.isbetfull == PDEFINE.BET_TYPE.FULL then 
            extend1 = 'fullbet' --slots游戏 下注，押满
        end
    end
    return calUserCoin_do(uid, altercoin, alterlog, ctype, deskInfo.gameid, pooltype, deskInfo.uuid, subgameid, nil, poolround_id, nil, extend1)
end

--功能加金币
--[[
    extend1 入队列的扩展字段
]]
local function funcAddCoin(uid, altercoin, alterlog, ctype, gameid, pooltype, issync, extend1)
    local gameinfo_para = {
        gameid = gameid, --游戏id
        subgameid = 0, --子游戏id
    }
    local poolround_para = {
        uniid = uid..randomCode(11), --唯一id
        pooltype = pooltype, --pooltype  PDEFINE.POOL_TYPE
    }
    local code = api_service.callAPIMod("startPoolRound", uid, gameinfo_para, poolround_para)
     
    if code ~= PDEFINE.RET.SUCCESS then
        return PDEFINE.RET.ERROR.CALL_FAIL
    end

    local callok,addok,code,before_coin,after_coin = pcall(
            calUserCoin_nogame,
            poolround_para.uniid,
            uid, 
            altercoin, 
            alterlog, 
            ctype, 
            gameid, 
            pooltype, 
            issync,
            true,
            extend1
        )
    LOG_DEBUG("calUserCoin_nogame callok:", callok, "addok:", addok, "code:", code)
    if callok and addok and code == PDEFINE.RET.SUCCESS then
        --发出结算日志
        local gameinfo_para_log = {
            gameid = gameid, --游戏id
            deskid = 0, --桌子id
            subgameid = 0, --子游戏id
            deskuuid = uid, --桌子唯一id
            roundinfo = {
                bet = 0, --下注
                win = altercoin, --赢钱
                result = alterlog, --游戏结果
            }
        }
        api_service.callAPIMod("sendGameLog", uid, before_coin, after_coin, gameinfo_para_log, poolround_para)
    end
    api_service.callAPIMod("endPoolRound", gameinfo_para, poolround_para)

    if not callok or not addok or code ~= PDEFINE.RET.SUCCESS then
        return PDEFINE.RET.ERROR.CALL_FAIL
    end

    return code,before_coin,after_coin
end

return {
    getPlayerInfo = getPlayerInfo,
    calUserCoin = calUserCoin,
    calUserCoin_nogame = calUserCoin_nogame,
    calUserCoin_do = calUserCoin_do,
    calUserCoinSlot = calUserCoinSlot,
    funcAddCoin = funcAddCoin,
    brodcastcoin2client = brodcastcoin2client,
}