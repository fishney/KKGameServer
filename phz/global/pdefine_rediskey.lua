PDEFINE_REDISKEY =
{
    ["YOU9API"] =
    {
        ["disbigbang"] = "you9sdkapi:bigbang:disbigbang",
        ["bigbangreward"] = "you9sdkapi:bigbang:reward",
        ["redbagsetting"] = "you9sdkapi:redbag:setting",
        ["pooljp"] = "you9sdkapi:pooljp:data",
        ["day7coindiff"] = "you9sdkapi:7daycoindiff",
        ["rewardrate_user"] = "you9sdkapi:rewardrate:user",
        ["rewardrate_agent"] = "you9sdkapi:rewardrate:agent",
        ["token2account"] = "you9sdkapi:account:token2account",
        ["account2token"] = "you9sdkapi:account:account2token",
        ["loanpoolnormal"] = "you9sdkapi:loanpoolnormal",
        ["subgame_localpool"] = "you9sdkapi:subgamepool",
        ["disslc"] = "you9sdkapi:disslc:data", --双龙彩
        ["diszbc"] = "you9sdkapi:diszbc:data", --争霸彩
    },
    ["GAME"]=
    {
        --类型:数据所属层次
        ["waterpool"]="game:waterpool",
        ["loginlock"]="game:loginlock",
        ["deskdata"]="game:deskdata",
        ["history"]="game:history",
        ["loandata"]="game:loandata",
        ["expire_sortedset"]="game:deskdata:expire_sortedset",
    }
}
return PDEFINE_REDISKEY