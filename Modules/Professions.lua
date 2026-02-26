local SPELL_ROWS = {
    [1270530] = { "prof_alchemy",        "alch_notebook",   1 },
    [1264572] = { "prof_alchemy",        "alch_drops",      1 },
    [1282284] = { "prof_alchemy",        "alch_treatise",   1 },

    [1270531] = { "prof_blacksmithing",  "bs_notebook",     1 },
    [1264601] = { "prof_blacksmithing",  "bs_drops",        1 },
    [1282300] = { "prof_blacksmithing",  "bs_treatise",     1 },

    [1270532] = { "prof_enchanting",     "ench_notebook",   1 },
    [1264604] = { "prof_enchanting",     "ench_drops",      1 },
    [1280988] = { "prof_enchanting",     "ench_de_essence", 1 },
    [1280992] = { "prof_enchanting",     "ench_de_shard",   4 },
    [1282301] = { "prof_enchanting",     "ench_treatise",   1 },

    [1270533] = { "prof_engineering",    "eng_notebook",    1 },
    [1264607] = { "prof_engineering",    "eng_drops",       1 },
    [1282302] = { "prof_engineering",    "eng_treatise",    1 },

    [1270534] = { "prof_herbalism",      "herb_notebook",   3 },
    [1225342] = { "prof_herbalism",      "herb_drops",      1 },
    [1225344] = { "prof_herbalism",      "herb_tail",       4 },
    [1282303] = { "prof_herbalism",      "herb_treatise",   1 },

    [1270535] = { "prof_inscription",    "insc_notebook",   4 },
    [1264608] = { "prof_inscription",    "insc_drops",      1 },
    [1282304] = { "prof_inscription",    "insc_treatise",   1 },

    [1270536] = { "prof_jewelcrafting",  "jc_notebook",     3 },
    [1264609] = { "prof_jewelcrafting",  "jc_drops",        1 },
    [1282305] = { "prof_jewelcrafting",  "jc_treatise",     1 },

    [1270537] = { "prof_leatherworking", "lw_notebook",     2 },
    [1264602] = { "prof_leatherworking", "lw_drops",        1 },
    [1282306] = { "prof_leatherworking", "lw_treatise",     1 },

    [1270538] = { "prof_mining",         "mine_notebook",   3 },
    [1223243] = { "prof_mining",         "mine_rock",       1 },
    [1223324] = { "prof_mining",         "mine_nodule",     3 },
    [1282307] = { "prof_mining",         "mine_treatise",   1 },

    [1270539] = { "prof_skinning",       "skin_notebook",   3 },
    [1225644] = { "prof_skinning",       "skin_drops",      1 },
    [1225646] = { "prof_skinning",       "skin_bone",       3 },
    [1282308] = { "prof_skinning",       "skin_treatise",   1 },

    [1270540] = { "prof_tailoring",      "tail_notebook",   2 },
    [1264610] = { "prof_tailoring",      "tail_drops",      1 },
    [1282309] = { "prof_tailoring",      "tail_treatise",   1 },
}

local SKILL_TO_MODULE = {
    [2906] = "prof_alchemy",
    [2907] = "prof_blacksmithing",
    [2909] = "prof_enchanting",
    [2910] = "prof_engineering",
    [2912] = "prof_herbalism",
    [2913] = "prof_inscription",
    [2914] = "prof_jewelcrafting",
    [2915] = "prof_leatherworking",
    [2916] = "prof_mining",
    [2917] = "prof_skinning",
    [2918] = "prof_tailoring",
}

local rowMaxCache = nil

local function GetRowMax(modKey, rowKey)
    if not rowMaxCache then
        rowMaxCache = {}
        for _, mod in ipairs(MR.modules) do
            for _, row in ipairs(mod.rows) do
                rowMaxCache[mod.key .. "\0" .. row.key] = row.max
            end
        end
    end
    return rowMaxCache[modKey .. "\0" .. rowKey] or 1
end

MR:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    rowMaxCache = nil
end)

