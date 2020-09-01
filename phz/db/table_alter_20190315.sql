update s_game set title='xiyouzhengba_online' where id=222;
update s_game set title='zhuanpan_high' where id=220;
update s_game set title='zhuanpan_mid' where id=219;
replace into s_game(id,title) values(240,'xiyouzhengba_918');
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(211,240,'xiyouzhengba_918',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
replace into s_game(id,title) values(241,'zhanwubusheng');
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(212,241,'zhanwubusheng',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);