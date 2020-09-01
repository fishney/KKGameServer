local skynet = require "skynet"
local protobuf = require "protobuf"
local random = require "random"
local MessagePack = require "MessagePack"
local cjson = require "cjson"
local is_release = skynet.getenv('isrelease')
local is_logrelease = skynet.getenv('logrelease')
--local file = io.open("./proto/dtmessage.pb","rb")
--local buffer = file:read "*a"
--file:close()
--protobuf.register(buffer)

systemprint = print
systemerror = error

function do_redis(args, uid)
	local cmd = assert(args[1])
	args[1] = uid
	return skynet.call(".redispool", "lua", cmd, table.unpack(args))
end

function do_redis_withprename(servicename, args, uid)
    local cmd = assert(args[1])
    args[1] = uid
    return skynet.call("."..servicename.."redispool", "lua", cmd, table.unpack(args))
end

function do_mysql_direct(sql)
	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function do_mysql_queue(sql)
	return skynet.call(".dbsync", "lua", "sync", sql)
end

--关闭房间
function updateDeskStatus(uuid, status)
	status = status or 3
	local sql = string.format("update d_desk set status=%d where uuid='%d' ", status, uuid)
	return skynet.call(".dbsync", "lua", "sync", sql)
end

--matchdepth 是用堆栈的第几行数据加到head里面
function GetLogHead(matchdepth)
	local head = SERVICE_NAME
	local tracebackarr = string.split(debug.traceback(),"\n")
    if #tracebackarr >= matchdepth then
    	local tracebackmsg = string.split(tracebackarr[matchdepth]," ")[1] -- 	./lualib/webreq.lua:58:
    	tracebackmsg = string.gsub(tracebackmsg, "\t", "") 
    	local msgarr = string.split(tracebackmsg, "/", "")
    	local msg = msgarr[#msgarr] -- webreq.lua:58:
    	if string.len(msg) < 2 then
    		head = string.format("%s(%s)", head, msg)
    	else
    		head = string.format("%s(%s)", head, string.sub(msg, 1, string.len(msg)-1--[[去掉最后的:]]))
    	end 
    	
    end
    return head
end

--用 concatstr 拼接字符串
--@param log_tbl日志table
--@param concatstr拼接的字符串 如果没传默认为 空格
--@return 拼接好的字符串
local function log_tostring(log_tbl, concatstr)
    if concatstr == nil then
        concatstr = " "
    end
    
    local tem = {}
    for idx, msg in pairs(log_tbl) do
        if type(msg) ~= 'string' then
            msg = tostring(msg)
        end
        if is_logrelease then
            msg = string.gsub(msg, '\n', '');
            msg = string.gsub(msg, '\t', '');
        end
        table.insert(tem, msg)
    end
    return table.concat(tem, concatstr)
end

--用空格拼接字符串 
--@return str
function concatStr( ... )
    local msg = log_tostring({str, gameid, ...}, concatstr)
    return msg
end

function dlog(str, gameid, ...)
	print(os.date("%Y-%m-%d %H:%M:%S", os.time())  .. ' ' .. os.clock(), "游戏["..gameid.."]", str, ...)
end

function plog(str, gameid, ...)
	if is_logrelease then
		return
	end
    -- local msg = table.concat({...}, " ")
    local msg = log_tostring({str, gameid, ...})
    skynet.send(".log", "lua", "info", GetLogHead(4), msg)
end

function print(...)
	local head = string.format("%s [%s]",os.date("%Y-%m-%d %H:%M:%S"), GetLogHead(4))
	local msg = log_tostring({head, ...})
	systemprint(msg)
end

function error(...)
    local head = string.format("%s [%s]",os.date("%Y-%m-%d %H:%M:%S"), GetLogHead(4))
	local msg = log_tostring({head, ...})
	systemerror(msg)
end

function LOG_DEBUG(...)
	if is_logrelease then
		return
	end

    local msg = log_tostring({...})
    skynet.send(".log", "lua", "debug", GetLogHead(4), msg)
end

function LOG_INFO(...)
	if is_logrelease then
		return
	end
    -- local msg = table.concat({...}, " ")
    local msg = log_tostring({...})
    skynet.send(".log", "lua", "info", GetLogHead(4), msg)
end

function LOG_WARNING(...)
    local msg = log_tostring({...})
    skynet.send(".log", "lua", "warning", GetLogHead(4), msg)
end

function LOG_ERROR(...)
    local msg = log_tostring({...})
    skynet.send(".log", "lua", "error", GetLogHead(4), msg)
end

function LOG_FATAL(...)
    local msg = log_tostring({...})
    skynet.send(".log", "lua", "fatal", GetLogHead(4), msg)
end

function pb_encode(msg)
	if not msg then
		LOG_ERROR("msg is nil")
	end
	local data = protobuf.encode("DatingMessage.Message", msg)
	if not data then
		LOG_ERROR("pb_encode error")
	end
	return data
end

function pb_decode(data)
	return protobuf.decode("DatingMessage.Message", data)
end

function pb_encode(data)
	local json_data = cjson.encode(data)
	return MessagePack.pack(json_data)
end

function pack_decode(data)
	local msg = data:sub(9, #data)
	return MessagePack.unpack(msg)
end

function MK_Index(first, second)
	local indexTem = 1000
	return tonumber(first*indexTem+second)
end

function Get_First_Index(index)
	if index > 10 then
		return math.floor(index / 10)
	else
		return index
	end
end

function Get_Second_Index(index)
	return index % 1000
end

function make_pairs_table(t, fields)
	assert(type(t) == "table", "make_pairs_table t is not table")

	local data = {}

	if not fields then
		for i=1, #t, 2 do
			data[t[i]] = t[i+1]
		end
	else
		for i=1, #t do
			data[fields[i]] = t[i]
		end
	end

	return data
end

function make_pairs_table_int(t, fields)
	assert(type(t) == "table", "make_pairs_table t is not table")

	local data = {}

	if not fields then
		for i=1, #t, 2 do
			data[t[i]] = tonumber(t[i+1])
		end
	else
		for i=1, #t do
			data[fields[i]] = tonumber(t[i])
		end
	end

	return data
end

-- 生成通知消息包
function NotifyObj(code,questInfo)
	local notifyobj = {}
	notifyobj.response = {}
	notifyobj.opCode = "NOTIFY_INFO"
	notifyobj.response.errorCode = PDEFINE.RET.SUCCESS
	notifyobj.response.notifyInfo = {}
	notifyobj.response.notifyInfo.questInfo = {}
	notifyobj.response.notifyInfo.questInfo = questInfo
	notifyobj.response.notifyInfo.notifyCode = code
	return notifyobj
end

-- 根据随机列表掉落物品
function RandomLoot(loot_list, times)
	local loot_result = {}
	local loop_times = 1
	if times and times > 0 then
		loop_times = times
	end
	local total_probability = 0
	for _,loot in pairs(loot_list) do
		total_probability = total_probability + loot.Probability
	end
	if total_probability > 1.0 then total_probability = 1.0 end
	for i=1,loop_times do
		local random_value = random.Get(0, total_probability)
		local ret_item = {}
		for _,loot in pairs(loot_list) do
			if loot.Probability >= 1.0 then
				ret_item = table.copy(loot, true)
				table.insert(loot_result, ret_item)
				break
			end
			random_value = random_value - loot.Probability
			if random_value < 0 then
				ret_item = table.copy(loot, true)
				table.insert(loot_result, ret_item)
				break
			end
		end
	end
	return loot_result
end

function OFFLINE_CMD(uid, cmd, params, append)
	local param = ""
	for i,v in pairs(params) do
		if i == 1 then
			param = param .. v
		else
			param = param .. "," .. v
		end
	end
	local sql = ""
	if append then
		sql = "insert into d_offline_multi_cmd(uid,cmd,param) values("..uid..",'"..cmd.."','"..param.."')"
	else
		sql = "replace into d_offline_single_cmd(uid,cmd,param) values("..uid..",'"..cmd.."','"..param.."')"
	end
	do_mysql_direct(sql)
	return true
end

function GUID()
	local seed = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
	local tb = {}
	for i=1,32 do
		table.insert(tb, seed[random.Get(1,16)])
	end
	local sid = table.concat(tb)
	return string.format("%s-%s-%s-%s-%s",
			string.sub(sid,1,8),
			string.sub(sid,9,12),
			string.sub(sid,13,16),
			string.sub(sid,17,20),
			string.sub(sid,21,32)
		)
end

function randomCode(count)
	local seed = {'0','1','2','3','4','5','6','7','8','9'}
	local seed1 = {'1','2','3','4','5','6','7','8','9'}
	local tb = {}
	for i=1,count do
		if i == 1 then
			table.insert(tb, seed1[random.Get(1,9)])
		else
			table.insert(tb, seed[random.Get(1,10)])
		end
	end
	local sid = table.concat(tb)
	return sid
end

function payId()
	local seed = {'0','1','2','3','4','5','6','7','8','9'}
	local tb = {}
	for i=1,10 do
		table.insert(tb, seed[random.Get(1,10)])
	end
	local sid = table.concat(tb)
	return sid
end

function  random_s_e_value()
	return random.GetRange(1, 9, 6) 
end

function  randomSomeRValue(s,e,cnt)
	return random.GetRange(s,e,cnt) 
end

--[[function  random_value(value)
	local random_value = random.Get(1, value)
	return random_value
end]]

function  random_value(value)
	local random_table = {}
	for i = 1, 100 do
		table.insert(random_table,random.Get(1, value))
	end
	local index = random.Get(1, 100)
	local random_value = random_table[index]
	return random_value
end


function  random_gold(min,max)
	local random_value = random.Get(min, max)
	return random_value
end

local function printT(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, v)
    end
   	table.sort(result)
    --
    local str = ""
    for k, v in ipairs(result) do
        str = str .. v .. ","
    end
    --
    return str
end

local function insertList(t, t1)
    for i = 1, #t1 do
        table.insert(t, t1[i])
    end
end

local function seprateLaizi(t,LaiZi)
    local tTmpList = {}
    local laiziList = {}  
      
    for i = #t, 1, -1 do  
        local v = t[i]  
        if v == LaiZi then  
            table.insert(laiziList, v)  
        else
            table.insert(tTmpList, v)  
        end  
    end  
    return tTmpList, laiziList  
end 


local function removeOneNum(t, v)
    for i = 1, #t do
        if t[i] == v then
            table.remove(t, i)
            break
        end
    end
end

local function getSameNumCount(t, v)
    local count = 0
    for i = 1, #t do
        if v == t[i] then
            count = count + 1
        end
    end
    return count
end

function getCoin(htype,difen,pcsC,TgangC,htp)
	print("-----222222---",htype)
	local db = 0
	local tmp_coin = 0
	for _,gtype in pairs(htype) do
		db = PDEFINE.COIN_TYPE[gtype]
		tmp_coin = tmp_coin + db
	end
	local taddcoin = 0
	if TgangC then
		if htp == 2 then
			taddcoin = taddcoin + (TgangC-1)*2
		end
	end
	if pcsC > 0 then
		taddcoin = taddcoin + (pcsC-1)*2
	end
	return tmp_coin + taddcoin
end

function  random_uid(uid)
	local CACHE_KEY = "UID_LIST"
	if uid then
		do_redis({"zrem", CACHE_KEY, uid})
	else
		local row = do_redis({ "zrevrangebyscore", CACHE_KEY, 1})
		if #row == 0 then
			local num = do_redis({ "zcard", "UID_LIST"}) or 0
			error("Get uid error ---->------>-----> Redis 池子中的uid个数：", num)
		end
		uid = row[1]
		do_redis({"zrem", CACHE_KEY, uid})
	end
	return tonumber(uid)

	--local random_value = random.GetRange(0, 9, 7)
	--local uid = ""
	--for i,key in pairs(random_value) do
	--	if i == 1 and key == 0 then
	--		key = 3
	--	end
	--	uid = uid .. key
	--end
	--return tonumber(uid)
end

-------- 打乱数组 --------
function random_array(arr) 
    local tmp, index 
    for i= 1, #arr-1 do 
        index = math.random(i, #arr)
        if i ~= index then 
            tmp = arr[index]
            arr[index] = arr[i]
            arr[i] = tmp
        end
    end
end
 
function getCardValue(card)
    return card & 0x0F
end

function getCardColor(card)
    return card & 0xF0
end

--获取什么  恭喜 "玩家名字" 在 "游戏名称"中拿到"什么牌型",一把获得"金币数"5万--------------这种类型的游戏
function strinigColorA(uname,gname,cname,gold)
	local msg = string.format("恭喜<color=#ff0000>%s</c>在<color=#ff0000>%s</c>游戏中拿到<color=#ff0000>%s</c>牌型,一把获得<color=#ff0000>%s金币</c>",uname,gname,cname,gold)
	return msg
end

--获取什么  恭喜 "玩家名字" 在 "游戏名称"中拿到"什么牌型"
function strinigColorB(uname,gname,cname)
	local msg = string.format("恭喜<color=#ff0000>%s</c>在<color=#ff0000>%s</c>游戏中拿到<color=#ff0000>%s</c>牌型",uname,gname,cname)
	return msg
end

--获取什么  恭喜 "玩家名字" 在 "游戏名称"中押中"什么牌型",一把获得"金币数"5万--------------这种类型的游戏
function strinigColorC(uname,gname,cname,gold)
	local msg = string.format("恭喜<color=#ff0000>%s</c>在<color=#ff0000>%s</c>游戏中押中<color=#ff0000>%s</c>牌型,一把获得<color=#ff0000>%s金币</c>",uname,gname,cname,gold)
	return msg
end

--获取什么  恭喜 "玩家名字" 在 "游戏名称"中一把"什么牌型"
function strinigColorTongsha(uname,gname,gold)
	local msg = string.format("恭喜<color=#ff0000>%s</c>在<color=#ff0000>%s</c>游戏中庄家通杀,一把获得<color=#ff0000>%s金币</c>",uname,gname,gold)
	return msg
end

--获取什么  恭喜 "玩家名字" 在 "游戏名称"中一把"什么牌型"
function strinigColorCleida(uname,gname,gold)
	local msg = string.format("恭喜<color=#ff0000>%s</c>在<color=#ff0000>%s</c>游戏中全垒打,一把获得<color=#ff0000>%s金币</c>",uname,gname,gold)
	return msg
end

--所有游戏中每次押注嬴得金币≥200金币时


local function horse_format(uname, coin)
    local len = #uname
    --uid = string.sub(uid,1,1) .."******" ..string.sub(uname, len, len)
    if not coin then coin = 0 end
    coin = string.format("%.2f", coin)
    return uname, coin
end

function serializePlayername(playername)

    if #playername > 16 then
    	local v = "%s%s"
    	playername = string.format(v, string.sub(playername,1,16),".")
    end
    return playername
end

--跑马灯  玩家中得分数大于等于押注总额的30倍时
function horse_race_lamp1(uname, coin, betcoin)
    if betcoin ~= nil and coin > 0 and coin >= betcoin * 30 then
    	uname, coin = horse_format(uname, coin)
    	local MSG_CONF = 
    	{
    		"玩家<color=#05f989>******%s</c>赢得<color=#f525d5>%s</c>",
    		"Player<color=#05f989>******%s</c>won <color=#f525d5>%s</c> "
    	}
    	local msg = {}
    	for k,v in pairs(MSG_CONF) do
    		table.insert(msg, string.format(v, string.sub(uname,-4), tostring(coin)))
    	end
	   return msg
    end
    return nil
end

--跑马灯  免费游戏的公告
function horse_race_lamp2(uname)
	uname = horse_format(uname)
	local MSG_CONF = 
	{
		"玩家<color=#05f989>******%s</c>赢得免费游戏",
		"Player<color=#05f989>******%s</c>won FREE GAME "
	}
	local msg = {}
	for k,v in pairs(MSG_CONF) do
		table.insert(msg, string.format(v, string.sub(uname,-4)))
	end
	return msg
end

--跑马灯  单双大奖公告
function horse_race_sin_dou(uname,coin)
	if coin >= 97 then
		local uname = serializePlayername(uname)
		local MSG_CONF = 
		{
			"玩家<color=#05f989>%s</c>运气爆棚！在<color=#fb060c>单双</c>中赢得<color=#f525d5>%s</c>",
		}
		local msg = {}
		for k,v in pairs(MSG_CONF) do
			table.insert(msg, string.format(v, uname,tostring(coin)))
		end
		return msg
	end
end

--跑马灯  牛牛大奖公告
function horse_race_niuniu(uname,coin)
	if coin >= 50 then
		local uname = serializePlayername(uname)
		local MSG_CONF = 
		{
			"玩家<color=#05f989>%s</c>牛气冲天！在<color=#fb060c>牛牛</c>中赢得<color=#f525d5>%s</c>",
		}
		local msg = {}
		for k,v in pairs(MSG_CONF) do
			table.insert(msg, string.format(v, uname,tostring(coin)))
		end
		return msg
	end
end

--跑马灯  单双大奖公告
function horse_race_sin_dou_red_packge(uname,coin)
	if coin > 0 then
		local uname = serializePlayername(uname)
		local MSG_CONF = 
		{
			"<color=#05f989>%s</c>在<color=#fb060c>红包活动</c>中获得<color=#ffd700>%s</c>",
		}
		local msg = {}
		for k,v in pairs(MSG_CONF) do
			table.insert(msg, string.format(v, uname,tostring(coin)))
		end
		return msg
	end
end
--用户昵称+运气爆棚！在单双中赢得+中奖金额！

--跑马灯  玩家中得JP奖池的公告：
function horse_race_lamp3(uname, coin)
	if coin > 0 then
		uname, coin = horse_format(uname, coin)
		local MSG_CONF = 
		{
			"玩家<color=#05f989>******%s</c>赢取了随机积宝大奖<color=#f525d5>%s</c>",
			"Player<color=#05f989>******%s</c>won random jackpot<color=#f525d5>%s</c>"
		}
		local msg = {}
		for k,v in pairs(MSG_CONF) do
			table.insert(msg, string.format(v, string.sub(uname,-4), tostring(coin)))
		end
		return msg
	end
end

--过滤特殊字符
function filter_spec_chars(s)
	local charTypes = {num="数字",char="字母",chs="中文"}
	local ss = {}
	local k = 1
	while true do
		if k > #s then break end
		local c = string.byte(s,k)
		if not c then break end
		if c<192 then
			if (c>=48 and c<=57) then
				if charTypes.num then
					table.insert(ss, string.char(c))
				end
			elseif (c>= 65 and c<=90) or (c>=97 and c<=122) then
				if charTypes.char then
					table.insert(ss, string.char(c))
				end
			end
			k = k + 1
		elseif c<224 then
			k = k + 2
		elseif c<240 then
			if c>=228 and c<=233 then
				local c1 = string.byte(s,k+1)
				local c2 = string.byte(s,k+2)
				if c1 and c2 then
					local a1,a2,a3,a4 = 128,191,128,191
					if c == 228 then a1 = 184
					elseif c == 233 then a2,a4 = 190,c1 ~= 190 and 191 or 165
					end
					if c1>=a1 and c1<=a2 and c2>=a3 and c2<=a4 then
						if charTypes.chs then
							table.insert(ss, string.char(c,c1,c2))
						end
					end
				end
			end
			k = k + 3
		elseif c<248 then
			k = k + 4
		elseif c<252 then
			k = k + 5
		-- elseif c<254 then
			k = k + 6
		end
	end
	return table.concat(ss)
end

--用cjson来解析字符串
function jsondecode( body )
    return cjson.decode(body)
end

function two_value_Add(value1,value2)
	if not value2 then value2 = 0 end
	local value = value1 + value2
	local result = tonumber(string.format("%.2f", value))
	return result
end

--double的加
function Double_Add( ... )

	local para_tbl = {...}
	local value = 0
	for _, v in pairs(para_tbl) do
		if is_release == nil or is_release == false then
			-- local littlev = math.abs(v)-math.floor(math.abs(v))
			-- local vstr = tostring(littlev)
			local vstr = tostring(v)
			local fields = string.split(vstr, ".")
			if #fields > 1 then
				if #fields[2] > 2 then
					LOG_ERROR( "Double_Add value too long.some err occurs? check para:"..vstr..",littlev:"..fields[2], para_tbl )
				end
				-- assert(#fields[2] <= 4, "Double_Add value too long.some err occurs? check para:"..vstr..",littlev:"..fields[2])
			end
		end
		value = value + v * 10000
	end
	return math.floor(value+0.01)/10000
end

function urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function urlencode(input)
    input = string.gsub(input, "([^%w%.%- ])", 
    	function(c)
    		return string.format("%%%02X", string.byte(c)) 
    	end
    )
    return string.gsub(input, " ", "+")
end

--加载配置文件，用换行和=分割
function load_config(filename)
    local f = assert(io.open(filename))
    local source = f:read "*a"
    f:close()
    local tmp = {}
    -- source.split()
    assert(load(source, "@"..filename, "t", tmp))()

    return tmp
end

--检测table中是否有指定的value
--@param table_p 待检测的table
--@param value 指定value
--@return true表示包含  false表示不包含
function checkInTable( table_p, value )
    for k,v in pairs(table_p) do
        if v == value then
            return true
        end
    end
    return false
end

--table元素乱序
--@param arr 待乱序的table
--@param arr_index arr的原序列 arr乱序的时候会跟着一起乱序
function stufftable( arr, arr_index )
    assert( arr ~= nil )
    assert( #arr > 0 )
    if arr_index ~= nil then
        assert( #arr == #arr_index )
    end
    
    if #arr > 1 then
        for i = 1,#arr do
            local ranOne = math.random(1,#arr+1-i)
            arr[ranOne], arr[#arr+1-i] = arr[#arr+1-i],arr[ranOne]
            if arr_index ~= nil then
                arr_index[ranOne], arr_index[#arr_index+1-i] = arr_index[#arr_index+1-i],arr_index[ranOne]
            end
        end
    end
end

--根据概率从指定data中选择数据
--@param rate 概率 概率运算的时候会把概率运算放大1W倍
--@param data 数据table
--@return 选择的数据,选择的数据在表中的序号
function randomtablebyrate(rate, data)
    local choose
    local allrate = 0
    for i,v in ipairs(rate) do
        allrate = allrate + v
    end
    allrate = allrate*10000
    local randrate = math.random(1, math.ceil(allrate))
    local tmprate = 0
    local choose
    local choosei
    for i,v in ipairs(data) do
        tmprate = tmprate + rate[i]*10000
        if randrate <= tmprate then
            choose = v
            choosei = i
            break
        end
    end
    if choose == nil then
        choose = data[#data]
        choosei = #data
    end
    return choose,choosei
end

--根据赔率从指定data中选择数据
--@param mult_t 赔率 概率运算的时候会把概率运算放大1W倍
--@param data 数据table
--@return 选择的数据,选择的数据在表中的序号
function randomtablebymult(mult_t, data)
    local rate = {}
    local rate_tmp = {}
    local all = 0
    for i, mult in ipairs(mult_t) do
        local num = 1/mult
        table.insert(rate_tmp, num)
        all = all + num
    end
    for _, prob in ipairs(rate_tmp) do
        table.insert(rate, prob/all * 10000)
    end
    return randomtablebyrate(rate, data)
end

--替换整列为万能牌
--@param resultCards手牌 wild 万能牌对应line全部替换成line
function changeCardsLineWild(resultCards,wild,line,lineIndex)
	if not line then
		for _,lineInfo in pairs(lineIndex) do
			local tmpLineInfo = nil
			for i = 1, #lineInfo do
				if resultCards[lineInfo[i]] == wild then
					tmpLineInfo = lineInfo
					break
				end
			end
			if tmpLineInfo then
				for i = 1, #tmpLineInfo do
					resultCards[tmpLineInfo[i]] = wild
				end
			end
		end
	else
		for l,lineInfo in pairs(lineIndex) do
			if l == line then
				local tmpLineInfo = nil
				for i = 1, #lineInfo do
					if resultCards[lineInfo[i]] == wild then
						tmpLineInfo = lineInfo
						break
					end
				end
				if tmpLineInfo then
					for i = 1, #tmpLineInfo do
						resultCards[tmpLineInfo[i]] = wild
					end
				end
			end
		end
	end
end

--@param 替换对应列为对应的牌
function assignLineCard(resultCards,line,card,lineIndex)
	if line then
		for i = 1, #lineIndex[line] do
			resultCards[lineIndex[line][i]] = card
		end
	end
end

--每一列只能出现一个散列牌
--@param resultCards手牌 scatter 万能牌, line替换对应的列
function changeCardsLineOnlyOneFreeCard(resultCards,scatter,spcards,line)
	local lineIndex= {{1,6,11},{2,7,12},{3,8,13},{4,9,14},{5,10,15}}
	if not line then
		for _,lineInfo in pairs(lineIndex) do
			local scatterCnt = 0
			for _,index in pairs(lineInfo) do
				if resultCards[index] == scatter then
					if scatterCnt == 1 then
						local spIndex = math.random(#spcards)
						resultCards[index] = spcards[spIndex]
					end
					scatterCnt = scatterCnt + 1
				end
			end
		end
	else
		for l,lineInfo in pairs(lineIndex) do
			if l == line then
				local scatterCnt = 0
				for _,index in pairs(lineInfo) do
					if resultCards[index] == scatter then
						if scatterCnt == 1 then
							local spIndex = math.random(#spcards)
							resultCards[index] = spcards[spIndex]
						end
						scatterCnt = scatterCnt + 1
					end
				end
			end
		end
	end
end

--更改对应下标对应的整列牌
function changeCardsIndexLine(resultCards,card,index,lineIndex)
	for line,lineInfo in pairs(lineIndex) do
		local tmpLineInfo = nil
		for i = 1, #lineInfo do
			if lineInfo[i] == index then
				tmpLineInfo = lineInfo
				break
			end
		end
		if tmpLineInfo then
			for i = 1, #tmpLineInfo do
				resultCards[tmpLineInfo[i]] = card
			end
		end
	end
end

--从arg中取出不相同的count个不包含ps表的元素
function selectPsNumber(count,ps,indexs,lineIndex)
	local selected={}
	if count < 1 then return selected end
	if not indexs then --每一列找出一个下标
		local tmpIineIndex = table.copy(lineIndex)
		local value = 1
		local swap = 1
		local l = #tmpIineIndex
		for i = 1,l do
			local x = l - i
			local rv = random_value(x)
			if x == 0 then
				rv = 0
			end
			value = i + rv
			swap = tmpIineIndex[i]
			tmpIineIndex[i] = tmpIineIndex[value]
			tmpIineIndex[value] = swap
		end
		for i = 1, 5 do
			for j = 1, #lineIndex[1] do
				if #tmpIineIndex[i] == 0 then break end
				local key = table.remove(tmpIineIndex[i],math.random(#tmpIineIndex[i]))
				local flg = true
		        if ps then
			        for _,k in pairs(ps) do
			            if k == key then
			                flg = false
			                break
			            end
			        end
			    end
		        if flg then
		           table.insert(selected,key)
		           if #selected == count then
		           	   return selected
		           end
		           break
		        end
			end
		end
	    --[[while #selected < count do
	    	if #lineIndex[1] == 0 and #lineIndex[2] == 0 and #lineIndex[3] == 0 and #lineIndex[4] == 0 and #lineIndex[5] == 0  then
	    		break
	    	end
	    	for i = 1, #lineIndex do
	    		if #lineIndex[i] == 0 then

	    		end
		        local key = table.remove(lineIndex[i],math.random(#lineIndex[i]))
		        local flg = true
		        if ps then
			        for _,k in pairs(ps) do
			            if k == key then
			                flg = false
			                break
			            end
			        end
			    end
		        if flg then
		          table.insert(selected,key)
		        end
		        break
		    end
	    end]]
	else
		indexs = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
		while #selected < count do
			if #indexs == 0 then break end
	    	local index = table.remove(indexs,math.random(#indexs))
		    local flg = true
		    if ps then
			    for _,k in pairs(ps) do
			        if k == index then
			           flg = false
			            break
			        end
			    end
			end
		    if flg then
		        table.insert(selected,index)
		    end
	    end
	end
    return selected
end

function findIdx(tbl, card)
    local idx = -1 
    for k, v in ipairs (tbl) do
        if v == card then
            idx = k
            break
        end
    end
    return idx
end

-- 反转一个表 {1, 2, 3, 4, 5} ==>> {5, 4, 3, 2, 1}
function reverseTable(tbl)
    local ret = {}
    for i = #tbl, 1, -1 do
        table.insert(ret, tbl[i])
    end
    return  ret
end

-- 随机取出几个不同的元素(除ps中出现的)
function getAntBunCount(count,tab,ps)
	local value = 1
	local swap = 1
	local indexs = table.copy(tab)
	local l = #indexs
	for i = 1,l do
		local x = l - i
		local rv = math.floor(random_value(x))
		if x == 0 then
			rv = 0
		end
		value = i + rv
		swap = indexs[i]
		indexs[i] = indexs[value]
		indexs[value] = swap
	end
		
	local selected={}
	while #selected < count do
		if #indexs == 0 then break end
		local index = table.remove(indexs,math.random(#indexs))
		local flag = false
		if ps then
			for _,key in pairs(ps) do
				if key == index then
					flag = true
					break
				end
			end
		end
		if not flag then
			table.insert(selected,index)
		end
	end
	return selected
end

function saintWinType(betCoin,winCoin)
	if winCoin > 0 and winCoin <= betCoin*2 then
		return 1
	end
	if winCoin > betCoin*2 and winCoin <= betCoin*8 then
		return 2
	end
	if winCoin > betCoin*8 then
		return 3
	end
	return 0
end

function selectedUser(deskList,sideInfo)
	local pro  = math.random(1000)
	local dbDeskInfo = nil
	for _, deskInfo in pairs(deskList) do
		for _, user in pairs(deskInfo.users) do
			local sql = string.format("select platform from d_user where uid = %d",user.uid)
			local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
			if #rs == 1 and rs[1].platform == 1 and user.hadBet == 1 then
				dbDeskInfo = deskInfo
				break
			end
		end
	end
	if dbDeskInfo then
		for _,user in pairs(dbDeskInfo.users) do
			local sql = string.format("select platform from d_user where uid = %d",user.uid)
			local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
			if #rs == 1 and rs[1].platform == 1 then
				local dian1 = sideInfo[1]
				local dian2 = sideInfo[2]
				if user.bet[dian1] > 0 or user.bet[dian2] > 0 then
					return true
				end
				local sindouPlace
				local num1,num2=math.modf((sideInfo[1] + sideInfo[2])/2)
				if num2 == 0 then
					if sideInfo[1] ~= sideInfo[2] then
						sindouPlace = 9
					elseif sideInfo[1] == sideInfo[2] then
						sindouPlace = 8
					end
				else
					sindouPlace = 7
				end
				if user.bet[sindouPlace] > 0 then
					return true
				end
			end
		end
		return false
	else
		return true
	end
	return true
end

function contrlSelectedUser(deskList,sideInfo)
	local pro  = math.random(1000)
	local dbDeskInfo = nil
	for _, deskInfo in pairs(deskList) do
		for _, user in pairs(deskInfo.users) do
			local sql = string.format("select platform from d_user where uid = %d",user.uid)
			local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
			if #rs == 1 and rs[1].platform == 1 and user.hadBet == 1 then
				if user.bet[1]+user.bet[2]+user.bet[3]+user.bet[4]+user.bet[5]+user.bet[6] > 0 then
					dbDeskInfo = deskInfo
					break
				end
			end
		end
	end
	if dbDeskInfo then
		for _,user in pairs(dbDeskInfo.users) do
			local sql = string.format("select platform from d_user where uid = %d",user.uid)
			local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
			if #rs == 1 and rs[1].platform == 1 then
				local dian1 = sideInfo[1]
				local dian2 = sideInfo[2]
				if user.bet[dian1] > 0 or user.bet[dian2] > 0 then
					return true
				end
			end
		end
		return false
	else
		return true
	end
	return true
end

function getSpCarIdx(cntScatterNum,inInIdxs,ps,isContinuous)
	local scatterIdx = {0,0,0,0,0}
	local idxs = {}
	if inInIdxs then
		idxs = getAntBunCount(cntScatterNum,inInIdxs,ps)
	else
		idxs = getAntBunCount(cntScatterNum,{1,2,3,4,5},ps)
	end
	if isContinuous then
		if cntScatterNum == 3 then
			idxs = {1,2,3}
		end
		if cntScatterNum == 4 then
			idxs = {1,2,3,4}
		end
		if cntScatterNum == 5 then
			idxs = {1,2,3,4,5}
		end
	end

	if #idxs > 0 then
		for _, key in pairs(idxs) do
			scatterIdx[key] = 1
		end
	end
	return scatterIdx
	-- local scatterIdx = {0,0,0,0,0}
	-- if cntScatterNum == 1 then
	-- 	local index =  math.random(1,5)
	-- 	scatterIdx[index] = 1
	-- 	scatterIdx = scatterIdx
	-- 	return scatterIdx
	-- end

	-- if cntScatterNum == 2 then
	-- 	local scatterIdxs = {
	-- 	{1,1,0,0,0},{1,0,1,0,0},{1,0,0,1,0},{1,0,0,0,1},
	-- 	{0,1,1,0,0},{0,1,0,1,0},{0,1,0,0,1},
	-- 	{0,0,1,1,0},{0,0,1,0,1},
	-- 	{0,0,0,1,1}}
	-- 	local index = math.random(1,#scatterIdxs)
	-- 	return scatterIdxs[index]
	-- end

	-- if cntScatterNum == 3 then
	-- 	local scatterIdxs = {{1,1,1,0,0},{1,1,0,1,0},{1,1,0,0,1},{1,0,1,1,0},{1,0,1,0,1},{1,0,0,1,1},{0,1,1,1,0},{0,1,1,0,1},{0,1,0,1,1},{0,0,1,1,1}}
	-- 	local index = math.random(1,#scatterIdxs)
	-- 	return scatterIdxs[index]
	-- end
	-- if cntScatterNum == 4 then
	-- 	local scatterIdxs = {{0,1,1,1,1},{1,0,1,1,1},{1,1,0,1,1},{1,1,1,0,1},{1,1,1,1,0}}
	-- 	local index = math.random(1,#scatterIdxs)
	-- 	return scatterIdxs[index]
	-- end
	-- if cntScatterNum == 5 then
	-- 	return {1,1,1,1,1}
	-- end
	-- return scatterIdx
end

function doCardNiuniu(nnv)
	--1. 3张花牌
	--2. 2张花牌  2张数字等于10
	--3. 3张数字
	local type = math.random(1,3)
	local tmpCards = bulltool.RandCardList()
	local controlCards = {}
	local nv = nnv or math.random(9,10)
	print("----------nv---------",nv)
	if type == 1 then
		for i, card in pairs(tmpCards) do
			if (card & 0x0F) >= 10 then
				table.insert(controlCards,card)
				tmpCards[i] = nil
				if #controlCards == 3 then
					break
				end
			end
		end
		for _, card in pairs(tmpCards) do
			if (card & 0x0F) < 10 then
				if #controlCards == 3 then
					if nv ~= 10 then
						if (card & 0x0F) ~= nv then
							table.insert(controlCards,card)
						end
					else
						table.insert(controlCards,card)
					end
				elseif #controlCards == 4 then
					if nv ~= 10 then
						if math.floor(((card & 0x0F) + (controlCards[4] & 0x0F))%10) == nv then
							table.insert(controlCards,card)
							break
						end
					else
						if (card & 0x0F) + (controlCards[4] & 0x0F)%10 == nv then
							table.insert(controlCards,card)
							break
						end
					end
				end
			end
		end
		print("------------1111111111111---------",controlCards)
		return controlCards
	end
	if type == 2 then
		for i, card in pairs(tmpCards) do
			if (card & 0x0F) >= 10 then
				table.insert(controlCards,card)
				tmpCards[i] = nil
				if #controlCards == 2 then
					break
				end
			end
		end
		for _, card in pairs(tmpCards) do
			if #controlCards == 2 then
				if (card & 0x0F) < 10 then
					table.insert(controlCards,card)
				end
			elseif #controlCards == 3 then
				if (card & 0x0F) < 10 then
					if ((card & 0x0F) + (controlCards[3] & 0x0F) )%10 == 0 then
						table.insert(controlCards,card)
					end
				end
			elseif #controlCards == 4 then
				if nv == 10 then
					if (card & 0x0F) >= 10 then
						table.insert(controlCards,card)
						break
					end
				else
					if (card & 0x0F) == nv then
						table.insert(controlCards,card)
						break
					end
				end
			end
		end
		print("------------22222222222---------",controlCards)
		return controlCards
	end
	if type == 3 then
		for i, card in pairs(tmpCards) do
			if #controlCards < 2 then
				if (card & 0x0F) < 10 then
					if #controlCards == 0 then
						table.insert(controlCards,card)
						tmpCards[i] = nil
					else
						if ((card & 0x0F) + (controlCards[1] & 0x0F))%10 ~= 0 then
							table.insert(controlCards,card)
							tmpCards[i] = nil
							break
						end
					end
				end
			end
		end
		for _, card in pairs(tmpCards) do
			if (card & 0x0F) < 10 then
				if #controlCards == 2 then
					if ((controlCards[1] & 0x0F) + (controlCards[2] & 0x0F) + (card & 0x0F))%10 == 0 then
						table.insert(controlCards,card)
					end
				elseif #controlCards == 3 then
					if nv ~= 10 then
						if (card & 0x0F) ~= nv then
							table.insert(controlCards,card)
						end
					else
						table.insert(controlCards,card)
					end
				elseif #controlCards == 4 then
					if nv ~= 10 then
						if math.floor(((card & 0x0F) + (controlCards[4] & 0x0F))%10) == nv then
							table.insert(controlCards,card)
							break
						end
					else
						if math.floor(((card & 0x0F) + (controlCards[4] & 0x0F))%10) == 0 then
							table.insert(controlCards,card)
							break
						end
					end
				end
			end
		end
		print("------------3333333333333---------",controlCards)
		return controlCards
	end
end

function  checkFourCardType(cards)
	local tcards = table.copy(cards)
	local card1 = (tcards[1] & 0x0F)
	if (tcards[1] & 0x0F) > 10 then
		card1 = 10
	end
	local card2 = (tcards[2] & 0x0F)
	if (tcards[2] & 0x0F) > 10 then
		card2 = 10
	end
	local card3 = (tcards[3] & 0x0F)
	if (tcards[3] & 0x0F) > 10 then
		card3 = 10
	end
	local card4 = (tcards[4] & 0x0F)
	if (tcards[4] & 0x0F) > 10 then
		card4 = 10
	end
	if (card1 + card2 + card3)%10 == 0 then
		return true
	end
	if (card1 + card2 + card4)%10 == 0 then
		return true
	end
	if (card1 + card3 + card4)%10 == 0 then
		return true
	end
	if (card2 + card3 + card4)%10 == 0 then
		return true
	end
end
function getCntScatterNum(min)
	local cntScatterNum = 0
	local pro = math.random(1000)
	if min == 2 then
		if pro > 0 and pro <= 600 then
			cntScatterNum = 0
		elseif pro > 600 and pro <= 950 then
			cntScatterNum = 1
		else
			cntScatterNum = 2
		end
	elseif min == 1 then
		if pro > 0 and pro <= 800 then
			cntScatterNum = 0
		else
			cntScatterNum = 1
		end
	end
	return cntScatterNum
end
function makeDeskBaseInfo(gameid,deskid)
    return {gameid = gameid,deskid = deskid}
end

--获取胡牌的成型
function getHuPaiCards(cards,pcard,isDelKanOrShe)
	local handHuCards = {}
	local duiValue = {}
	for _,data in pairs(cards) do --去掉跑了或者蛇 踢龙后 胡牌算法 凑的那个0
		if isDelKanOrShe then
			if #data == 3 and data[1] ==  pcard and data[1] == data[2] and data[3] == data[2] then
				print("-----去除砍------")
			elseif #data == 4 and data[1] ==  pcard and data[1] == data[2] and data[3] == data[2] then
				print("-----去除砍蛇----")
			else
				table.insert(handHuCards,data)
			end
		else
			table.insert(handHuCards,data)
		end
	end
	return handHuCards
end