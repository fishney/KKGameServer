DROP TABLE IF EXISTS `s_growup`;

DROP TABLE IF EXISTS `d_user_growup`;
CREATE TABLE `d_user_growup` (
  `uid` bigint(20) NOT NULL COMMENT '用户id',
  `star` int(11) DEFAULT '0' COMMENT '当前星星数',
  `process` int(11) DEFAULT '0' COMMENT '当前星星升级的进度值',
  `gift` mediumtext COMMENT '奖励数据',
  `updatetime` int(11) DEFAULT NULL COMMENT '本条数据被修改的时间戳',
  `starttime` int(11) DEFAULT NULL COMMENT '本轮开始的时间戳',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='成长值玩家数据';