local CREST_CAP = 100

local CREST_CURRENCIES = {
    { key = "crest_adventurer", id = 3383, label = "|cffb7b7b7Adventurer Dawncrest:|r", color = "#b7b7b7",
      note = "Repeatable Outdoor Events · Delve T4\nUpgrades gear to ilvl 224–237" },
    { key = "crest_veteran",    id = 3341, label = "|cff1eff00Veteran Dawncrest:|r",    color = "#1eff00",
      note = "Outdoor Events · LFR · Heroic Dungeons · Delves T5–6\nUpgrades gear to ilvl 237–250" },
    { key = "crest_champion",   id = 3343, label = "|cfff1c232Champion Dawncrest:|r",   color = "#f1c232",
      note = "Weekly Outdoor Events · Normal Raid · Mythic Dungeon · M+ 2–3 · Delves T7–10\nUpgrades gear to ilvl 250–263" },
    { key = "crest_hero",       id = 3345, label = "|cff0070ddHero Dawncrest:|r",       color = "#0070dd",
      note = "Heroic Raid · M+ 4–8 · Delve T11 · Trovehunter T8+\nUpgrades gear to ilvl 263–276" },
    { key = "crest_myth",       id = 3347, label = "|cffff8000Myth Dawncrest:|r",       color = "#ff8000",
      note = "Heroic Raid · M+ 9+\nUpgrades gear to ilvl 276–289" },
}

MR:RegisterModule({
    key         = "crests",
    currencyTracked = true,
    label       = "Crest Tracker",
    labelColor  = "#f1c232",
    resetType   = "weekly",
    defaultOpen = true,

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        for _, crest in ipairs(CREST_CURRENCIES) do
            local info = C_CurrencyInfo.GetCurrencyInfo(crest.id)
            if info then
                db[mod.key][crest.key] = math.min(info.quantity, CREST_CAP)
            end
        end
    end,

    rows = (function()
        local rows = {}
        for _, c in ipairs(CREST_CURRENCIES) do
            table.insert(rows, {
                key          = c.key,
                label        = c.label,
                max          = CREST_CAP,
                note         = c.note,
                spellTracked = true,
            })
        end
        return rows
    end)(),
})

