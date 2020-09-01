local skynet = require "skynet"
require "skynet.manager"
local logger = require "log.core"

local cjson = require "cjson"

-- local is_report = skynet.getenv('isreport') --控制现在是否进行数据上报

local redis_queue = "queue:report"

local CMD = {}

function CMD.Report( reportmodname, data )
    LOG_DEBUG("CMD.Report receive,modname:", reportmodname, " data:", data)
    if reportmodname == nil or reportmodname == "" then
        return
    end
    if data == nil then
        return
    end


    local time = os.date("%Y-%m-%d %H:%M:%S")
    local report = {}
    report.time = time
    report.modname = reportmodname
    report.data = data

    LOG_DEBUG("Report data:", report)
    do_redis_withprename("report_", {"rpush", redis_queue,  cjson.encode(report)})
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        if cmd == "start" or cmd == "stop" then
            skynet.retpack(f(...))
        else
            f(...)
        end
    end)

    skynet.register("."..SERVICE_NAME)
end)
