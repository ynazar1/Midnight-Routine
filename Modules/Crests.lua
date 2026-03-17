local CREST_CAP = 100
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local function ItemLabel(itemID, fallback)
    local itemName = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    return string.format("|cffe8c96e%s:|r", itemName or fallback)
end

MR:RegisterModule({
    key         = "currencies",
    label       = L["Currencies"],
    labelColor  = "#f1c232",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        { key = "crest_adventurer", currencyId = 3383, max = CREST_CAP, label = L["Crest_Adventurer_Label"] },
        { key = "crest_veteran",    currencyId = 3341, max = CREST_CAP, label = L["Crest_Veteran_Label"] },
        { key = "crest_champion",   currencyId = 3343, max = CREST_CAP, label = L["Crest_Champion_Label"] },
        { key = "crest_hero",       currencyId = 3345, max = CREST_CAP, label = L["Crest_Hero_Label"] },
        { key = "crest_myth",       currencyId = 3347, max = CREST_CAP, label = L["Crest_Myth_Label"] },
        { key = "manaflux",         currencyId = 3378, noMax = true, label = L["Currency_Manaflux_Label"] },
        { key = "voidlight_marl",   currencyId = 3316, noMax = true, label = L["Currency_VoidlightMarl_Label"] },
        {
            key        = "shards",
            label      = L["CofferKey_Label"],
            currencyId = 3310,
            max        = 600,
        },
        {
            key    = "restored_coffer_key",
            label  = ItemLabel(263191, "Restored Coffer Key"),
            itemId = 263191,
            noMax  = true,
        },
        {
            key    = "spark_radiance",
            label  = ItemLabel(232875, "Spark of Radiance"),
            itemId = 232875,
            noMax  = true,
        },
        {
            key        = "undercoin",
            label      = L["Currency_Undercoin_Label"],
            currencyId = 2803,
            noMax      = true,
        },
        {
            key        = "shard_dundun",
            label      = L["Shard_Dundun_Label"],
            currencyId = 3376,
            noMax      = true,
        },
    },
})
