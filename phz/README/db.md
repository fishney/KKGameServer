##数据库模块介绍

1.  数据存在三层：游戏内（mem），redis，mysql
2.  玩家登录会尝试从 redis 加载数据到 mem，redis 没有则穿透到 mysql 加载，并缓存到 redis
3.  玩家登出会释放 mem，redis 和 mysql 数据不释放
4.  玩家离线期间有数据修改需求，直接修改 mysql，并且在 redis 打一个标记，如果登录加载的时候检测到标记，则强制从 mysql 加载数据
5.  修改数据会立即操作 redis 和 mem，异步同步到 mysql
6.  查询数据遵循 mem > redis > mysql

##数据表的管理配置

1.  目前支持 config user common 三类表，项目中config不使用（通过lua配置）
2.  CommonEntity 配置规则
    -   name 表名，reids_key 是 name:key，indexkey 索引所有相关 redis_key
3.  UserEntity 用户表根据结构关系分三种
    -   配置信息 name 和 key 组成 reids_key，indexkey 索引所有相关 redis_key
    -   UserSingleEntity uid - data 单对单数据
        +   name 表名
        +   key 配置为 uid
    -   UserMultiEntity uid - id - data 单对多id数据，id是全服公用自增
        +   name 表名
        +   key 配置为 mysql 主键
        +   indexkey 配置固定为 uid
        +   autoincrease = "1"
    -   UserIndexEntity uid - baseid - data 单对多baseid数据
        +   name 表名
        +   baseid 必须有作为二级索引
        +   key 配置为 uid,baseid
        +   indexkey 配置固定为 uid
