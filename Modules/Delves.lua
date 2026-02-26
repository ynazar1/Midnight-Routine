MR:RegisterModule({
    key         = "delves",
    label       = "Delves",
    labelColor  = "#c8956c",
    resetType   = "weekly",
    defaultOpen = false,

    onScan = function(mod)
        if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return end
        local activities = C_WeeklyRewards.GetActivities()
        if not activities then return end

        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end

        for _, act in ipairs(activities) do
            if act.type == 4 then
                local prog = act.progress or 0
                db[mod.key]["delve_runs"] = prog

                db[mod.key]["delve_t11"] = ((act.level or 0) >= 11) and 1 or 0
                break
            end
        end
    end,

    rows = {
        {
            key      = "delve_bounty",
            label    = "|cffc8956cDelver's Bounty Collected:|r",
            max      = 1,
            note     = "Claim from Brann weekly",
            questIds = { 83100 },
        },
        {
            key     = "delve_runs",
            label   = "|cffc8956cDelve / World Runs:|r",
            max     = 8,
            note    = "Auto-tracked · feeds Great Vault World slot (2/4/8)",
            liveKey = "delve_runs",
        },
        {
            key         = "delve_t11",
            label       = "|cffc8956cTier 11 Delve Cleared:|r",
            max         = 1,
            note        = "Auto-detected from highest Delve level this week",
            spellTracked = true,
        },
        {
            key      = "delve_zekvir1",
            label    = "|cffc8956cZek'vir ? Defeated:|r",
            max      = 1,
            note     = "Optional weekly challenge",
            questIds = { 83150 },
        },
        {
            key      = "delve_zekvir2",
            label    = "|cffc8956cZek'vir ?? Defeated:|r",
            max      = 1,
            note     = "Optional weekly challenge (harder)",
            questIds = { 83151 },
        },
    },
})
