local skynet = require "skynet"
require "skynet.manager"
local cjson = require "cjson"
local snax = require "snax"
local cluster = require "cluster"
local balance = 1

--调用api模块
local function callAPIMod( modname, ... )
    balance = balance + 1
    if balance > PDEFINE.MAX_APIWORKER then
        balance = 1
    end

    return cluster.call( "api", ".you9api_worker"..balance, --[[".you9apisdk",--]] modname, ... )
end

--发送到node服 让node服带上 uid和token参数去调用api模块
local function callAPIMod2Node( user, modname, ... )
    return cluster.call(user.cluster_info.server,
        user.cluster_info.address, "clusterModuleCall", "player", "callapiservice", modname, ...)
end

--用于先后连续调用api模块
local function callAPIModWithFun( dealfunction, modname, ... )
    --现在用于2次处理  因为现在只有2次需求，以后多了改成循环，或者自己逻辑实现 这里不实现
    local ok,resultjson,afterdealmod = CMD.callAPIMod( modname, ... )
    if not ok then
        --通知执行者 执行失败
        dealfunction(false)
        return
    end

    local dealok,dealjson = dealfunction( true, resultjson, ... )
    if not dealok then
        --本地记录失败日志 但是不进行其他处理
        LOG_ERROR("api_service dealfunction fail.resultjson:", resultjson, " modname:", modname," otherpara:", ...)
        return
    end

    if afterdealmod ~= nil then
        local callbackok = CMD.callAPIMod( afterdealmod, dealjson, ... )
        if not callbackok then
            --本地记录失败日志 暂时不进行其他处理(出现这样的情况是因为对端网络异常，这个很难出现)，以后线上这里问题多的话可以记录redis，并且记录错误队列，系统启动后从redis读出错误数据 本地定时检测处理
            LOG_ERROR("api_service dealfunction fail.resultjson:", resultjson, " modname:", modname," otherpara:", ...)
            return
        end
    end
end

return {
    callAPIMod = callAPIMod,
    callAPIMod2Node = callAPIMod2Node,
    callAPIModWithFun = callAPIModWithFun,
}