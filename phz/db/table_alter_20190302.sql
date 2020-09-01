replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(116,226,'draontigeralone1',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(117,227,'draontigeralone2',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(118,228,'draontigeralone3',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='draontigeralone1' where id=226;
update s_game set title='draontigeralone2' where id=227;
update s_game set title='draontigeralone3' where id=228;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(123,236,'motorbike',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='motorbike' where id=236;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(124,224,'roulette24',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='roulette24' where id=224;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(125,223,'roulettemini',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='roulettemini' where id=223;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(126,225,'roulette73',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='roulette73' where id=225;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(127,237,'benz1',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='benz1' where id=237;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(128,229,'touzi',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='touzi' where id=229;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(129,230,'baccaratalone',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='baccaratalone' where id=230;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(130,231,'threecard',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='threecard' where id=231;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(131,232,'gambling',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='gambling' where id=232;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(132,233,'gamblingwar',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='gamblingwar' where id=233;
replace into s_sess(id,gameid,title,basecoin,mincoin,leftcoin,hot,status,ord,free,level,param1,param2,param3,param4,revenue,seat) values(133,234,'nnalone',1,0.00,1,1,1,100,0,0,0,0,0,0,0,1);
update s_game set title='nnalone' where id=234;   

replace into `s_sess` (gameid, title, basecoin, mincoin, leftcoin, hot, status, ord, free,level, param1, param2, param3,  param4,  revenue, seat )values (129, "复活节", 1, 0, 1, 1, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1);
replace into `s_game` (id, title) values(129, "复活节");
replace into `s_game_type` (gametype, gameid, title, state, hot)  VALUES (2, 129, "复活节", 1, 100);

update s_game set title = 'fuhuojie' where id = 129;

