local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local cluster = require "cluster"
local cjson = require "cjson"
local md5 = require "md5"

local mode = ...

local respheader = {}
respheader["Content-Type"] = "text/html;Charset=utf-8"

if mode == "agent" then

    local function response(id, ...)
        local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
        if not ok then
            -- if err == sockethelper.socket_error , that means socket closed.
            skynet.error(string.format("fd = %d, %s", id, err))
        end
    end

    
    --重置配置表s_config
    local function processRequestSendSms(id, query)
        if nil == query.mod or query.mod ~= 'sms' then
            return 500, 'fail'
        end

        local ok, retok, result
        if query.act == 'sendCode' then
            local mobile = tostring(query.mobile)
            local sql = string.format("select * from d_account where user = '%s' and type = 3",mobile)
            local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
            if #rs == 1 then
                return PDEFINE.RET.ERROR.MOBILE_IS_REGIST --手机号已被注册
            end
            local code = tostring(randomCode(6))
            --获取user信息
            if nil == webclient then
                webclient = skynet.newservice("webreq")
            end
            print("=======mobile===>",mobile,"   code=======>",code)
            --[[local timestamp = os.date("%Y%m%d%H%M%S", os.time())
            local content = {}
            content.code = code
            local pwd = md5.sumhexa("123456yy".."youpan123")
            local ok, body = skynet.call(webclient, "lua", "request", "http://api.sms.cn/sms/",nil,{ac="send", uid="youpan123",pwd=pwd,mobile=mobile,template=100001,content=cjson.encode(content)}, nil,false)
            ]]
            -- print("-----ok----",ok)
            -- print("-----body----",body)
            local sql = string.format("insert into s_user_code(user,code)values('%s','%s')",mobile,code)
            skynet.call(".mysqlpool", "lua", "execute", sql)
            --TODO 接验证码平台
            return PDEFINE.RET.SUCCESS, 'succ'
        end
        if not ok then
            return 500, 'fail'
        end
        return PDEFINE.RET.SUCCESS, 'succ'
    end

    --重置配置表s_config
    local function processRequestSendSms1(id, query)
        print("--------query---------",query)
        if nil == query.mod or query.mod ~= 'sms' then
            return 500, 'fail'
        end

        local ok, retok, result
        if query.act == 'sendCode' then
            local mobile = tostring(query.mobile)
            local code = tostring(randomCode(6))
            --获取user信息
            if nil == webclient then
                webclient = skynet.newservice("webreq")
            end
            
            local timestamp = os.date("%Y%m%d%H%M%S", os.time())
            local content = string.format("【闲友】您的手机验证码:%d。若非本人操作,请忽略本短信。",code)
            local userid = 4679
            local user = 18525855928
            local pass = "xy101213"
            local sign = md5.sumhexa(user..pass..timestamp)
            local ok, body = skynet.call(webclient, "lua", "request", "http://39.104.28.149:8888/v2sms.aspx",nil,{action="send", userid=userid,timestamp=timestamp,sign=sign,mobile=mobile,content=content,sendTime="",extno=""}, nil,false)
            print("-----ok----",ok)
            print("-----body----",body)
            local sql = string.format("insert into s_user_code(user,code)values('%s','%s')",mobile,code)
            skynet.call(".mysqlpool", "lua", "execute", sql)
            --TODO 接验证码平台
            return PDEFINE.RET.SUCCESS, 'succ'
        end
        if not ok then
            return 500, 'fail'
        end
        return PDEFINE.RET.SUCCESS, 'succ'
    end

    --重置配置表s_config
    local function processRequestSendSms2(id, query)
        print("--------query---------",query)
        if nil == query.mod or query.mod ~= 'sms' then
            return 500, 'fail'
        end

        local ok, retok, result
        if query.act == 'sendCode' then
            local mobile = tostring(query.mobile)
            local code = tostring(randomCode(6))
            --获取user信息
            if nil == webclient then
                webclient = skynet.newservice("webreq")
            end
            
            local timestamp = os.date("%Y%m%d%H%M%S", os.time())
            local content = string.format("【闲友】您的手机验证码:%d。若非本人操作,请忽略本短信。",code)
            local userid = 11995
            local account = 18525855928
            local password = "18525855928"
            local ok, body = skynet.call(webclient, "lua", "request", "http://47.92.107.180:8081/sms.aspx",nil,{action="send", userid=userid,account=account,password = password,mobile=mobile,content=content,sendTime="",extno=""}, nil,false)
            print("-----ok----",ok)
            print("-----body----",body)
            local sql = string.format("insert into s_user_code(user,code)values('%s','%s')",mobile,code)
            skynet.call(".mysqlpool", "lua", "execute", sql)
            --TODO 接验证码平台
            return PDEFINE.RET.SUCCESS, 'succ'
        end
        if not ok then
            return 500, 'fail'
        end
        return PDEFINE.RET.SUCCESS, 'succ'
    end
    

    skynet.start(function()
        skynet.dispatch("lua", function (_, _, id)
            socket.start(id)
            -- limit request body size to 64k (you can pass nil to unlimit)
            local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 65536)
            if code then
                if code ~= 200 then
                    response(id, code)
                else
                    local code, resp

                    local path, query = urllib.parse(url)
                    if not query then
                        return
                    end
                    print("query is:", query)
                    if query then
                        local q = urllib.parse_query(query)
                        if q.mod == "sms" then
                            code, resp = processRequestSendSms2(id, q)
                        end
                    end
                    response(id, code, resp, respheader)
                end
            else
                if url == sockethelper.socket_error then
                    skynet.error("socket closed")
                else
                    skynet.error(url)
                end
            end
            socket.close(id)
        end)
    end)

else

    skynet.start(function()
        local agent = {}
        for i= 1, 20 do
            agent[i] = skynet.newservice(SERVICE_NAME, "agent")
        end
        local balance = 1
        local port = skynet.getenv("web_port")
        local id = socket.listen("0.0.0.0", port)
        skynet.error("Listen web port " .. port)
        socket.start(id , function(id, addr)
            skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
            skynet.send(agent[balance], "lua", id)
            balance = balance + 1
            if balance > #agent then
                balance = 1
            end
        end)
    end)

end