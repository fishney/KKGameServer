local skynet = require "skynet"
require "skynet.manager"
local cjson = require "cjson"
local snax = require "snax"
local cluster = require "cluster"
local balance = 1
local is_report = skynet.getenv('isreport')

--调用api模块
local function Report( modname, data )
    if not is_report then
        return
    end
    pcall(cluster.send, "report", ".report", "Report", modname, data)
end

--上报桌子T人信息
-- user={uid=xxx,coin=xxx}
local function reportGameKick( user,deskinfo )
    if deskinfo == nil then
        return
    end

    local report  = {}
    report.c=0
    report.uid = user.uid
    report.gameid = deskinfo.gameid
    report.deskid = deskinfo.deskid
    report.deskuuid = deskinfo.uuid
    report.coin = user.coin
    Report( PDEFINE.REPORTMOD.gamekick,report )
end

-- 上报游戏结果
-- user={uid=xxx,betcoin=xxx,betline=xxx,altercoin=xxx,bet=xxx,result=xx}
-- altercoin是输赢 输用负数 betcoin是真实下注信息 bet 是下注方位信息 result=开奖结果
local function reportGameResult( user,deskinfo )
    if deskinfo == nil then
        return
    end
    local report  = {}
    report.c=0
    report.uid = user.uid
    report.gameid = deskinfo.gameid
    report.deskid = deskinfo.deskid
    report.deskuuid = deskinfo.uuid
    report.betcoin = user.betcoin
    report.betline = user.betline
    report.altercoin = user.altercoin
    report.bet = user.bet
    report.result = user.result
    Report( PDEFINE.REPORTMOD.gameresult,report )
end

return {
    Report = Report,
    reportGameKick = reportGameKick,
    reportGameResult = reportGameResult,
}