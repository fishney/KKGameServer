##登录过程数据格式
二进制序列化 : 2字节数据长度(大端编码) + 数据

###登录服帐号认证流程

1. C2S : 客户端连接登录服(登录服地址固定)
2. S2C : base64(8bytes random challenge)随机串，用于后序的握手验证。
3. C : 生成 8bytes 随机串 client key
4. C2S : base64(DH-Exchange(client key)) 用于生成 secret 的 key
5. S: 生成 8bytes 随机串 server key
6. S2C : base64(DH-Exchange(server key)) 用于生成 secret 的 key
7. S/C secret := DH-Secret(client key/server key)服务器和客户端都可以计算出同一个 8 字节的 secret 用来加密数据
8. C2S : base64(HMAC(challenge, secret))回应服务器第一步握手的挑战码，确认握手正常
9. C2S : DES(secret, base64(token))使用 DES 算法，以 secret 做 key 加密传输 token，token 包含帐号信息[user，sdkid]
10. S2C : 认证结果信息，前2个字节retcode 200 表示成功，只有成功才解析后续内容(base64(uid:subid)@base64(server)#base64(info))
    -   uid : 玩家id
    -   subid : 此次登录唯一id
    -   server : 分配node服名字
    -   info : node服务网络地址信息(ip:port)

###登录node流程

1. C2S : 客户端连接node(上面认证第10步解析到的ip:port)
2. C : handshake = (base64(uid)@base64(server)#base64(subid):index)
    -   uid : 玩家id
    -   server : 认证第10步获得的node服名字
    -   subid : 认证第10步获得的登录唯一id
    -   index : 重连索引，第一次连接是1，如果断线重连node，需要自增index
3. C : hmac = base64(HMAC(HASHKEY(handshake), secret)) 用 secret 加密数据
4. C2S : handshake:hmac
5. S2C : 登录握手结果信息，数据前2个字节retcode 200 表示握手成功，可以开始后续通信


##协议数据格式
C2S : 2字节数据长度 + 数据 [消息数据 + 4字节session + hmac]
S2C : 2字节数据长度 + 数据 [消息数据 + 4字节session + hmac]
hmac = base64(HMAC(HASHKEY(数据除了hmac部分), secret)) 用 secret 加密数据，必有
session : 索引关联对应请求回复，必有但可能为0
消息数据 : protobuf 结构，详细定义 proto/message.proto

客户端验证登录交互流程可参考 test/client.lua

##注意点
1. protobuf设定了数据类型对应的默认值，当保存的值是默认值的时候，不会被打包，接收方会解析不到。int32字段不能赋值0，因此非法值一律用'-1'表示，枚举定义从'1'开始
2. 跨服务调用，如果有传递proto消息数据对象，需要先assert声明内含字段
