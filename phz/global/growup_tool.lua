local skynet = require "skynet"
require "skynet.manager"
local cjson = require "cjson"
local snax = require "snax"
local cluster = require "cluster"
local cur_servername = skynet.getenv("mastername")

--增加经验
local function addGrowupScoreByRound( uid, altercoin )
    -- local code,callcode

    -- if cur_servername == "master" then
    --     callcode,code = pcall(skynet.call, ".growupmgr", "lua", "addGrowupScoreByRound", uid, altercoin )
    -- else
    --     callcode,code = pcall(cluster.call, "master", ".growupmgr", "addGrowupScoreByRound", uid, altercoin )
    -- end
    -- if not callcode then
    --     LOG_ERROR("addGrowupScoreByRound", callcode, code)
    --     return false
    -- end
    -- if code ~= PDEFINE.RET.SUCCESS then
    --     LOG_ERROR("addGrowupScoreByRound", callcode, code)
    --     return false
    -- end
    return true
end

--获取成长数据
local function getuserGrowupData( uid )
    local code,callcode,data

    if cur_servername == "master" then
        callcode,code,data = pcall(skynet.call, ".growupmgr", "lua", "getuserGrowupData", uid )
    end
    callcode,code,data = pcall(cluster.call, "master", ".growupmgr", "getuserGrowupData", uid )
    if not callcode then
        LOG_ERROR("getuserGrowupData", callcode, code, data)
        return false
    end
    if code ~= PDEFINE.RET.SUCCESS then
        LOG_ERROR("getuserGrowupData", callcode, code, data)
        return false
    end
    return true, data
end

--获取系统配置
local function getAll_Conf( )
    local code,data

    if cur_servername == "master" then
        code,data = pcall(skynet.call, ".growupmgr", "lua", "getAll_Conf" )
    end
    code,data = pcall(cluster.call, "master", ".growupmgr", "getAll_Conf" )
    if not code then
        LOG_ERROR("getAll_Conf", code, data)
        return false
    end
    return true, data
end

--领取星星奖励
local function getGift( uid, star )
    local code,callcode,data

    if cur_servername == "master" then
        callcode,code,data = pcall(skynet.call, ".growupmgr", "lua", "getGift", uid, star)
    end
    callcode,code,data = pcall(cluster.call, "master", ".growupmgr", "getGift", uid, star)
    if not callcode then
        LOG_ERROR("getGift", callcode, code, data)
        return false
    end
    if code ~= PDEFINE.RET.SUCCESS then
        LOG_ERROR("getGift", callcode, code, data)
        return false
    end
    return true, data
end

--获取成长数据 转化成客户端使用的
local function getuserGrowupData2Client( uid )
    local isok, growup = getuserGrowupData( uid )
    if isok then
        growup.gift = nil
        --超过100% 只显示100%
        if growup.target ~= nil and growup.process ~= nil then
            if growup.target < growup.process then
                growup.process = growup.target
            end
        end
    end
    return isok,growup
end

return {
    addGrowupScoreByRound = addGrowupScoreByRound,
    getuserGrowupData = getuserGrowupData,
    getuserGrowupData2Client = getuserGrowupData2Client,
    getAll_Conf = getAll_Conf,
    getGift = getGift,
}