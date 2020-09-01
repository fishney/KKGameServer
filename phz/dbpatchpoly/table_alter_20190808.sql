
replace into `s_sess`(`gameid`, `title`, `basecoin`, `mincoin`, `leftcoin`, `hot`, `status`, `ord`, `free`, `level`, `param1`, `param2`, `param3`, `param4`, `revenue`, `seat`, `chips`) 
VALUES (245, 'invincible_online', 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 100, '[{"min":2,"max":1000},{"min":0.2,"max":500},{"min":2,"max":100},{"min":5,"max":1000}]');

replace into `s_game` (id, title, storaterate, gametag) values(245, "invincible_online", 98, 3);
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (4, 245, "invincible_online", 1, 37);

update s_game set control = '[{"roundBossProbability":20000,"winBossRate":8000,"wudiRate":1,"bossProbability":{"boss_1":{"s":0,"e":500},"boss_2":{"s":500,"e":3000},"boss_3":{"s":3000,"e":7000},"boss_4":{"s":7000,"e":10000}}},{"roundBossProbability":20000,"winBossRate":8000,"wudiRate":1,"bossProbability":{"boss_1":{"s":0,"e":500},"boss_2":{"s":500,"e":3000},"boss_3":{"s":3000,"e":7000},"boss_4":{"s":7000,"e":10000}}},{"roundBossProbability":20000,"winBossRate":8000,"wudiRate":1,"bossProbability":{"boss_1":{"s":0,"e":500},"boss_2":{"s":500,"e":3000},"boss_3":{"s":3000,"e":7000},"boss_4":{"s":7000,"e":10000}}},{"roundBossProbability":20000,"winBossRate":8000,"wudiRate":1,"bossProbability":{"boss_1":{"s":0,"e":500},"boss_2":{"s":500,"e":3000},"boss_3":{"s":3000,"e":7000},"boss_4":{"s":7000,"e":10000}}},{"roundBossProbability":20000,"winBossRate":8000,"wudiRate":1,"bossProbability":{"boss_1":{"s":0,"e":500},"boss_2":{"s":500,"e":3000},"boss_3":{"s":3000,"e":7000},"boss_4":{"s":7000,"e":10000}}}]' where id = 245;      

update s_game set aicontrol = '[{"starttime":0,"endtime":24,"num":{"min":20,"max":100},"coin":{"min":100000,"max":500000},"betrate":70,"betcoin":{"max":2000},"betplace":{"min":1,"max":4},"betplace_c":[{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":4,"chiprate":[1000,2000,2000,2000,1000,1000]},{"rate":20,"chiprate":[1000,2000,2000,2000,1000,1000]}]}]' where id = 245;


replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (179, "学妹", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(179, "学妹");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 179, "学妹", 1, 100);
update s_game set title = 'kimochi' where id = 179;


	
