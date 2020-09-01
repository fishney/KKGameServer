CREATE TABLE `coin_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '用户id',
  `type` tinyint(2) NOT NULL COMMENT '修改方式',
  `game_id` int(11) NOT NULL COMMENT '游戏id',
  `before_coin` decimal(15,4) DEFAULT NULL COMMENT '修改之前的金币数',
  `coin` decimal(15,4) DEFAULT NULL COMMENT '金币数',
  `after_coin` decimal(15,4) DEFAULT NULL COMMENT '修改之后的金币数',
  `log` varchar(128) NOT NULL,
  `state` tinyint(1) DEFAULT '1' COMMENT '数据状态 0创建1本地已加2已经通知api',
  `updatetime` int(11) DEFAULT '0' COMMENT '修改时间',
  `time` int(11) DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_uid` (`uid`),
  KEY `idx_type` (`type`),
  KEY `idx_game_id` (`game_id`),
  KEY `idx_state` (`state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='金币修改明细表';