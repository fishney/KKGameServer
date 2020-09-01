CREATE TABLE `tmp_duizhan` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `game_identification` int(11) DEFAULT '0' COMMENT '一轮evo游戏的唯一id',
  `sumall` decimal(15,4) DEFAULT NULL COMMENT '金币数',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='临时对账表';