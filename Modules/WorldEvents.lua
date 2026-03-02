local COLOR_DMF = "|cffcc99ff"
local COLOR_TW  = "|cff66ccff"
local COLOR_WB  = "|cffff4444"

local HOLIDAY_DARKMOON_FAIRE = 479

local HOLIDAY_TIMEWALKING = {
    1056,
    1063,
    1326,
    1400,
    1404,
    1500,
}

local function IsHolidayActive(holidayId)
    if not C_DateAndTime or not C_DateAndTime.GetHolidayInfo then return false end
    local info = C_DateAndTime.GetHolidayInfo(holidayId)
    return info ~= nil and info.startTime ~= nil and GetServerTime() >= info.startTime and GetServerTime() <= info.endTime
end

local function IsDarkmoonActive()
    return IsHolidayActive(HOLIDAY_DARKMOON_FAIRE)
end

local function IsTimewalkingActive()
    for _, id in ipairs(HOLIDAY_TIMEWALKING) do
        if IsHolidayActive(id) then return true end
    end
    return false
end

local DARKMOON_PROFESSION_QUESTS = { 29513, 29514, 29515, 29516, 29517, 29518 }

local function ScanDarkmoon(mod)
    local db = MR.db.char.progress
    if not db[mod.key] then db[mod.key] = {} end

    local profDone = 0
    for _, qid in ipairs(DARKMOON_PROFESSION_QUESTS) do
        if C_QuestLog.IsQuestFlaggedCompleted(qid) then
            profDone = profDone + 1
        end
    end
    db[mod.key]["dmf_profession"] = math.min(profDone, 6)

    local function q(qid) return C_QuestLog.IsQuestFlaggedCompleted(qid) and 1 or 0 end
    db[mod.key]["dmf_dungeon"]  = q(29525)
    db[mod.key]["dmf_tonk"]     = q(29520)
    db[mod.key]["dmf_shooting"] = q(29526)
    db[mod.key]["dmf_ring"]     = q(29524)
    db[mod.key]["dmf_cannon"]   = q(29527)
    db[mod.key]["dmf_sword"]    = q(29529)
end

MR:RegisterModule({
    key         = "darkmoon_faire",
    label       = "Darkmoon Faire",
    labelColor  = "#cc99ff",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = IsDarkmoonActive,
    onScan      = ScanDarkmoon,

    rows = {
        {
            key     = "dmf_profession",
            label   = COLOR_DMF .. "Profession Quests:|r",
            max     = 6,
            note    = "One quest per profession — gives 5 skill points each",
            liveKey = "dmf_profession",
        },
        {
            key     = "dmf_dungeon",
            label   = COLOR_DMF .. "Dungeon: A Treatise on Strategy:|r",
            max     = 1,
            note    = "Complete a dungeon while at the Faire",
            liveKey = "dmf_dungeon",
        },
        {
            key     = "dmf_tonk",
            label   = COLOR_DMF .. "Game: Tonk Championship:|r",
            max     = 1,
            note    = "Destroy 30 Tonk targets",
            liveKey = "dmf_tonk",
        },
        {
            key     = "dmf_shooting",
            label   = COLOR_DMF .. "Game: It's Hammer Time:|r",
            max     = 1,
            note    = "Strike the bell 30 times",
            liveKey = "dmf_shooting",
        },
        {
            key     = "dmf_ring",
            label   = COLOR_DMF .. "Game: Ring Toss:|r",
            max     = 1,
            note    = "Toss 3 rings onto the post",
            liveKey = "dmf_ring",
        },
        {
            key     = "dmf_cannon",
            label   = COLOR_DMF .. "Game: He Shoots, He Scores!:|r",
            max     = 1,
            note    = "Launch yourself out of the cannon",
            liveKey = "dmf_cannon",
        },
        {
            key     = "dmf_sword",
            label   = COLOR_DMF .. "Game: Target Toss:|r",
            max     = 1,
            note    = "Hit 3 targets with throwing daggers",
            liveKey = "dmf_sword",
        },
    },
})

local MAPID_ISLE_OF_DORN     = 2248
local MAPID_RINGING_DEEPS    = 2249
local MAPID_HALLOWFALL       = 2255
local MAPID_AZJ_KAHET        = 2346

local function IsInMap(mapId)
    local current = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not current then return false end
    local checked = 0
    while current and checked < 10 do
        if current == mapId then return true end
        local info = C_Map.GetMapInfo(current)
        current = info and info.parentMapID
        checked = checked + 1
    end
    return false
end

MR:RegisterModule({
    key         = "world_bosses",
    label       = "World Boss",
    labelColor  = "#ff4444",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = function()
        return IsInMap(MAPID_ISLE_OF_DORN)
            or IsInMap(MAPID_RINGING_DEEPS)
            or IsInMap(MAPID_HALLOWFALL)
            or IsInMap(MAPID_AZJ_KAHET)
    end,
    rows = {
        {
            key       = "skarmorak",
            label     = COLOR_WB .. "Skarmorak:|r",
            max       = 1,
            note      = "World Boss — Isle of Dorn",
            questIds  = { 78319 },
            isVisible = function() return IsInMap(MAPID_ISLE_OF_DORN) end,
        },
        {
            key       = "aggregation",
            label     = COLOR_WB .. "Aggregation of Horrors:|r",
            max       = 1,
            note      = "World Boss — The Ringing Deeps",
            questIds  = { 83173 },
            isVisible = function() return IsInMap(MAPID_RINGING_DEEPS) end,
        },
        {
            key       = "odalrik",
            label     = COLOR_WB .. "Odalrik:|r",
            max       = 1,
            note      = "World Boss — Hallowfall",
            questIds  = { 80385 },
            isVisible = function() return IsInMap(MAPID_HALLOWFALL) end,
        },
        {
            key       = "echo_forgotten",
            label     = COLOR_WB .. "Echo of the Forgotten:|r",
            max       = 1,
            note      = "World Boss — Azj-Kahet",
            questIds  = { 84446 },
            isVisible = function() return IsInMap(MAPID_AZJ_KAHET) end,
        },
    },
})

MR:RegisterModule({
    key         = "timewalking",
    label       = "Dungeon",
    labelColor  = "#66ccff",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = IsTimewalkingActive,

    rows = {
        {
            key      = "tw_weekly",
            label    = COLOR_TW .. "Timewalking Weekly:|r",
            max      = 1,
            note     = "Complete 5 Timewalking dungeons for the weekly cache",
            questIds = { 40753, 40173, 40786, 40785, 45566, 62786 },
        },
    },
})
