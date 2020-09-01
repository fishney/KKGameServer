--面向游戏内部服务的转发
local skynet = require "skynet"
require "skynet.manager"
local snax = require "snax"
local cluster = require "cluster"
local CMD = {}
local balance = 1
local cur_servername = skynet.getenv("mastername")

function callevosdk( modname, ... )
    balance = balance + 1
    if balance > PDEFINE.MAX_APIWORKER then
        balance = 1
    end
    LOG_DEBUG("cur_servername:",cur_servername)
    if cur_servername == "api" then
        LOG_DEBUG("skynet.call:")
        return skynet.call(".luckyliveapisdk_worker"..balance, "lua", modname, ... )
    end
    return cluster.call( "api", ".luckyliveapisdk_worker"..balance, modname, ... )
end

function sendevosdk( modname, ... )
    balance = balance + 1
    if balance > PDEFINE.MAX_APIWORKER then
        balance = 1
    end
    LOG_DEBUG("cur_servername:",cur_servername)
    if cur_servername == "api" then
        LOG_DEBUG("skynet.send:")
        return skynet.send(".evoapisdk_worker"..balance, "lua", modname, ... )
    end

    return cluster.send( "api", ".evoapisdk_worker"..balance, modname, ... )
end

return  {
    callevosdk = callevosdk,
    sendevosdk = sendevosdk,
}