
replace into `s_sess`(`gameid`, `title`, `basecoin`, `mincoin`, `leftcoin`, `hot`, `status`, `ord`, `free`, `level`, `param1`, `param2`, `param3`, `param4`, `revenue`, `seat`) 
VALUES (238, '五龙', 1, 0.01, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 35, 1);


REPLACE INTO `s_game_type`(`gametype`, `gameid`, `title`, `state`, `hot`) VALUES(2, 238, '五龙', 1, 250);


replace into `s_game` VALUES(238,'wulong',1,1537170339,100,0.00,0.00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"",0,0,0,4,"1.0.0.0",NULL);
