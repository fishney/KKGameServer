ALTER TABLE s_sess ADD chips text COMMENT '游戏的筹码范围json数据';
update s_sess set chips = '[{"min":2,"max":1000},{"min":0.2,"max":500},{"min":2,"max":100},{"min":5,"max":1000}]' where gameid in (select gameid from s_game_type where gametype=4);
CREATE TABLE `d_gamesetting` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) DEFAULT NULL COMMENT '玩家id',
  `gameid` int(11) DEFAULT '0' COMMENT '游戏id',
  `state` tinyint(11) DEFAULT '0' COMMENT '0开放 1关闭',
  `chips` text COMMENT '可以用的筹码范围',
  `updatetime` int(11) DEFAULT '0' COMMENT '数据修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_gameid` (`gameid`),
  KEY `idx_uid` (`uid`),
  KEY `idx_updatetime` (`updatetime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='针对玩家的游戏设置';    