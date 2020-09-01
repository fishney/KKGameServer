local skynet = require "skynet"
require "skynet.manager"
local httpc = require "http.httpc"
local cjson = require "cjson"
local snax = require "snax"
local cluster = require "cluster"
local CMD = {}
local webclient
--[[
Verify user accesstoken from facebook.
Get the result if accesstoken is ok.
e.g:
{
    "data": {
        "app_id": "234936877086514",
        "type": "USER",
        "application": "Megoo",
        "expires_at": 1531621396,
        "is_valid": true,
        "issued_at": 1526437396,
        "metadata": {
            "auth_type": "rerequest"
        },
        "scopes": [
            "public_profile"
        ],
        "user_id": "138130137045325"
    }
}
]]
function CMD.verify(userid, accesstoken)
    assert(accesstoken)
    if #userid == 0 or #accesstoken==0 then
        assert("facebook accesstoken auth failed because the userid or accesstoken length equre zero!")
    end

    local appid = ""
    local apptoken = ""

    --获取微信配置信息
    local sql = string.format("select * from s_config_third where type='facebook' limit 1")
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs == 1 then
        appid = rs[1].appid
        apptoken = rs[1].appsecret
    end

    if #appid == 0 then
        assert("not set facebook config information")
    end

    if nil == webclient then
        webclient = skynet.newservice("webreq")
    end

    --获取微信配置信息
    local ok, body = skynet.call(webclient, "lua", "request", "https://graph.facebook.com/debug_token",{access_token=appid .. "%7C"..apptoken, input_token=accesstoken}, nil,false)
    if not ok then
        assert("Verify token from facebook error!")
    end
    local resp = cjson.decode(body)
    print("resp:", resp)

    if resp.data == nil then
        assert(string.format("verify token error %s:%s", userid, accesstoken))
    end

    local uid = resp.data.user_id
    if tonumber(uid) == tonumber(userid) then
        return PDEFINE.RET.SUCCESS, true
    end

    return PDEFINE.RET.ERROR.FACEBOOK_AUTH_FAILD, false
end

--[[
{
	["id"] = "138130137045325",
	["name"] = "云浮",
	["picture"] = {
		["data"] = {
			["height"] = 50.0,
			["url"] = "https://lookaside.facebook.com/platform/profilepic/?asid=138130137045325&height=50&width=50&ext=1527335730&hash=AeTaICUaWi18R-hx",
			["width"] = 50.0,
			["is_silhouette"] = true,
		},
	},
}

--头像地址:  https://graph.facebook.com/138130137045325/picture
]]
--get user data from facebook
function CMD.userinfo(accesstoken)
    print("accesstoken:",accesstoken)
    assert(accesstoken)
    if #accesstoken == 0 then
        assert("facebook login failed because the accesstoken length equre zero!")
    end

    --获取user信息
    if nil == webclient then
        webclient = skynet.newservice("webreq")
    end
    local ok, body = skynet.call(webclient, "lua", "request", "https://graph.facebook.com/me",{fields="id,name,gender", access_token=accesstoken}, nil,false)

    if not ok then
        assert("Get userinfo from facebook error!")
    end
    print("body:",body)
    local resp = cjson.decode(body)
    print("resp:",resp)

    if resp.id ~= nil then
        assert("get userdata from facebook error")
    end

    local uid = resp.id
    if tonumber(uid) == tonumber(resp.id) then
        local sex = 1
        if resp.gender ~= nil and resp.gender=="female" then
            sex = 0
        end
        local userinfo = { id = resp.id, name = resp.name, pic = string.format("https://graph.facebook.com/%s/picture?type=normal", "" .. resp.id ), sex= sex}
        return PDEFINE.RET.SUCCESS, userinfo
    end
    return PDEFINE.RET.FACEBOOK_AUTH_FAILD, nil
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)
    skynet.register(".facebook")
end)