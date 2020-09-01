replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (176, "极限比赛", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(176, "极限比赛");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 176, "极限比赛", 1, 100);
update s_game set title = 'motorcycle' where id = 176;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (188, "埃及艳后", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(188, "埃及艳后");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 188, "埃及艳后", 1, 100);
update s_game set title = 'cleopatraGold' where id = 188;

