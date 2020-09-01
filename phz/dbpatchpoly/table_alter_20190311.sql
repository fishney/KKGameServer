
replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (143, "爱尔兰的运气", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(143, "爱尔兰的运气");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 143, "爱尔兰的运气", 1, 100);
update s_game set title = 'aierlandeyunqi' where id = 143;

replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (157, "可乐瓶", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(157, "可乐瓶");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 157, "可乐瓶", 1, 100);
update s_game set title = 'keleping' where id = 157;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (158, "海盗船", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(158, "海盗船");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 158, "海盗船", 1, 100);
update s_game set title = 'haidaochuan' where id = 158;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (164, "狂野非洲", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(164, "狂野非洲");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 164, "狂野非洲", 1, 100);
update s_game set title = 'kuangyefeizhou' where id = 164;


