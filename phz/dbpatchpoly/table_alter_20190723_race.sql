delete from s_game where id = 211;
delete from s_game_type where gameid = 211;
delete from s_sess where gameid = 211;

replace into `s_game` (id, title, storaterate, control, `type`) values(243, "saima", 98, '[{"factor":1.2},{"factor":0.8},{"factor":0.7},{"factor":0.4},{"factor":0.2}]', 4);
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (4, 243, "赛马918", 1, 45);
replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (243, "赛马918", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);