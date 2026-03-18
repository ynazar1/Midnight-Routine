local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local HONOR_CAP        = 15000
local CONQUEST_CAP     = 1600
local BLOODY_TOKEN_CAP = 1600

local CURRENCY_HONOR        = 1792
local CURRENCY_CONQUEST     = 1602
local CURRENCY_BLOODY_TOKEN = 2123

local QUEST_SPARKS_ZULAMAN        = 93424
local QUEST_SPARKS_HARANDAR       = 93425
local QUEST_SPARKS_VOIDSTORM      = 93426
local QUEST_PREPARING_BATTLE      = 89354
local QUEST_SOMETHING_DIFFERENT   = 47148
local QUEST_EARLY_TRAINING        = 94835

MR:RegisterModule({
    key         = "pvp_currencies",
    label       = L["PvP_CurrenciesTitle"],
    labelColor  = "#cc3333",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key        = "honor",
            currencyId = CURRENCY_HONOR,
            max        = HONOR_CAP,
            label      = L["PvP_Honor_Label"],
            note       = L["PvP_Honor_Note"],
        },
        {
            key        = "conquest",
            currencyId = CURRENCY_CONQUEST,
            max        = CONQUEST_CAP,
            label      = L["PvP_Conquest_Label"],
            note       = L["PvP_Conquest_Note"],
        },
        {
            key        = "bloody_tokens",
            currencyId = CURRENCY_BLOODY_TOKEN,
            max        = BLOODY_TOKEN_CAP,
            label      = L["PvP_BloodyTokens_Label"],
            note       = L["PvP_BloodyTokens_Note"],
        },
    },
})

MR:RegisterModule({
    key         = "pvp_weeklies",
    label       = L["PvP_WeekliesTitle"],
    labelColor  = "#cc3333",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key      = "sparks_of_war",
            label    = L["PvP_Sparks_Label"],
            max      = 1,
            note     = L["PvP_Sparks_Note"],
            questIds = { QUEST_SPARKS_ZULAMAN, QUEST_SPARKS_HARANDAR, QUEST_SPARKS_VOIDSTORM },
            tooltipFunc = function(tip)
                local variants = {
                    { quest = QUEST_SPARKS_ZULAMAN,   name = L["PvP_Sparks_ZA"] },
                    { quest = QUEST_SPARKS_HARANDAR,  name = L["PvP_Sparks_Harandar"] },
                    { quest = QUEST_SPARKS_VOIDSTORM, name = L["PvP_Sparks_Voidstorm"] },
                }

                local completedName = nil
                local activeName = nil

                for _, v in ipairs(variants) do
                    if C_QuestLog.IsQuestFlaggedCompleted(v.quest) then
                        completedName = v.name
                        break
                    end
                end

                if not completedName then
                    for _, v in ipairs(variants) do
                        if C_QuestLog.IsOnQuest(v.quest) then
                            activeName = v.name
                            break
                        end
                    end
                end

                tip:AddLine(" ")
                if completedName then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. completedName, 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Sparks"], 1, 1, 1)
                end
            end,
        },
        {
            key      = "preparing_battle",
            label    = L["PvP_Preparing_Label"],
            max      = 1,
            note     = L["PvP_Preparing_Note"],
            questIds = { QUEST_PREPARING_BATTLE },
        },
        {
            key      = "something_different",
            label    = L["PvP_Brawl_Label"],
            max      = 1,
            note     = L["PvP_Brawl_Note"],
            questIds = { QUEST_SOMETHING_DIFFERENT },
        },
        {
            key      = "early_training",
            label    = L["PvP_Training_Label"],
            max      = 1,
            note     = L["PvP_Training_Note"],
            turnInTracked = true,
            questIds = { QUEST_EARLY_TRAINING },
        },
    },
})
