ALTER TABLE q_coins_log ADD game_identification int(11) DEFAULT '0' COMMENT '一轮evo游戏的唯一id';
ALTER TABLE q_coins_log ADD coin decimal(15,4) DEFAULT NULL COMMENT '金币数';
ALTER TABLE q_coins_log ADD gameid int(11) DEFAULT '0' COMMENT '游戏id';
ALTER TABLE q_coins_log ADD type int(11) DEFAULT '0' COMMENT 'type';
ALTER TABLE q_coins_log ADD uid bigint(20) DEFAULT '0' COMMENT '玩家id';

ALTER TABLE q_pool_log ADD game_identification int(11) DEFAULT '0' COMMENT '一轮evo游戏的唯一id';
ALTER TABLE q_pool_log ADD coin decimal(15,4) DEFAULT NULL COMMENT '金币数';
ALTER TABLE q_pool_log ADD gameid int(11) DEFAULT '0' COMMENT '游戏id';
ALTER TABLE q_pool_log ADD type int(11) DEFAULT '0' COMMENT 'type';
ALTER TABLE q_pool_log ADD uid bigint(20) DEFAULT '0' COMMENT '玩家id';

ALTER TABLE q_gplay_log ADD game_identification int(11) DEFAULT '0' COMMENT '一轮evo游戏的唯一id';
ALTER TABLE q_gplay_log ADD coin decimal(15,4) DEFAULT NULL COMMENT '金币数';
ALTER TABLE q_gplay_log ADD gameid int(11) DEFAULT '0' COMMENT '游戏id';
ALTER TABLE q_gplay_log ADD type int(11) DEFAULT '0' COMMENT 'type';
ALTER TABLE q_gplay_log ADD uid bigint(20) DEFAULT '0' COMMENT '玩家id';

ALTER TABLE q_poolevent_log ADD game_identification int(11) DEFAULT '0' COMMENT '一轮evo游戏的唯一id';
ALTER TABLE q_poolevent_log ADD coin decimal(15,4) DEFAULT NULL COMMENT '金币数';
ALTER TABLE q_poolevent_log ADD gameid int(11) DEFAULT '0' COMMENT '游戏id';
ALTER TABLE q_poolevent_log ADD type int(11) DEFAULT '0' COMMENT 'type';
ALTER TABLE q_poolevent_log ADD uid bigint(20) DEFAULT '0' COMMENT '玩家id';