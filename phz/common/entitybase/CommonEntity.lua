local skynet = require "skynet"
require "Entity"

-- CommonEntity
CommonEntity = class(Entity)

function CommonEntity:ctor()
	self.type = 3
end

function CommonEntity:Init()
	self.pk, self.key, self.indexkey = skynet.call(".dbmgr", "lua", "get_table_key", self.tbname, self.type)
end

function CommonEntity:dtor()
end

-- 加载整张表数据
function CommonEntity:Load()
	if table.empty(self.recordset) then
		if self.table ~= "d_account" then --account数据不在login完全加载
			local rs = skynet.call(".dbmgr", "lua", "get_common", self.tbname)
			if rs then
				self.recordset = rs
			end
		end
	end
end

-- row中包含pk字段,row为k,v形式table
-- 内存中不存在，则添加，并同步到redis
function CommonEntity:Add(row, nosync)
	local key = self:GetKey(row)
	if self.tbname == 'd_account' then --针对account表单独处理
		local t = do_redis({ "hgetall", self.tbname .. ":" .. key })
		if t ~= nil and not table.empty(t) then
			return -- 记录已经存在，返回
		end
	else
		if row.id and self.recordset[key] then
			print(os.date("%Y-%m-%d %H:%M:%S", os.time()), "数据已存在:", row.id, " data:", self.recordset[key])
			return  -- 记录已经存在，返回
		end
	end

	local id = row[self.pk]
	if not id or id == 0 then
		id = self:GetNextId()
		row[self.pk] = id
	end
	local ret = skynet.call(".dbmgr", "lua", "add", self.tbname, row, self.type, nosync)
	if ret then
		self.recordset[key] = row
	end
	return true
end

-- row中包含pk字段,row为k,v形式table
-- 从内存中删除，并同步到redis
function CommonEntity:Delete(row, nosync)
	local key = self:GetKey(row)
	if self.tbname ~= "d_account" then
		if not row.id or not self.recordset[key] then return end		-- 记录不存在，返回
	end


	local ret = skynet.call(".dbmgr", "lua", "delete", self.tbname, row, self.type, nosync)

	if ret then
		key = self:GetKey(row)
		self.recordset[key] = nil
	end

	return true
end

-- row中包含pk字段,row为k,v形式table
-- 仅从内存中移除，但不同步到redis
function CommonEntity:Remove(row)
	local key = self:GetKey(row)
	if not row.id or not self.recordset[key] then return end		-- 记录不存在，返回

	key = self:GetKey(row)
	self.recordset[key] = nil

	return true
end

-- row中包含pk字段,row为k,v形式table
function CommonEntity:Update(row, nosync)
	local key = self:GetKey(row)
	if self.tbname ~= "d_account" then
		if not row.id or not self.recordset[key] then 
			return 
		end		-- 记录不存在，返回
	end
	local write2mysqlnow = false
	if self.tbname == 's_game' then 
		write2mysqlnow = true
	end
	local ret = skynet.call(".dbmgr", "lua", "update", self.tbname, row, self.type, nosync, write2mysqlnow)
	if ret then
		key = self:GetKey(row)
		for k, v in pairs(row) do
			self.recordset[key][k] = v
		end
	end

	return true
end

function CommonEntity:Get(...)
	local t = { ... }
	assert(#t > 0)
	local key
	if #t == 1 then
		key = t[1]
	else
		key = ""
		for i = 1, #t do
			if i > 1 then
				key = key .. ":"
			end
			key = key .. tostring(t[i])
		end
	end

	local t = self.recordset[key]
	if self.tbname ~= "d_account" then
		return t or {}
	end

	--针对d_account表优先走内存，然后走redis
	if nil ~= t and not table.empty(t) then
		return t
	end

	print("hgetall key:", self.tbname .. ":" .. key)
	local row = do_redis({ "hgetall", self.tbname .. ":" .. key })
	if row ~= nil then
		row = make_pairs_table(row)
		return row or {}
	end

	return {}
end

function CommonEntity:GetValue(id, field)
	local record = self:Get(id)
	if record then
		return record[field]
	end
end

function CommonEntity:SetValue(id, field, data, nosync)
	local record = {}
	record[self.pk] = id
	record[field] = data
	self:Update(record, nosync)
end

function CommonEntity:SetValueByKey(id, row, nosync)
	local record = {}
	record[self.key] = id
	for field , val in pairs(row) do
		record[field] = val
	end
	self:Update(record, nosync)
end

function CommonEntity:GetKey(row)
	local fields = string.split(self.key, ",")
	local key
	for i=1, #fields do
		if i == 1 then
			key = row[fields[i]]
		else
			key = key .. ":" .. row[fields[i]]
		end
	end

	return key
end

function CommonEntity:GetAll()
	return self.recordset
end