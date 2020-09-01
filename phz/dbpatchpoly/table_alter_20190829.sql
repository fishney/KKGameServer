replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (194, "时尚世界", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(194, "时尚世界");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 194, "时尚世界", 1, 100);
update s_game set title = 'glamourousworld' where id = 194;

replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (195, "名利场", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(195, "名利场");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 195, "名利场", 1, 100);
update s_game set title = 'famefortune' where id = 195;