MR:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
    if unit ~= "player" then return end
    local entry = SPELL_ROWS[spellID]
    if not entry then return end
    local modKey, rowKey, amount = entry[1], entry[2], entry[3]
    if not MR.db then return end
    MR:BumpProgress(modKey, rowKey, amount, GetRowMax(modKey, rowKey))
end)

MR:RegisterModule({
    key           = "prof_alchemy",
    profSkillLine = 2906,
    label         = "Alchemy",
    labelColor    = "#33bbff",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "alch_notebook", spellTracked = true, label = "|cff33bbffWeekly Quest:|r",              max = 1 },
        { key = "alch_drops",    spellTracked = true, label = "|cff33bbffWeekly Drops – Spore/Cruor:|r", max = 2 },
        { key = "alch_treatise", spellTracked = true, label = "|cff33bbffTreatise:|r",                   max = 1 },
        { key = "alch_dmf",      questIds = { 29506 }, label = "|cff33bbffDarkmoon Faire:|r",            max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_blacksmithing",
    profSkillLine = 2907,
    label         = "Blacksmithing",
    labelColor    = "#aaaaaa",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "bs_notebook", spellTracked = true, label = "|cffaaaaaaWeekly Quest:|r",           max = 1 },
        { key = "bs_drops",    spellTracked = true, label = "|cffaaaaaaWeekly Drops – Oil/Stone:|r", max = 2 },
        { key = "bs_treatise", spellTracked = true, label = "|cffaaaaaa Treatise:|r",               max = 1 },
        { key = "bs_dmf",      questIds = { 29508 }, label = "|cffaaaaaa Darkmoon Faire:|r",        max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_enchanting",
    profSkillLine = 2909,
    label         = "Enchanting",
    labelColor    = "#bb77ff",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "ench_notebook",   spellTracked = true, label = "|cffbb77ffWeekly Quest:|r",              max = 1 },
        { key = "ench_drops",      spellTracked = true, label = "|cffbb77ffWeekly Drops – Ashes/Vellum:|r", max = 2 },
        { key = "ench_de_essence", spellTracked = true, label = "|cffbb77ffDE – Arcane Essence:|r",        max = 5 },
        { key = "ench_de_shard",   spellTracked = true, label = "|cffbb77ffDE – Mana Shard:|r",            max = 1 },
        { key = "ench_treatise",   spellTracked = true, label = "|cffbb77ffTreatise:|r",                   max = 1 },
        { key = "ench_dmf",        questIds = { 29510 }, label = "|cffbb77ffDarkmoon Faire:|r",            max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_engineering",
    profSkillLine = 2910,
    label         = "Engineering",
    labelColor    = "#ffcc44",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "eng_notebook", spellTracked = true, label = "|cffffcc44Weekly Quest:|r",                   max = 1 },
        { key = "eng_drops",    spellTracked = true, label = "|cffffcc44Weekly Drops – Gear/Capacitor:|r",   max = 2 },
        { key = "eng_treatise", spellTracked = true, label = "|cffffcc44Treatise:|r",                        max = 1 },
        { key = "eng_dmf",      questIds = { 29511 }, label = "|cffffcc44Darkmoon Faire:|r",                 max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_herbalism",
    profSkillLine = 2912,
    label         = "Herbalism",
    labelColor    = "#55cc44",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "herb_notebook", spellTracked = true, label = "|cff55cc44Weekly Quest:|r",                     max = 1 },
        { key = "herb_drops",    spellTracked = true, label = "|cff55cc44Weekly Gather – Phoenix Plumes:|r",    max = 5 },
        { key = "herb_tail",     spellTracked = true, label = "|cff55cc44Weekly Gather – Phoenix Tail:|r",      max = 1 },
        { key = "herb_treatise", spellTracked = true, label = "|cff55cc44Treatise:|r",                          max = 1 },
        { key = "herb_dmf",      questIds = { 29514 }, label = "|cff55cc44Darkmoon Faire:|r",                   max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_inscription",
    profSkillLine = 2913,
    label         = "Inscription",
    labelColor    = "#44ddaa",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "insc_notebook", spellTracked = true, label = "|cff44ddaaWeekly Quest:|r",          max = 1 },
        { key = "insc_drops",    spellTracked = true, label = "|cff44ddaaWeekly Drops – Ink/Rune:|r", max = 2 },
        { key = "insc_treatise", spellTracked = true, label = "|cff44ddaaTreatise:|r",               max = 1 },
        { key = "insc_dmf",      questIds = { 29515 }, label = "|cff44ddaaDarkmoon Faire:|r",        max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_jewelcrafting",
    profSkillLine = 2914,
    label         = "Jewelcrafting",
    labelColor    = "#ff7799",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "jc_notebook", spellTracked = true, label = "|cffff7799Weekly Quest:|r",               max = 1 },
        { key = "jc_drops",    spellTracked = true, label = "|cffff7799Weekly Drops – Gems/Stone:|r",   max = 2 },
        { key = "jc_treatise", spellTracked = true, label = "|cffff7799Treatise:|r",                    max = 1 },
        { key = "jc_dmf",      questIds = { 29516 }, label = "|cffff7799Darkmoon Faire:|r",             max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_leatherworking",
    profSkillLine = 2915,
    label         = "Leatherworking",
    labelColor    = "#cc8833",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "lw_notebook", spellTracked = true, label = "|cffcc8833Weekly Quest:|r",        max = 1 },
        { key = "lw_drops",    spellTracked = true, label = "|cffcc8833Weekly Drops – Oil:|r",  max = 2 },
        { key = "lw_treatise", spellTracked = true, label = "|cffcc8833Treatise:|r",            max = 1 },
        { key = "lw_dmf",      questIds = { 29517 }, label = "|cffcc8833Darkmoon Faire:|r",     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_mining",
    profSkillLine = 2916,
    label         = "Mining",
    labelColor    = "#cccccc",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "mine_notebook", spellTracked = true, label = "|cffccccccWeekly Quest:|r",                  max = 1 },
        { key = "mine_rock",     spellTracked = true, label = "|cffccccccWeekly Gather – Rock Specimens:|r", max = 5 },
        { key = "mine_nodule",   spellTracked = true, label = "|cffccccccWeekly Gather – Septarian Nodule:|r", max = 1 },
        { key = "mine_treatise", spellTracked = true, label = "|cffccccccTreatise:|r",                       max = 1 },
        { key = "mine_dmf",      questIds = { 29518 }, label = "|cffccccccDarkmoon Faire:|r",                max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_skinning",
    profSkillLine = 2917,
    label         = "Skinning",
    labelColor    = "#c8a060",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "skin_notebook", spellTracked = true, label = "|cffc8a060Weekly Quest:|r",                      max = 1 },
        { key = "skin_drops",    spellTracked = true, label = "|cffc8a060Weekly Gather – Hide/Sample:|r",        max = 5 },
        { key = "skin_bone",     spellTracked = true, label = "|cffc8a060Weekly Gather – Mana-Infused Bone:|r",  max = 1 },
        { key = "skin_treatise", spellTracked = true, label = "|cffc8a060Treatise:|r",                           max = 1 },
        { key = "skin_dmf",      questIds = { 29519 }, label = "|cffc8a060Darkmoon Faire:|r",                    max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_tailoring",
    profSkillLine = 2918,
    label         = "Tailoring",
    labelColor    = "#ffaadd",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "tail_notebook", spellTracked = true, label = "|cffffaaddWeekly Quest:|r",              max = 1 },
        { key = "tail_drops",    spellTracked = true, label = "|cffffaaddWeekly Drops – Collar/Memento:|r", max = 2 },
        { key = "tail_treatise", spellTracked = true, label = "|cffffaaddTreatise:|r",                   max = 1 },
        { key = "tail_dmf",      questIds = { 29520 }, label = "|cffffaaddDarkmoon Faire:|r",            max = 1 },
    },
})
