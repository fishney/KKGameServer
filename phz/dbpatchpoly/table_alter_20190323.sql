

-- 增加bigwin和hugewin的配置

replace into `s_config` (id, k, v, memo) values (26, 'spEffect', '[{"bigwin":100,"hugewin":200}]', 'bigwin和hugewin的倍数配置');


replace into `s_config` (id, k, v, memo) values (27, 'horse_race_lamp', '[
    {
        "bighugewin_lamp": [
            "\'真棒，<color=#05f989>%s</c>爆出了<color=#f525d5>%s</c>的超级大奖池\'",
            "\'Awesome, <color=#05f989>%s</c> burst out <color=#f525d5>%s</c> of super jackpot!\'"
        ],
        "free_lamp": [
            "\'耶...，<color=#05f989>%s</c>触发了免费游戏\'",
            "\'Yeah...,<color=#05f989>%s</c>triggered free game!\'"
        ]
    }
]', 
    '拉霸huge_bigwin跑马灯以及触发免费跑马灯配置');