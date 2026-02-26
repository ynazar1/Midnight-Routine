local SPELL_ROWS = {

    [1270530] = { "prof_alchemy", "alch_notebook", 1 },
    [1264572] = { "prof_alchemy", "alch_drops",    1 },
    [1282284] = { "prof_alchemy", "alch_treatise", 1 },

    [1270531] = { "prof_blacksmithing", "bs_notebook", 2 },
    [1264601] = { "prof_blacksmithing", "bs_drops",    2 },
    [1282300] = { "prof_blacksmithing", "bs_treatise", 1 },

    [1270532] = { "prof_enchanting", "ench_notebook",   3 },
    [1264604] = { "prof_enchanting", "ench_drops",      2 },
    [1280988] = { "prof_enchanting", "ench_de_essence", 1 },
    [1280992] = { "prof_enchanting", "ench_de_shard",   4 },
    [1282301] = { "prof_enchanting", "ench_treatise",   1 },

    [1270533] = { "prof_engineering", "eng_notebook", 1 },
    [1264607] = { "prof_engineering", "eng_drops",    2 },
    [1282302] = { "prof_engineering", "eng_treatise", 1 },

    [1270534] = { "prof_herbalism", "herb_notebook", 3 },
    [1225342] = { "prof_herbalism", "herb_drops",    1 },
    [1225344] = { "prof_herbalism", "herb_tail",     4 },
    [1282303] = { "prof_herbalism", "herb_treatise", 1 },

    [1270535] = { "prof_inscription", "insc_notebook", 4 },
    [1264608] = { "prof_inscription", "insc_drops",    2 },
    [1282304] = { "prof_inscription", "insc_treatise", 1 },

    [1270536] = { "prof_jewelcrafting", "jc_notebook", 3 },
    [1264609] = { "prof_jewelcrafting", "jc_drops",    2 },
    [1282305] = { "prof_jewelcrafting", "jc_treatise", 1 },

    [1270537] = { "prof_leatherworking", "lw_notebook", 2 },
    [1264602] = { "prof_leatherworking", "lw_drops",    2 },
    [1282306] = { "prof_leatherworking", "lw_treatise", 1 },

    [1270538] = { "prof_mining", "mine_notebook", 3 },
    [1223243] = { "prof_mining", "mine_rock",     1 },
    [1223324] = { "prof_mining", "mine_nodule",   3 },
    [1282307] = { "prof_mining", "mine_treatise", 1 },

    [1270539] = { "prof_skinning", "skin_notebook", 3 },
    [1225644] = { "prof_skinning", "skin_drops",    1 },
    [1225646] = { "prof_skinning", "skin_bone",     3 },
    [1282308] = { "prof_skinning", "skin_treatise", 1 },

    [1270540] = { "prof_tailoring", "tail_notebook", 2 },
    [1264610] = { "prof_tailoring", "tail_drops",    2 },
    [1282309] = { "prof_tailoring", "tail_treatise", 1 },
}

