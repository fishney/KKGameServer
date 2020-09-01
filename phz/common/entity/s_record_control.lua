require "CommonEntity"

local EntityType = class(CommonEntity)

function EntityType:ctor()
    self.tbname = "s_record_control"
end

return EntityType.new()