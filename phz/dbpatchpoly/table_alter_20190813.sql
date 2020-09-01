replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (186, "神秘之龙", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(186, "神秘之龙");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 186, "神秘之龙", 1, 100);
update s_game set title = 'mysticDragon' where id = 186;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (187, "野狼现金", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(187, "野狼现金");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 187, "野狼现金", 1, 100);
update s_game set title = 'wolfCash' where id = 187;

