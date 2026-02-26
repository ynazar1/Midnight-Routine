MR:RegisterModule({
    key         = "s1_weekly",
    label       = "Season 1 Weeklies",
    labelColor  = "#2ae7c6",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key      = "abundance",
            label    = "|cff2ae7c6Weekly: Abundance:|r",
            max      = 1,
            questIds = { 89507 },
        },
        {
            key      = "lost_legends",
            label    = "|cff2ae7c6Lost Legends:|r",
            max      = 1,
            questIds = { 89268 },
        },
        {
            key      = "high_esteem",
            label    = "|cff2ae7c6High Esteem:|r",
            max      = 1,
            questIds = { 91629 },
        },
        {
            key      = "fortify_runestones",
            label    = "|cff2ae7c6Fortify the Runestones:|r",
            max      = 1,
            questIds = { 90575, 90576, 90574, 90573 },
        },
        {
            key      = "stand_your_ground",
            label    = "|cff2ae7c6Stand Your Ground:|r",
            max      = 1,
            questIds = { 94581 },
        },
    },
})
