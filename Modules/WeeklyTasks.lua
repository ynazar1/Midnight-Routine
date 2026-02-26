MR:RegisterModule({
    key          = "s1_weekly",
    label        = "Season 1 Weeklies",
    labelColor   = "#2ae7c6",
    resetType    = "weekly",
    defaultOpen  = true,
    rows = {

        {
            key      = "abundance",
            label    = "Weekly: Abundance",
            max      = 1,
            note     = "Earn 20,000 points in Abundance.\nAuto-tracked via quest completion.",
            questIds = { 89507 },
        },

        {
            key      = "lost_legends",
            label    = "Lost Legends",
            max      = 1,
            note     = "Select a relic to pursue in Harandar.\nRewards Avid Learner's Supply Pack.",
            questIds = { 89268 },
        },

        {
            key      = "high_esteem",
            label    = "High Esteem",
            max      = 1,
            note     = "Choose a faction ally for Saltheril's Soiree.\nDetermines which Fortify quest is available this week.",
            questIds = { 91629 },
        },
        {
            key      = "fortify_runestones",
            label    = "Fortify the Runestones",
            max      = 1,
            note     = "Collect Latent Arcana & defend a Runestone.\nOnly one faction quest is active per week:\n  Farstriders (90575), Shades of the Row (90576),\n  Blood Knights (90574), Magisters (90573).\nAuto-tracked — whichever your warband has will tick.",

            questIds = { 90575, 90576, 90574, 90573 },
        },

        {
            key      = "stand_your_ground",
            label    = "Stand Your Ground",
            max      = 1,
            note     = "Weekly quest in Eversong Woods.\nAuto-tracked via quest completion.",
            questIds = { 94581 },
        },
    },
})
