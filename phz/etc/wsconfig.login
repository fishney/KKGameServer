skynetroot = "./skynet/"
thread = 8
logger = nil
logpath = "."
start = "wsmain"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap
app = 4
-- 集群配置
cluster = "./etc/clustername.lua"
harbor = 0

isbigbang=1
log_dirname = "log"
log_basename = "login"
loginname = "login"

loginservice = "./login/?.lua;" ..
		"./lualib/?.lua;" ..
			   "./common/?.lua;" ..
			   "./common/cluster/?.lua;" ..
			   "./common/datacenter/?.lua"

-- LUA服务所在位置
luaservice = skynetroot .. "service/?.lua;" .. loginservice
snax = loginservice

-- 用于加载LUA服务的LUA代码
lualoader = skynetroot .. "lualib/loader.lua"
preload = "./global/preload.lua"	-- run preload.lua before every lua service run

-- C编写的服务模块路径
cpath = skynetroot .. "cservice/?.so"

-- 将添加到 package.cpath 中的路径，供 require 调用。
lua_cpath = skynetroot .. "luaclib/?.so;" .. "./luaclib/?.so"

lua_path = skynetroot .. "lualib/?.lua;" ..  skynetroot .. "lualib/compat10/?.lua;" ..
		   "./lualib/?.lua;" ..
		   "./global/?.lua;" ..
		    "./common/?.lua;"..
		   "./common/entitybase/?.lua;" ..
		   "./common/config/?.lua.txt;" ..
		   "./common/config/CfgInfo/?.lua.txt;" ..
		   "./common/entity/?.lua;"

-- 后台模式
--daemon = "./login.pid"

port = 9180					-- 监听端口
-- 游戏数据库
mysql_maxconn = 2		-- mysql数据库最大连接数
mysql_host = "127.0.0.1"	-- mysql数据库主机
mysql_port = 3306		-- mysql数据库端口
mysql_db = "game"             -- mysql数据库库名
mysql_user = "root"             -- mysql数据库帐号
mysql_pwd = "Admin123@"            -- mysql数据库密码




redis_maxinst = 1		-- redis最大实例数
redis_db1 = 15
redis_host1 = "127.0.0.1"	-- redis数据库IP
redis_port1 = 6379		-- redis数据库端口
redis_auth1 = "xingC99"		-- redis数据库密码

nodename = "login"
