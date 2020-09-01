local entity = require "Entity"

local EntGame

function init()
    EntGame = entity.Get("s_record_control")
    EntGame:Init()
    EntGame:Load()
end

function response.add(row)
    return EntGame:Add(row)
end

function response.delete(row)
    return EntGame:Delete(row)
end

function response.get(pid, passwd)
    return EntGame:Get(pid, passwd)
end

function response.getvalue(id, key)
    return EntGame:GetValue(id, key)
end

function response.getall()
    return EntGame:GetAll()
end

function accept.setvalue(id, key, value)
    return EntGame:SetValue(id, key, value)
end

function accept:remove(row)
    return EntGame:Remove(row)
end

function response.update(oldrow,row)
    local ret = EntGame:Delete(oldrow)
    if ret then
        return EntGame:Add(row)
    end
    return
end

-- 获得下一个uid
function response.get_nextid()
    return EntGame:GetNextId()
end
