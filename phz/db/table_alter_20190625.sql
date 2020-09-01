alter table d_user add red_envelope decimal(17,4) DEFAULT 0 COMMENT '用户红包金额';
alter table d_user add hadshowredenvelope tinyint(1) DEFAULT 0 COMMENT '用户红包金额是否已展示';