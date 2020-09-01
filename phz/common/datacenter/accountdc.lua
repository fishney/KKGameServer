local entity = require "Entity"

local EntAccount

function init()
    EntAccount = entity.Get("d_account")
    EntAccount:Init()
    EntAccount:Load()
end

function response.add(row)
    local ret = EntAccount:Add(row)
    if ret then
        if row.playername ~= nil then
            do_redis({"incr", row.playername})
        end
    end
    return ret
end

function response.delete(row)
    return EntAccount:Delete(row)
end

function response.get(pid, passwd)
    return EntAccount:Get(pid, passwd)
end

function response.update(oldrow, row)
    local ret = EntAccount:Delete(oldrow)
    if ret then
        if oldrow.playername ~= nil then
            do_redis({"del", oldrow.playername})
        end

        local ret2 = EntAccount:Add(row)
        if ret2 then
            if row.playername ~= nil then
                do_redis({"incr", row.playername})
            end
        end
    end
    return
end

function response.setValue(id, field, data)
    return EntAccount:SetValue(id, field, data)
end

-- 获得下一个uid
function response.get_nextid()
    return EntAccount:GetNextId()
end