local skynet = require "skynet"
require "skynet.manager"
local cjson   = require "cjson"
local queue = {}

local CMD = {}

function CMD.start()
end

function CMD.stop()
end

function CMD.size()
    return #queue
end

function CMD.sync(sql)
    table.insert(queue, sql)
end

local function sync_impl()
    while true do
        --local combine_count = 20
        --local tmp = 0
        --local combine_sql = ""
        for k, sql in pairs(queue) do
            LOG_DEBUG("sync_execute %s", sql)
            local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
            if rs.errno ~=nil and tonumber(rs.errno) > 0 then
                LOG_DEBUG("error_sql: ".. sql .."----- result:----'%s'",cjson.encode(rs))
            end
            --if tmp == 0 then
            --    combine_sql = sql
            --else
            --    combine_sql = combine_sql .. ";" .. sql
            --end
            --tmp = tmp + 1
            --if tmp >= combine_count then
            --    combine_sql = "START TRANSACTION;" .. combine_sql .. ";COMMIT;"
            --    LOG_DEBUG("-------TRANSACTION sql:----------")
            --    LOG_DEBUG(combine_sql)
            --    LOG_DEBUG("------TRANSACTION sql end-----------")
            --    local rs = skynet.call(".mysqlpool", "lua", "execute", combine_sql)
            --    local rs_str = cjson.encode(rs)
            --    LOG_DEBUG("------rs_str-----------'%s'",rs_str)
            --    tmp = 0
            --    combine_sql = ""
            --end
            queue[k] = nil
        end
        --if combine_sql ~= "" then
        --    combine_sql = "START TRANSACTION;" .. combine_sql .. ";COMMIT;"
        --    LOG_DEBUG("-------TRANSACTION1 sql:----------")
        --    print("-------TRANSACTION1 sql:----------")
        --    print(os.date("%Y-%m-%d %H:%M:%S", os.time()), " sql:", combine_sql)
        --    print("------TRANSACTION sql end-----------")
        --    local rs = skynet.call(".mysqlpool", "lua", "execute", combine_sql)
        --
        --    local rs_str = cjson.encode(rs)
        --    LOG_DEBUG("------rs_str-----------'%s'",rs_str)
        --    --if error then
        --    --    skynet.call(".mysqlpool", "lua", "execute", "ROLLBACK")
        --    --end
        --    tmp = 0
        --    combine_sql = ""
        --end
        skynet.sleep(500) --每5秒同步到db
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
    skynet.fork(sync_impl)
    skynet.register("." .. SERVICE_NAME)
end)
