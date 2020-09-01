require "CommonEntity"

local EntityType = class(CommonEntity)

function EntityType:ctor()
    self.tbname = "s_growup"
end

return EntityType.new()