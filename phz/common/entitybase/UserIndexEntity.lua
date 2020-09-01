local skynet = require "skynet"
require "UserEntity"

-- UserIndexEntity
UserIndexEntity = class(UserEntity)

--[[
userindex 使用要点

跟usermulti区别，二级索引不是递增主键id而是基础配置索引
mysql表需要有baseid字段作为二级索引，[uid,baseid]需要是UNIQUE KEY
增加数据操作确保是初始化需要
--]]

--self.recordset格式如下：
--[[
{
	[uid1] =
	{
		[baseid1] = { field1 = 1, field2 = 2 }
		[baseid2] = { field1 = 1, field2 = 2 }
	},
	[uid2] =
	{
		[baseid1] = { field1 = 1, field2 = 2 }
		[baseid2] = { field1 = 1, field2 = 2 }
	},
}
--]]

-- 数据实例归属玩家
local owner = 0

function UserIndexEntity:ctor()
	self.ismulti = true		-- 是否多行记录
end

function UserIndexEntity:dtor()
end

-- 加载玩家数据
function UserIndexEntity:Load(uid)
	local hasdata = true
	owner = uid
	if not self.recordset[uid] then
		local rs = skynet.call(".dbmgr", "lua", "load_user_multi_index", self.tbname, uid)
		if not table.empty(rs) and rs then
			self.recordset[uid] = rs
		else
			hasdata = false
		end
	end
	return hasdata
end

-- 将内存中的数据先同步回redis,再从redis加载到内存（该方法要不要待定）
function UserIndexEntity:ReLoad(uid)

end

-- 卸载玩家数据
function UserIndexEntity:UnLoad(uid)
	local rs = self.recordset[uid]
	if rs then
		for k, v in pairs(rs) do
			rs[k] = nil
		end

		self.recordset[uid] = nil

		-- 是否需要移除待定
		-- 从redis删除，但不删除mysql中的数据
	end
end

-- 清除玩家数据
function UserIndexEntity:Clear(uid)
	local rs = self.recordset[uid]
	if rs then
		for k, v in pairs(rs) do
			rs[k] = nil
		end
		self.recordset[uid] = nil
		-- 删除db中的数据
		local record = {uid = uid}
		local ret = skynet.call(".dbmgr", "lua", "clear", self.tbname, record, self.type, nosync)
	end
end

-- record.lua,record.lua,v形式table
-- 内存中不存在，则添加，并同步到redis
function UserIndexEntity:Add(record, nosync)
	if not record.uid then return end

	local baseid = record[self.baseid]
	if self.recordset[record.uid] and self.recordset[record.uid][baseid] then return end		-- 记录已经存在，返回

	if nil == record[self.baseid] then
		record[self.baseid] = self:GetNextBaseId()
		baseid = record[self.baseid]
	end

	--if not baseid or baseid == 0 then
	--	-- userindex 增加数据必须含有baseid
	--	return
	--end

	local ret = skynet.call(".dbmgr", "lua", "add", self.tbname, record, self.type, nosync)
	if ret then
		if not self.recordset[record.uid] then
			self.recordset[record.uid] = {}
			--self.recordset[record.uid][baseid] = {}
			setmetatable(self.recordset[record.uid], { __mode = "k" })
		end
		self.recordset[record.uid][baseid] = record
	end
	return ret, baseid
end

-- record中包含uid字段,record为k,v形式table
-- 从内存中删除，并同步到redis
function UserIndexEntity:Delete(record, nosync)
	if not record.uid then return end

	local baseid = record[self.baseid]
	if not self.recordset[record.uid] or not self.recordset[record.uid][baseid] then return end		-- 记录不存在，返回

	local ret = skynet.call(".dbmgr", "lua", "delete_by_index", self.tbname, record, self.type, self.baseid, nosync)

	if ret then
		self.recordset[record.uid][baseid] = nil
	end

	return ret
end

-- function UserIndexEntity:Remove(record.lua)
-- end

