
replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (175, "猎狼者", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(175, "猎狼者");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 175, "猎狼者", 1, 100);
update s_game set title = 'wolfhunters' where id = 175;



replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (176, "极限比赛", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(176, "极限比赛");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 176, "极限比赛", 1, 100);
update s_game set title = 'nitro' where id = 176;



replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (177, "艳星野妹", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(177, "艳星野妹");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 177, "艳星野妹", 1, 100);
update s_game set title = 'wildFox' where id = 177;