ALTER TABLE `s_game` ADD COLUMN `collector` int(11) NULL DEFAULT 0 COMMENT '收藏人数' AFTER `gametag`;

CREATE TABLE `s_game_collector`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NULL COMMENT '玩家uid',
  `gameid` int(11) NULL COMMENT '游戏id',
  `action` tinyint(1) NULL COMMENT '1收藏2取消',
  `create_time` int(11) NULL COMMENT '操作时间',
  PRIMARY KEY (`id`),
  INDEX `index_uid`(`uid`, `gameid`),
  INDEX `index_time`(`create_time`)
);