local SKILL_TO_MODULES = {
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

local MODULE_SKILL = {}
for skillLine, modKey in pairs(SKILL_TO_MODULES) do
    MODULE_SKILL[modKey] = skillLine
end

local ROW_MAX = {}

local rowMaxCached = false

local function GetRowMax(modKey, rowKey)
    if not rowMaxCached then
        for _, mod in ipairs(MR.modules) do
            for _, row in ipairs(mod.rows) do
                ROW_MAX[mod.key .. "\0" .. row.key] = row.max
            end
        end
        rowMaxCached = true
    end
    return ROW_MAX[modKey .. "\0" .. rowKey] or 99
end

local spellFrame = CreateFrame("Frame")
spellFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

spellFrame:SetScript("OnEvent", function(_, _, unit, _, spellID)
    if unit ~= "player" then return end
    local entry = SPELL_ROWS[spellID]
    if not entry then return end
    local modKey, rowKey, amount = entry[1], entry[2], entry[3]
    MR:BumpProgress(modKey, rowKey, amount, GetRowMax(modKey, rowKey))
end)

local origSlash = SlashCmdList["MIDROUTE"]
SlashCmdList["MIDROUTE"] = function(msg)
    msg = (msg or ""):lower():trim()
    if msg == "profs" then
        print("|cff2ae7c6MTL Professions:|r Detected skill lines:")
        local found = false
        for sl, modKey in pairs(SKILL_TO_MODULES) do
            if MR.playerProfessions[sl] then
                print(string.format("  |cff00ff96✓|r skill %d → %s", sl, modKey))
                found = true
            end
        end
        if not found then
            print("  |cffff4444None found.|r Run /mr profs after entering world.")
        end
    elseif msg == "testspell" then
        print("|cff2ae7c6MTL:|r Listening for next profession KP spell cast...")
        local tf = CreateFrame("Frame")
        tf:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        tf:SetScript("OnEvent", function(self, _, unit, _, sid)
            if unit ~= "player" then return end
            local e = SPELL_ROWS[sid]
            if e then
                print(string.format("|cff2ae7c6MTL:|r Spell %d → %s / %s (+%d KP) ✓ TRACKED", sid, e[1], e[2], e[3]))
            else
                print(string.format("|cff2ae7c6MTL:|r Spell %d cast (not a KP spell)", sid))
            end
            self:UnregisterAllEvents()
        end)
    else
        origSlash(msg)
    end
end

MR:RegisterModule({
    key         = "prof_alchemy",
    profSkillLine = 2906,
    label       = "Alchemy",
    labelColor  = "#33bbff",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "alch_notebook",
            spellTracked = true,
            label = "|cff33bbffWeekly Notebook  –  2 KP:|r",
            max   = 2,
            note  = "Thalassian Alchemist's Notebook — from weekly world drops.\nUse the item; auto-tracked via spell cast. (item:263454)",
        },
        {
            key   = "alch_drops",
            spellTracked = true,
            label = "|cff33bbffWeekly Drops – Spore/Cruor  –  4 KP:|r",
            max   = 4,
            note  = "Lightbloomed Spore Sample x4 + Aged Cruor x1 (+1 KP each).\nAuto-tracked when each is used. (items: 259188, 259189)",
        },
        {
            key   = "alch_treatise",
            spellTracked = true,
            label = "|cff33bbffTreatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Alchemy — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245755)",
        },
        {
            key      = "alch_dmf",
            label    = "|cff33bbffDarkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: A Fizzy Fusion (quest:29506)\nAuto-tracked via quest completion.",
            questIds = { 29506 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_blacksmithing",
    profSkillLine = 2907,
    label       = "Blacksmithing",
    labelColor  = "#aaaaaa",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "bs_notebook",
            spellTracked = true,
            label = "|cffaaaaaaWeekly Journal  –  2 KP:|r",
            max   = 2,
            note  = "Thalassian Blacksmith's Journal — from weekly world drops.\nAuto-tracked when used. (item:263455)",
        },
        {
            key   = "bs_drops",
            spellTracked = true,
            label = "|cffaaaaaaWeekly Drops – Oil/Stone  –  4 KP:|r",
            max   = 4,
            note  = "Infused Quenching Oil x2 + Thalassian Whetstone x2 (+2 KP each).\nAuto-tracked when each is used. (items: 259191, 259190)",
        },
        {
            key   = "bs_treatise",
            spellTracked = true,
            label = "|cffaaaaaa Treatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Blacksmithing — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245763)\n[If not tracking: run /mr testspell then use the treatise to confirm spell ID]",
        },
        {
            key      = "bs_dmf",
            label    = "|cffaaaaaaDarkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Baby Needs Two Pair of Shoes (quest:29508)\nAuto-tracked via quest completion.",
            questIds = { 29508 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_enchanting",
    profSkillLine = 2909,
    label       = "Enchanting",
    labelColor  = "#bb77ff",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "ench_notebook",
            spellTracked = true,
            label = "|cffbb77ffWeekly Folio  –  3 KP:|r",
            max   = 3,
            note  = "Thalassian Enchanter's Folio — from weekly world drops.\nAuto-tracked when used. (item:263464)",
        },
        {
            key   = "ench_drops",
            spellTracked = true,
            label = "|cffbb77ffWeekly Drops – Ashes/Vellum  –  4 KP:|r",
            max   = 4,
            note  = "Voidstorm Ashes x2 + Lost Thalassian Vellum x2 (+2 KP each).\nAuto-tracked when each is used. (items: 259192, 259193)",
        },
        {
            key   = "ench_de_essence",
            spellTracked = true,
            label = "|cffbb77ffDE – Arcane Essence  –  5 KP:|r",
            max   = 5,
            note  = "Swirling Arcane Essence x5 — from disenchanting (+1 KP each).\nAuto-tracked when each is used. (item:267654)",
        },
        {
            key   = "ench_de_shard",
            spellTracked = true,
            label = "|cffbb77ffDE – Mana Shard  –  4 KP:|r",
            max   = 4,
            note  = "Brimming Mana Shard — rare disenchant drop (+4 KP).\nAuto-tracked when used. (item:267655)",
        },
        {
            key   = "ench_treatise",
            spellTracked = true,
            label = "|cffbb77ffTreatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Enchanting — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245759)",
        },
        {
            key      = "ench_dmf",
            label    = "|cffbb77ffDarkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Putting Trash to Good Use (quest:29510)\nAuto-tracked via quest completion.",
            questIds = { 29510 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_engineering",
    profSkillLine = 2910,
    label       = "Engineering",
    labelColor  = "#ffcc44",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "eng_notebook",
            spellTracked = true,
            label = "|cffffcc44Weekly Notepad  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Engineer's Notepad — from weekly world drops.\nAuto-tracked when used. (item:263456)",
        },
        {
            key   = "eng_drops",
            spellTracked = true,
            label = "|cffffcc44Weekly Drops – Gear/Capacitor  –  4 KP:|r",
            max   = 4,
            note  = "Dance Gear x2 + Dawn Capacitor x2 (+2 KP each).\nAuto-tracked when each is used. (items: 259194, 259195)",
        },
        {
            key   = "eng_treatise",
            spellTracked = true,
            label = "|cffffcc44Treatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Engineering — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245809)",
        },
        {
            key      = "eng_dmf",
            label    = "|cffffcc44Darkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Talkin' Tonks (quest:29511)\nAuto-tracked via quest completion.",
            questIds = { 29511 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_herbalism",
    profSkillLine = 2912,
    label       = "Herbalism",
    labelColor  = "#55cc44",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "herb_notebook",
            spellTracked = true,
            label = "|cff55cc44Weekly Notes  –  3 KP:|r",
            max   = 3,
            note  = "Thalassian Herbalist's Notes — from weekly world drops.\nAuto-tracked when used. (item:263462)",
        },
        {
            key   = "herb_drops",
            spellTracked = true,
            label = "|cff55cc44Weekly Drop – Phoenix Plumes  –  5 KP:|r",
            max   = 5,
            note  = "Thalassian Phoenix Plume x5 (+1 KP each).\nAuto-tracked when each is used. (item:238465)",
        },
        {
            key   = "herb_tail",
            spellTracked = true,
            label = "|cff55cc44Weekly Drop – Phoenix Tail  –  4 KP:|r",
            max   = 4,
            note  = "Thalassian Phoenix Tail — rare drop (+4 KP).\nAuto-tracked when used. (item:238466)",
        },
        {
            key   = "herb_treatise",
            spellTracked = true,
            label = "|cff55cc44Treatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Herbalism — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245761)",
        },
        {
            key      = "herb_dmf",
            label    = "|cff55cc44Darkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Herbs for Healing (quest:29514)\nAuto-tracked via quest completion.",
            questIds = { 29514 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_inscription",
    profSkillLine = 2913,
    label       = "Inscription",
    labelColor  = "#44ddaa",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "insc_notebook",
            spellTracked = true,
            label = "|cff44ddaaWeekly Journal  –  4 KP:|r",
            max   = 4,
            note  = "Thalassian Scribe's Journal — from weekly world drops.\nAuto-tracked when used. (item:263457)",
        },
        {
            key   = "insc_drops",
            spellTracked = true,
            label = "|cff44ddaaWeekly Drops – Ink/Rune  –  4 KP:|r",
            max   = 4,
            note  = "Brilliant Phoenix Ink x2 + Loa-Blessed Rune x2 (+2 KP each).\nAuto-tracked when each is used. (items: 259196, 259197)",
        },
        {
            key   = "insc_treatise",
            spellTracked = true,
            label = "|cff44ddaaTreatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Inscription — self-crafted (Warbound).\nAuto-tracked when used. (item:245757)",
        },
        {
            key      = "insc_dmf",
            label    = "|cff44ddaaDarkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Writing the Future (quest:29515)\nAuto-tracked via quest completion.",
            questIds = { 29515 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_jewelcrafting",
    profSkillLine = 2914,
    label       = "Jewelcrafting",
    labelColor  = "#ff7799",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "jc_notebook",
            spellTracked = true,
            label = "|cffff7799Weekly Notebook  –  2 KP:|r",
            max   = 3,
            note  = "Thalassian Jewelcrafter's Notebook — from weekly world drops.\nAuto-tracked when used. (item:263458)",
        },
        {
            key   = "jc_drops",
            spellTracked = true,
            label = "|cffff7799Weekly Drops – Gems/Stone  –  4 KP:|r",
            max   = 4,
            note  = "Void-Touched Diamond Fragments x2 + Harandar Stone Sample x2 (+2 each).\nAuto-tracked when each is used. (items: 259198, 259199)",
        },
        {
            key   = "jc_treatise",
            spellTracked = true,
            label = "|cffff7799Treatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Jewelcrafting — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245760)",
        },
        {
            key      = "jc_dmf",
            label    = "|cffff7799Darkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Keeping the Faire Sparkling (quest:29516)\nAuto-tracked via quest completion.",
            questIds = { 29516 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_leatherworking",
    profSkillLine = 2915,
    label       = "Leatherworking",
    labelColor  = "#cc8833",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "lw_notebook",
            spellTracked = true,
            label = "|cffcc8833Weekly Journal  –  2 KP:|r",
            max   = 2,
            note  = "Thalassian Leatherworker's Journal — from weekly world drops.\nAuto-tracked when used. (item:263459)",
        },
        {
            key   = "lw_drops",
            spellTracked = true,
            label = "|cffcc8833Weekly Drops – Oil  –  4 KP:|r",
            max   = 4,
            note  = "Amani Tanning Oil x2 + Thalassian Mana Oil x2 (+2 KP each).\nAuto-tracked when each is used. (items: 259200, 259201)",
        },
        {
            key   = "lw_treatise",
            spellTracked = true,
            label = "|cffcc8833Treatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Leatherworking — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245758)",
        },
        {
            key      = "lw_dmf",
            label    = "|cffcc8833Darkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Eyes on the Prizes (quest:29517)\nAuto-tracked via quest completion.",
            questIds = { 29517 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_mining",
    profSkillLine = 2916,
    label       = "Mining",
    labelColor  = "#cccccc",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "mine_notebook",
            spellTracked = true,
            label = "|cffccccccWeekly Notes  –  3 KP:|r",
            max   = 3,
            note  = "Thalassian Miner's Notes — from weekly world drops.\nAuto-tracked when used. (item:263463)",
        },
        {
            key   = "mine_rock",
            spellTracked = true,
            label = "|cffccccccWeekly Drop – Rock Specimens  –  5 KP:|r",
            max   = 5,
            note  = "Igneous Rock Specimen x5 (+1 KP each).\nAuto-tracked when each is used. (item:237496)",
        },
        {
            key   = "mine_nodule",
            spellTracked = true,
            label = "|cffccccccWeekly Drop – Septarian Nodule  –  3 KP:|r",
            max   = 3,
            note  = "Septarian Nodule — rare drop (+3 KP).\nAuto-tracked when used. (item:237506)",
        },
        {
            key   = "mine_treatise",
            spellTracked = true,
            label = "|cffccccccTreatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Mining — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245762)",
        },
        {
            key      = "mine_dmf",
            label    = "|cffccccccDarkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Rearm, Reuse, Recycle (quest:29518)\nAuto-tracked via quest completion.",
            questIds = { 29518 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_skinning",
    profSkillLine = 2917,
    label       = "Skinning",
    labelColor  = "#c8a060",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "skin_notebook",
            spellTracked = true,
            label = "|cffc8a060Weekly Notes  –  3 KP:|r",
            max   = 3,
            note  = "Thalassian Skinner's Notes — from weekly world drops.\nAuto-tracked when used. (item:263461)",
        },
        {
            key   = "skin_drops",
            spellTracked = true,
            label = "|cffc8a060Weekly Drop – Hide/Sample  –  5 KP:|r",
            max   = 5,
            note  = "Manafused Sample OR Fine Void-Tempered Hide x5 (+1 KP each).\nAuto-tracked when each is used. (items: 238627, 238625)",
        },
        {
            key   = "skin_bone",
            spellTracked = true,
            label = "|cffc8a060Weekly Drop – Mana-Infused Bone  –  3 KP:|r",
            max   = 3,
            note  = "Mana-Infused Bone — rare drop (+3 KP).\nAuto-tracked when used. (item:238626)",
        },
        {
            key   = "skin_treatise",
            spellTracked = true,
            label = "|cffc8a060Treatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Skinning — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245828)",
        },
        {
            key      = "skin_dmf",
            label    = "|cffc8a060Darkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Tan My Hide (quest:29519)\nAuto-tracked via quest completion.",
            questIds = { 29519 },
        },
    },
})

MR:RegisterModule({
    key         = "prof_tailoring",
    profSkillLine = 2918,
    label       = "Tailoring",
    labelColor  = "#ffaadd",
    resetType   = "weekly",
    defaultOpen = false,
    rows = {
        {
            key   = "tail_notebook",
            spellTracked = true,
            label = "|cffffaaddWeekly Notebook  –  2 KP:|r",
            max   = 2,
            note  = "Thalassian Tailor's Notebook — from weekly world drops.\nAuto-tracked when used. (item:263460)",
        },
        {
            key   = "tail_drops",
            spellTracked = true,
            label = "|cffffaaddWeekly Drops – Collar/Memento  –  4 KP:|r",
            max   = 4,
            note  = "Finely Woven Lynx Collar x2 + Embroidered Memento x2 (+2 KP each).\nAuto-tracked when each is used. (items: 259203, 259202)",
        },
        {
            key   = "tail_treatise",
            spellTracked = true,
            label = "|cffffaaddTreatise  –  1 KP:|r",
            max   = 1,
            note  = "Thalassian Treatise on Tailoring — crafted by Inscription (Warbound).\nAuto-tracked when used. (item:245756)",
        },
        {
            key      = "tail_dmf",
            label    = "|cffffaaddDarkmoon Faire  –  1 KP:|r",
            max      = 1,
            note     = "Quest: Banners, Banners Everywhere! (quest:29520)\nAuto-tracked via quest completion.",
            questIds = { 29520 },
        },
    },
})
