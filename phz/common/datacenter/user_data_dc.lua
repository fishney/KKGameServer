local entity = require "Entity"

local user_data_dc = {}
local EntUserCommonData
local EntUserDailyData
local EntUserWeeklyData

function user_data_dc.init()
    EntUserCommonData = entity.Get("d_user_common_data")
    EntUserCommonData:Init()
    EntUserDailyData = entity.Get("d_user_daily_data")
    EntUserDailyData:Init()
end

function user_data_dc.load(uid)
    if not uid then return end
    EntUserCommonData:Load(uid)
    EntUserDailyData:Load(uid)
end

function user_data_dc.unload(uid)
    if not uid then return end
    EntUserCommonData:UnLoad(uid)
    EntUserDailyData:UnLoad(uid)
end

function user_data_dc.clear(uid, type)
    if not uid then return end
    if type == "COMMON" then
        EntUserCommonData:Clear(uid)
    elseif type == "DAILY" then
        EntUserDailyData:Clear(uid)
    end
end

function user_data_dc.get_common_value(uid, id)
    local result = EntUserCommonData:GetValue(uid, id, "value")
    if not result then result = 0 end
    return result
end

function user_data_dc.get_common_list(uid)
    return EntUserCommonData:Get(uid)
end

function user_data_dc.set_common_value(uid, id, value)
    local org_value = EntUserCommonData:GetValue(uid, id, "value")
    if not org_value then
        local data = {
            uid = uid,
            datatype = id,
            value = value,
        }
        return EntUserCommonData:Add(data)
    end
    return EntUserCommonData:SetValue(uid, id, "value", value)
end

function user_data_dc.get_common_range_list(uid, field, value)
    return EntUserCommonData:GetMultiByFieldRange(uid, field, value)
end

function user_data_dc.get_daily_range_list(uid, field, value)
    return EntUserDailyData:GetMultiByFieldRange(uid, field, value)
end

function user_data_dc.get_daily_value(uid, id)
    local result = EntUserDailyData:GetValue(uid, id, "value")
    if not result then result = 0 end
    return result
end

function user_data_dc.get_daily_list(uid)
    return EntUserDailyData:GetMultiByField(uid)
end

function user_data_dc.set_daily_value(uid, id, value)
    local org_value = EntUserDailyData:GetValue(uid, id, "value")
    if not org_value then
        local data = {
            uid = uid,
            datatype = id,
            value = value,
        }
        return EntUserDailyData:Add(data)
    end
    return EntUserDailyData:SetValue(uid, id, "value", value)
end

function user_data_dc.add_daily_value(uid, id)
    local org_value = EntUserDailyData:GetValue(uid, id, "value")
    if not org_value then
        local data = {
            uid = uid,
            datatype = id,
            value = 1,
        }
        return EntUserDailyData:Add(data)
    end
    return EntUserDailyData:SetValue(uid, id, "value", org_value + 1)
end

return user_data_dc