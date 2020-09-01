ALTER TABLE q_coins_log ADD state tinyint(1) DEFAULT '0' COMMENT '数据状态 0未发送 1已发送';
ALTER TABLE q_coins_log ADD result text NOT NULL COMMENT '数据发送结果日志';
ALTER TABLE q_coins_log ADD updatetime int(11) DEFAULT '0' COMMENT '数据修改时间';

ALTER TABLE q_pool_log ADD state tinyint(1) DEFAULT '0' COMMENT '数据状态 0未发送 1已发送';
ALTER TABLE q_pool_log ADD result text NOT NULL COMMENT '数据发送结果日志';
ALTER TABLE q_pool_log ADD updatetime int(11) DEFAULT '0' COMMENT '数据修改时间';

ALTER TABLE q_gplay_log ADD state tinyint(1) DEFAULT '0' COMMENT '数据状态 0未发送 1已发送';
ALTER TABLE q_gplay_log ADD result text NOT NULL COMMENT '数据发送结果日志';
ALTER TABLE q_gplay_log ADD updatetime int(11) DEFAULT '0' COMMENT '数据修改时间';

ALTER TABLE q_poolevent_log ADD state tinyint(1) DEFAULT '0' COMMENT '数据状态 0未发送 1已发送';
ALTER TABLE q_poolevent_log ADD result text NOT NULL COMMENT '数据发送结果日志';
ALTER TABLE q_poolevent_log ADD updatetime int(11) DEFAULT '0' COMMENT '数据修改时间';