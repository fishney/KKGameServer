##此skynet在开源的基础上增加了伪清除定时器的代码

- 编辑skynet/lualib/skynet.lua, 找到skynet.timeout接口 (修改timeout接口，同时增加remove_timeout接口)

```
local function remove_timeout_cb(...)

end

function skynet.remove_timeout(session)

 	local co = co_create(remove_timeout_cb)

 	assert(session_id_coroutine[session] ~= nil)

 	session_id_coroutine[session] = co

end

function skynet.timeout(ti, func)

 	local session = c.intcommand("TIMEOUT",ti)

 	assert(session)

 	local co = co_create(func)

 	assert(session_id_coroutine[session] == nil)

 	session_id_coroutine[session] = co

 	return session

end
```

##启动项目 start.sh

检查将启动的服务配置 `*/*.cfg`
执行 `./start.sh`

###脚本内容
- 检查 `../tmp` 目录中的关闭进程脚本并执行
- 生成 `../log` 日志目录
- 生成 `../tmp` 停服脚本目录
- 启动服务进程
- 生成服务对应的日志
- 根据对应的进程id生成相应的停服脚本，此处停服是直接kill
