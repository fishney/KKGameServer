CREATE TABLE `poolround_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uniqueid` bigint(20) DEFAULT NULL COMMENT '游戏场景唯一id',
  `gameid` int(11) DEFAULT '0' COMMENT '游戏id',
  `subgameid` int(11) DEFAULT '0' COMMENT '子游戏id',
  `game_timestamp` int(11) DEFAULT '0' COMMENT '游戏创建时间',
  `status` tinyint(1) DEFAULT '1' COMMENT '数据状态',
  `uid` bigint(20) DEFAULT NULL,
  `pooltype` tinyint(1) DEFAULT '1' COMMENT '奖池来源类型',
  `updatetime` int(11) DEFAULT '0' COMMENT '数据修改时间',
  `time` int(11) DEFAULT '0' COMMENT '数据创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_gameid` (`gameid`),
  KEY `idx_subgameid` (`subgameid`),
  KEY `idx_status` (`status`),
  KEY `idx_updatetime` (`updatetime`),
  KEY `idx_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='借款或扣库存状态日志';
CREATE TABLE `q_poolevent_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `data` text NOT NULL COMMENT '上报数据',
  `time` int(11) DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='彩池事件上报队列日志';
