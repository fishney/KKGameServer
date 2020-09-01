require "CommonEntity"

local EntityType = class(CommonEntity)

function EntityType:ctor()
	self.tbname = "s_game"
end

return EntityType.new()