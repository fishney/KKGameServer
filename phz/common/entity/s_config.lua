require "CommonEntity"

local EntityType = class(CommonEntity)

function EntityType:ctor()
    self.tbname = "s_config"
end

return EntityType.new()