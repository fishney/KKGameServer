replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (184, "马戏团", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(184, "马戏团");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 184, "马戏团", 1, 100);
update s_game set title = 'circus' where id = 184;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (185, "东方快车", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(185, "东方快车");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 185, "东方快车", 1, 100);
update s_game set title = 'orientExpress' where id = 185;

