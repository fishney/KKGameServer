local entity = require "Entity"

local user_growup_dc = {}
local EntUserGrowup

function user_growup_dc.init()
    EntUserGrowup = entity.Get("d_user_growup")
    EntUserGrowup:Init()
end

function user_growup_dc.load(uid)
    if not uid then return end
    return EntUserGrowup:Load(uid)
end

function user_growup_dc.unload(uid)
    if not uid then return end
    EntUserGrowup:UnLoad(uid)
end

function user_growup_dc.getvalue(uid, key)
    return EntUserGrowup:GetValue(uid, uid, key)
end

function user_growup_dc.setvalue(uid, key, value)
    return EntUserGrowup:SetValue(uid, uid, key, value)
end

function user_growup_dc.add(row)
    return EntUserGrowup:Add(row)
end

function user_growup_dc.delete(row)
    return EntUserGrowup:Delete(row)
end

function user_growup_dc.get(uid)
    return EntUserGrowup:Get(uid)
end

return user_growup_dc
