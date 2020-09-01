DELETE FROM s_config WHERE k = "regcoin";
INSERT INTO s_config(k,v,memo) VALUES ('mobileregcoin', 2300, '手机号注册');
INSERT INTO s_config(k,v,memo) VALUES ('guestregcoin', 800, '游客注册');
INSERT INTO s_config(k,v,memo) VALUES ('bindmobilecoin', 5000, '绑定手机号');