-- record中包含uid字段,record为k,v形式table
function UserIndexEntity:Update(record, nosync)
	if not record.uid then return end

	local baseid = record[self.baseid]

	if not self.recordset[record.uid] or not self.recordset[record.uid][baseid] then return end		-- 记录不存在，返回

	local ret = skynet.call(".dbmgr", "lua", "update_by_index", self.tbname, record, self.type, self.baseid, nosync)
	if ret then
		for k, v in pairs(record) do
			self.recordset[record.uid][baseid][k] = v
		end
	end

	return ret
end

-- 从内存中获取，如果不存在可能是其他的离线玩家数据，则加载数据到redis，但不保存在内存
-- field为空，获取整行记录，返回k,v形式table
-- field为字符串表示获取单个字段的值，如果字段不存在，返回nil
-- field为一个数组形式table，表示获取数组中指定的字段的值，返回k,v形式table
function UserIndexEntity:Get(uid, baseid, field)
	if not baseid and not field then
		return self:GetMulti(uid)
	end
	-- 从内存获取
	local record
	if self.recordset[uid] then
		if not field then
			record = self.recordset[uid][baseid] or {}
		elseif type(field) == "string" then
			if not self.recordset[uid][baseid] then return end
			record = self.recordset[uid][baseid][field]
		elseif type(field) == "table" then
			record = {}
			local t = self.recordset[uid][baseid]
			if not t then return record end
			for i=1, #field do
				record[field[i]] = t[field[i]]
			end
		end
		return record
	end
	-- 其他玩家数据
	if owner ~= uid then
		-- 从redis获取，如果redis不存在，从mysql加载
		local orifield = field
		if type(field) == "string" then
			field = { field }
		end
		record = skynet.call(".dbmgr", "lua", "get_user_multi_index", self.tbname, uid, baseid) -- 不存在返回空的table {}
		if type(orifield) == "string" then
			return record[orifield]
		end
	end
	return record
end

-- 获取单个字段的值,field为string，获取多个字段的值，field为table
function UserIndexEntity:GetValue(uid, baseid, field)
	local record = self:Get(uid, baseid, field)
	if record then
		return record
	end
end

-- 成功返回true，失败返回false
-- 设置单个字段的值，field为string，data为值，设置多个字段的值,field为key,value形式table,data为nil
function UserIndexEntity:SetValue(uid, baseid, field, value)
	local record = {}
	baseid = baseid or uid
	record["uid"] = uid
	record[self.baseid] = baseid
	if value then
		record[field] = value
	else
		for k, v in pairs(field) do
			record[k] = v
		end
	end
	return self:Update(record)
end

-- 内部接口
-- 多行记录，根据uid返回所有行
-- 从内存中获取，如果不存在可能是其他的离线玩家数据，则加载数据到redis，但不保存在内存
-- 没有则返回空表
function UserIndexEntity:GetMulti(uid)
	local rs = self.recordset[uid]
	if not rs then
		-- 其他玩家数据
		if owner ~= uid then
			-- 从redis获取，如果redis不存在，从mysql加载
			rs = skynet.call(".dbmgr", "lua", "get_user_multi_index", self.tbname, uid)
			-- self.recordset[uid] = rs
		end
	end
	return rs
end

-- 通过字段筛选多条数据
function UserIndexEntity:GetMultiByField(uid, field, value)
	assert(type(field) == "string")
	local record = self:GetMulti(uid)
	local rs = {}
	if nil ~= record then
		for k,v in pairs(record) do
			if v[field] == value then
				rs[k] = v
			end
		end
	end
	return rs
end

-- 通过字段数字范围筛选多条数据
function UserIndexEntity:GetMultiByFieldRange(uid, field, value )
	assert(type(field) == "string")
	local record = self:GetMulti(uid)
	local rs = {}
	for k,v in pairs(record) do
		if v[field] > value then
			rs[k] = v
		end
	end
	return rs
end
