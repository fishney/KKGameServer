local skynet = require "skynet"
require "skynet.manager"
local httpc = require "http.httpc"
local cjson = require "cjson"
local snax = require "snax"
local cluster = require "cluster"
local webclient
local CMD = {}
--[[
瑞力易宝支付渠道
]]

local Production_API = 'http://pay.apps.ruiliyule.com/yeepay/api.php'

function jsondecode(str)
    return cjson.decode(str)
end

--[[
去接口中支付
order["description"] = shop.title
order["amount"] = shop.amount
order["uid"] = uid
order["orderid"] = orderid
order["uid"] = uid
order["time"] = 1231312312
return 200, cjson.decode({"paymentId":"MPO622978","referenceId":"201809061554132185034392","paymentUrl":"https://sandbox-global.mol.com/PaymentWall/Checkout/index?token=qipDtsNLDSJbj7YTJQwGEfK2yVJkqQ%2f0pW0WIIO7Df1NB2eEQ0MCLalvkPphyNYrAE8qfwqvl1uL5JmloWWar7kB06EKOoKMxShuBWb6b0t6EQUcGWCKBOTuyUcjruAr3G%2b93LC9%2baARsjROPHgcjNdoSmldGO1lR7GAwWZvGQ2FPkYy1qvVk6LqhAmWU2xsMlVmWqv6nMc8BHDVCvhFtDqS1qKq%2fS5zVnGcZkW8C7tim1CLWj1ARwQ4B%2fkMvchm%2bz1JkqCLgXA%3d","amount":2,"currencyCode":"MYR","version":"v1","signature":"60e9c1727302742fff34aa27d0cabaab","applicationCode":"6fWm17olrZ9BJdHmg76D4w8ymUegP2b7"})
]]
function CMD.pay(order)
    assert(order.orderid, order.uid .. "支付缺少订单号")

    if nil == webclient then
        webclient = skynet.newservice("webreq")
    end

    local ok, body  = skynet.call(webclient, "lua", "request", Production_API,nil, order,false)
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
    print("resp:", resp)

    if resp.message ~= nil then
        assert(string.format("req paymol error %s , orderid: %s", resp.message,  order.orderid))
        return PDEFINE.RET.ERROR.PAY_FAILD, nil
    end

    return PDEFINE.RET.SUCCESS, resp
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)
    skynet.register(".yeepay")
end)