
local Date = {}

-- 根据给定时间戳，返回当天0点时间戳
function Date.GetTodayZeroTime(srcTime)
	local temp = os.date("*t", srcTime)
	return os.time{year=temp.year, month=temp.month, day=temp.day, hour=0,min=0,sec=0}
end

-- 根据给定时间戳，返回下周几时间戳
function Date.GetNextHourTime(srcTime, hour)
	assert(hour <= 24)
	assert(hour >= 1)
	local temp = os.date("*t", srcTime)
	local zero_time = os.time{year=temp.year, month=temp.month, day=temp.day, hour=temp.hour,min=0,sec=0}
	local add_hour = 0
	if temp.hour >= hour then
		add_hour = 24 - (temp.hour - hour)
	else
		add_hour = hour - temp.hour
	end
	return Date.GetNewTime(zero_time, add_hour, 'HOUR')
end

-- 根据给定时间戳，返回下周几时间戳
function Date.GetNextWeekDayTime(srcTime, weekday)
	assert(weekday <= 7)
	assert(weekday >= 1)
	local temp = os.date("*t", srcTime)
	-- 获取今天0点时间戳
	local zero_time = Date.GetTodayZeroTime(srcTime)
	-- 跨进天数
	local add_day = 0
	if temp.wday > weekday then
		add_day = 7 - (temp.wday - weekday)
	else
		add_day = weekday - temp.wday
	end
	-- os.date wday 1-7 代表周日-周六，需要加一天
	add_day = add_day + 1
	return Date.GetNewTime(zero_time, add_day, 'DAY')
end

-- 根据给定时间戳，设定偏移量和单位，返回结果时间戳
function Date.GetNewTime(srcTime,interval,dateUnit)
	-- 根据时间单位和偏移量得到具体的偏移数据
	local offset = 0
	if dateUnit =='DAY' then
		offset = 60 * 60 * 24 * interval
	elseif dateUnit == 'HOUR' then
		offset = 60 *60 * interval
	elseif dateUnit == 'MINUTE' then
		offset = 60 * interval
	elseif dateUnit == 'SECOND' then
		offset = interval
	end
	--指定的时间+时间偏移量
	return srcTime + tonumber(offset)
end

-- 两个时间戳相隔自然日
function Date.DiffDay(time1, time2)
	if time1 > time2 then
		time1, time2 = time2, time1
	end
	-- 归到零点
	local zero_time1 = Date.GetTodayZeroTime(time1)
	local zero_time2 = Date.GetTodayZeroTime(time2)
	return (zero_time2 - zero_time1) / 86400
end

return Date
