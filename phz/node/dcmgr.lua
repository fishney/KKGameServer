local user_dc = require "user_dc" --玩家相关的dc列表
local user_data_dc = require "user_data_dc"
-- local quest_dc = require "quest_dc"
-- local user_bind_dc = require "user_bind_dc"

local userdc_list = {
    user_dc,
    user_data_dc,
    -- quest_dc,
    -- user_bind_dc,
}

local dcmgr = {}
dcmgr.user_dc      = user_dc
dcmgr.user_data_dc = user_data_dc


function dcmgr.start()
    for _, dc in pairs(userdc_list) do
        dc.init(uid)
    end
end

function dcmgr.load(uid)
    for _, dc in pairs(userdc_list) do
        dc.load(uid)
    end
end

function dcmgr.unload(uid)
    for _, dc in pairs(userdc_list) do
        dc.unload(uid)
    end
end

return dcmgr
