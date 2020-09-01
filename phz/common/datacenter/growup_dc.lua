local entity = require "Entity"

local EntGrowup

function init()
    EntGrowup = entity.Get("s_growup")
    EntGrowup:Init()
    EntGrowup:Load()
end

function response.add(row)
    return EntGrowup:Add(row)
end

function response.delete(row)
    return EntGrowup:Delete(row)
end

function response.get(pid, passwd)
    return EntGrowup:Get(pid, passwd)
end

function response.getvalue(uid, key)
    return EntGrowup:GetValue(uid, key)
end

function accept.setvalue(uid, key, value, nosync)
    return EntGrowup:SetValue(uid, key, value, nosync)
end

function accept.remove(row)
    return EntGrowup:Remove(row)
end

function response.update(oldrow,row)
    local ret = EntGrowup:Delete(oldrow)
    if ret then
        return EntGrowup:Add(row)
    end
    return 
end

function response.getall()
    return EntGrowup:GetAll()
end
