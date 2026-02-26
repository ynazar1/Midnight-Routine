MR:RegisterModule({
    key         = "lfr",
    label       = "LFR  –  Nerub-ar Palace",
    labelColor  = "#99ccff",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key      = "lfr_w1",
            label    = "|cff99ccffWing 1: Darkflame Cleft:|r",
            max      = 1,
            note     = "Ulgrax & Bloodbound Horror",
            questIds = { 83700 },
        },
        {
            key      = "lfr_w2",
            label    = "|cff99ccffWing 2: The Swarming Shores:|r",
            max      = 1,
            note     = "Sikran & Rasha'nan",
            questIds = { 83701 },
        },
        {
            key      = "lfr_w3",
            label    = "|cff99ccffWing 3: The Soul Drinker's Lair:|r",
            max      = 1,
            note     = "Broodtwister & Nexus-Princess",
            questIds = { 83702 },
        },
        {
            key      = "lfr_w4",
            label    = "|cff99ccffWing 4: The Seat of the Throne:|r",
            max      = 1,
            note     = "Ansurek (final boss)",
            questIds = { 83703 },
        },
    },
})
