require "UserIndexEntity"

local EntityType = class(UserIndexEntity)

function EntityType:ctor()
    self.tbname = "d_user_daily_data"
end

return EntityType.new()