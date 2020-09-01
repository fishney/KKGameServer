--[[
    websocket:
        protocal   head||body
--]]
local skynet = require "skynet"
local socket = require "socket"
local string = require "string"
local websocket = require "websocket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"

local port = ...
port = tonumber(port)
local handler = {}
local ws_list = {}

function handler.on_open(ws)
    LOG_DEBUG(string.format("[WEBSERVICE] WS[%d] addr[%s] open", ws.id, ws.ip))
    ws_list[ws.id] = ws
end

function handler.on_message(ws, message)
    LOG_DEBUG("on_message:",message)
    -- LOG_DEBUG(string.format("[WEBSERVICE] WS[%d] receive: msg[%s]", ws.id, message))

    local socket_error = {}
    local ok, err = skynet.call(".login_master", "lua", "login", ws.id, ws.ip, message)
    if not ok then
        if err ~= socket_error then
            LOG_DEBUG(string.format("invalid client (fd = %d) error = %s", ws.id, err))
        end
    end
    socket.abandon(ws.id)
end

function handler.on_close(ws, code, reason)
    LOG_DEBUG(string.format("%d close:%s  %s", ws.id, code, reason))
    ws_list[ws.id] = nil
end

local function handle_socket(id, addr)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), nil)
    if code then
        if url == "/ws" then
            local ws = websocket.new(id, addr, header, handler)
            ws:start()
        end
    end
end
---------------------------------------------
-- service Commond
-- function
--      send  ws send msg to client
---------------------------------------------
local CMD = {}
function CMD.send( id, code )
    local ws = ws_list[id]
    if ws then
        ws:send_binary(code)
    end
end

function CMD.ServiceClose( ... )
    for id, ws in pairs( ws_list ) do
        socket.close( id )
    end
    skynet.timeout(5*100, function( ... )
        skynet.exit()
    end)
end

skynet.start(function()
    -- 监听本地端口
    local address = "0.0.0.0:" .. port
    skynet.error(os.date("%Y-%m-%d %H:%M:%S", os.time()), "Login websocket listening "..address)
    local id = assert(socket.listen(address))

    socket.start(id , function(id, addr)
        socket.start(id)
        pcall(handle_socket, id, addr)
    end)

    skynet.dispatch( "lua", function( _,_, common, ... )
        local f = CMD[ common ]
        if f then
            f( ... )
        end
    end)
end)