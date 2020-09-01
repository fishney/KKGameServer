local skynet = require "skynet"
require "skynet.manager"
local httpc = require "http.httpc"
local cjson = require "cjson"
local snax = require "snax"
local cluster = require "cluster"
local md5 = require "md5"
local webclient
local CMD = {}
--[[
拉米paymol支付渠道
]]

local Sandbox_API    = 'https://sandbox-api.mol.com/'
local Production_API = 'https://api.mol.com/'

local prod = false --默认测试环境

local secretkey = "6CtJy7LIOw9Tg2ZJG76V4b8dJrBDmz07"
local applicationCode = "3f2504e04f8911d39a0c0305e82c3301"

local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local function urlDecode(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end


function jsondecode(str)
    return cjson.decode(str)
end

--[[
order = {
    "description" = "产品描述",
    "amount" =  "金额",
    "currencyCode" = "币种, USD or MYR, 详情见文档",
    "uid" = "用户id",
    "returnUrl" = "回跳地址",
    "orderid" = "订单id",
}

return 200, cjson.decode({"paymentId":"MPO622978","referenceId":"201809061554132185034392","paymentUrl":"https://sandbox-global.mol.com/PaymentWall/Checkout/index?token=qipDtsNLDSJbj7YTJQwGEfK2yVJkqQ%2f0pW0WIIO7Df1NB2eEQ0MCLalvkPphyNYrAE8qfwqvl1uL5JmloWWar7kB06EKOoKMxShuBWb6b0t6EQUcGWCKBOTuyUcjruAr3G%2b93LC9%2baARsjROPHgcjNdoSmldGO1lR7GAwWZvGQ2FPkYy1qvVk6LqhAmWU2xsMlVmWqv6nMc8BHDVCvhFtDqS1qKq%2fS5zVnGcZkW8C7tim1CLWj1ARwQ4B%2fkMvchm%2bz1JkqCLgXA%3d","amount":2,"currencyCode":"MYR","version":"v1","signature":"60e9c1727302742fff34aa27d0cabaab","applicationCode":"6fWm17olrZ9BJdHmg76D4w8ymUegP2b7"})
]]
function CMD.pay(order)
    assert(order.orderid, order.uid .. "支付缺少订单号")

    --获取微信配置信息
    local sql = string.format("select * from s_config_third where type='paymol' limit 1")
    local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
    if #rs == 1 then
        if 'prod' == rs[1].appid then
            prod = true
        end
        applicationCode = rs[1].appsecret
        secretkey = rs[1].signkey
    end

    local amount = math.floor(order.amount * 100) --转换为分
    --组装数据
    local params = {}
    params["amount"] = amount
    params["applicationCode"] = applicationCode
    params["currencyCode"] = order.currencyCode or "MYR"
    params["customerId"] = order.uid
    params["description"] = order.description
    params["referenceId"] = order.orderid
    params["returnUrl"] = order.returnUrl
    params["version"] = "v1"

    local signature = CMD.signature(params)
    params["signature"] = signature

    --请求
    local api = Sandbox_API .. 'payout/payments'
    if prod then
        api = Production_API .. 'payout/payments'
    end
    if nil == webclient then
        webclient = skynet.newservice("webreq")
    end

    local ok, body  = skynet.call(webclient, "lua", "request", api,nil, params,false)
    print("--------->body:", body)
    if not ok then
        assert("paymol 支付请求失败!" .. order.orderid)
        return PDEFINE.RET.ERROR.PAY_FAILD, nil
    end

    local ok, resp = pcall(jsondecode, body)
    if not ok then
        assert("paymol 支付失败，请求未成功!")
        return PDEFINE.RET.ERROR.PAY_FAILD, nil
    end
    LOG_INFO("resp:", resp)

    if resp.message ~= nil then
        assert(string.format("req paymol error %s , orderid: %s", resp.message,  order.orderid))
        return PDEFINE.RET.ERROR.PAY_FAILD, nil
    end

    return PDEFINE.RET.SUCCESS, resp
end

--检查回调签名
function CMD.checkSign(order)
    local sign = order.signature
    order.signature = nil
    local tb2 = {}
    for k,v in pairs(order) do
        if v ~= "" then
            tb2[k] = v
        end
    end


    local signature = CMD.signature(tb2)
    if sign == signature then
        return true
    end
    return false
end

--签名
function CMD.signature(dict)
    local sortd_table = {}
    for i in pairs(dict) do
        table.insert(sortd_table, i)
    end
    table.sort(sortd_table)

    local str = ""
    for i,v in pairs(sortd_table) do
        str = str .. dict[v]
    end
    str = str .. secretkey

    local signature = md5.sumhexa(str)
    return signature
end

function CMD.start()
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)
    skynet.register(".paymol")
end)