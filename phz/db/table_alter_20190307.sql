replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (125, "泰国神游", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(125, "泰国神游");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 125, "泰国神游", 1, 100);
update s_game set title = 'taiguoshentyou' where id = 125;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (126, "足球嘉年华", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(126, "足球嘉年华");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 126, "足球嘉年华", 1, 100);
update s_game set title = 'zuqiujianianhua' where id = 126;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (127, "斩五门", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(127, "斩五门");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 127, "斩五门", 1, 100);
update s_game set title = 'zhanwumen' where id = 127;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (128, "斯巴达", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(128, "斯巴达");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 128, "斯巴达", 1, 100);
update s_game set title = 'sibada' where id = 128;




