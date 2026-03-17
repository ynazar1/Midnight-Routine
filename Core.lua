local addonName = "MidnightRoutine"

local LibStub  = LibStub
local AceAddon = LibStub("AceAddon-3.0")
local AceDB    = LibStub("AceDB-3.0")
local L        = LibStub("AceLocale-3.0"):GetLocale(addonName)

MR = AceAddon:NewAddon(addonName, "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0")

local DEFAULTS = {
    profile = {
        locked          = false,
        scale           = 1.0,
        frameAlpha      = 1.0,
        hideFramesInInstances = false,
        transparentMode = false,
        width           = 260,
        height          = 400,
        fontSize        = 11,
        minimap         = { hide = false },
        firstSeen       = false,
        position        = { point = "CENTER", x = 0, y = 0 },
        renownOpen          = false,
        raresOpen           = false,
        raresPos            = nil,
        raresLocked         = false,
        raresWidth          = 300,
        raresHeight         = 360,
        raresFontSize       = 9,
        raresShimmer        = true,
        raresHiddenZones    = {},
        raresCompact        = false,
        raresMinimized      = false,
        raresScale          = 1.0,
        raresAlpha          = 1.0,
        raresHideKilled     = false,
        raresColors         = {},
        renownPos           = nil,
        renownLocked        = false,
        renownWidth         = 280,
        renownBarH          = 18,
        renownAlpha         = 1.0,
        renownShowRep       = true,
        renownShowIcons     = true,
        renownShimmer       = true,
        renownHideMaxed     = false,
        renownHiddenFactions = {},
        renownColors         = {},
        renownOrder          = {},
        renownCompact        = false,
        renownScale          = 1.0,
        renownShowLevel      = true,
        renownFontSize       = 9,
        gatheringLocOpen     = false,
        gatheringLocPos      = nil,
        gatheringLocked      = false,
        gatheringWidth       = 350,
        gatheringHeight      = 450,
        gatheringMinimized   = false,
        gatheringAlpha       = 1.0,
        gatheringFontSize    = 9,
        gatheringScale       = 1.0,
        gatheringProfColors  = {},
            gatheringHideCompleted = false,
        headerColors    = {},
        rowColors       = {},
        syncWindowScale     = false,
        syncWindowFontSize  = false,
        peekOnHover         = false,
        characterWindowLayout = false,
        altBoardHiddenCharacters = {},
        altBoardShowHidden = false,
        altBoardCollapsedModules = {},
    },
    char = {
        progress = {},
        lastWeek = 0,
        lastSyncAt = 0,
        manualOverrides = {},
        welcomeSeen = false,
        raresKills = {},
        lastDailyAt = 0,
        hideComplete = true,
        panelOpen    = true,
        modules      = {},
        moduleOrder  = {},
        settingsMigrated = false,
        windowLayout = {},
    },
}

MR.modules     = {}
MR.moduleByKey = {}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function MergeMissing(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return dst
    end

    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = DeepCopy(v)
        elseif type(dst[k]) == "table" and type(v) == "table" then
            MergeMissing(dst[k], v)
        end
    end

    return dst
end

local function IsTableEmpty(t)
    return type(t) ~= "table" or next(t) == nil
end

local function ParseCharacterKey(charKey)
    if type(charKey) ~= "string" then
        return "Unknown", ""
    end

    local name, realm = charKey:match("^(.-)%s%-%s(.+)$")
    if name and realm then
        return name, realm
    end

    return charKey, ""
end

local function CleanAccountLabel(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

local function HasAnyTableValue(t)
    return type(t) == "table" and next(t) ~= nil
end

local function IsAltBoardModule(mod)
    if not mod or not mod.key then
        return false
    end

    if mod.resetType == "weekly" then
        return true
    end

    return mod.key:match("^story_campaign_") ~= nil
end

function MR:RegisterModule(def)
    assert(def.key,   "MR module missing .key")
    assert(def.label, "MR module missing .label")
    assert(def.rows,  "MR module missing .rows")
    table.insert(self.modules, def)
    self.moduleByKey[def.key] = def
    self._orderedModulesCache = nil
end

function MR:GetProgress(moduleKey, rowKey)
    local m = self.db.char.progress[moduleKey]
    return m and m[rowKey] or 0
end

function MR:GetCurrentCharacterKey()
    if self.db and self.db.keys and self.db.keys.char then
        return self.db.keys.char
    end

    local name, realm = UnitFullName and UnitFullName("player")
    if name and realm and realm ~= "" then
        return string.format("%s - %s", name, realm)
    end

    return UnitName and UnitName("player") or "Unknown"
end

function MR:GetWarbandWeeklyData()
    if not (self and self.db and self.db.sv and self.db.sv.char) then
        return {}
    end

    local results = {}
    local currentKey = self:GetCurrentCharacterKey()
    local resetAt = self.GetLastResetTimestamp and self:GetLastResetTimestamp() or 0
    local hiddenChars = (self.db and self.db.profile and self.db.profile.altBoardHiddenCharacters) or {}
    local showHidden = self.db and self.db.profile and self.db.profile.altBoardShowHidden == true

    for charKey, charData in pairs(self.db.sv.char) do
        if type(charData) == "table" and type(charData.progress) == "table" then
            local name, realm = ParseCharacterKey(charKey)
            local lastSyncAt = charData.lastSyncAt or 0
            local stale = resetAt > 0 and lastSyncAt > 0 and lastSyncAt < resetAt
            local hidden = hiddenChars[charKey] == true
            local snapshot = {
                key = charKey,
                name = name,
                realm = realm,
                classFile = charData.classFile,
                isCurrent = (charKey == currentKey),
                stale = stale,
                hidden = hidden,
                lastSyncAt = lastSyncAt,
                lastResetAt = charData.lastResetAt or 0,
                modules = {},
                totalRows = 0,
                doneRows = 0,
                activeRows = 0,
            }

            for _, mod in ipairs(self.modules) do
                if IsAltBoardModule(mod) then
                    local moduleSettings = type(charData.modules) == "table" and charData.modules[mod.key] or nil
                    local moduleEnabled = not (moduleSettings and moduleSettings.enabled == false)
                    local moduleVisible = moduleEnabled and (not mod.isVisible or mod:isVisible())
                    local modProgress = charData.progress[mod.key] or {}
                    local hasLiveProfession = snapshot.isCurrent and mod.profSkillLine and self.playerProfessions and self.playerProfessions[mod.profSkillLine]
                    local hasProfessionData = (not mod.profSkillLine)
                        or hasLiveProfession
                        or HasAnyTableValue(modProgress)
                        or (type(charData.manualOverrides) == "table" and HasAnyTableValue(charData.manualOverrides[mod.key]))
                        or (moduleSettings ~= nil)

                    if moduleVisible and hasProfessionData then
                        local moduleEntry = {
                            key = mod.key,
                            label = CleanAccountLabel(mod.label),
                            color = mod.labelColor or "#ffffff",
                            rows = {},
                            totalRows = 0,
                            doneRows = 0,
                        }

                        for _, row in ipairs(mod.rows) do
                            local rowVisible = (not row.isVisible or row.isVisible())
                            local rowEnabled = not (moduleSettings and moduleSettings.hiddenRows and moduleSettings.hiddenRows[row.key] == false)

                            if rowVisible and rowEnabled then
                                local value = stale and 0 or tonumber(modProgress[row.key]) or 0
                                local maxValue = tonumber(row.max) or 0
                                local complete = (not row.noMax) and maxValue > 0 and value >= maxValue
                                local rowLabel = CleanAccountLabel(row.label)
                                local displayValue

                                if row.countText and not stale then
                                    displayValue = row.countText
                                elseif row.noMax then
                                    displayValue = tostring(value)
                                else
                                    displayValue = string.format("%d / %d", value, maxValue)
                                end

                                table.insert(moduleEntry.rows, {
                                    key = row.key,
                                    label = rowLabel,
                                    value = value,
                                    max = maxValue,
                                    noMax = row.noMax and true or false,
                                    complete = complete,
                                    displayValue = displayValue,
                                    accentLabel = (not stale and (modProgress[row.liveTierLabelKey or ""] or row.vaultLabel)) or nil,
                                    accentColor = (not stale and (modProgress[row.liveTierColorKey or ""] or row.vaultColor)) or nil,
                                })

                                moduleEntry.totalRows = moduleEntry.totalRows + 1
                                snapshot.totalRows = snapshot.totalRows + 1

                                if complete then
                                    moduleEntry.doneRows = moduleEntry.doneRows + 1
                                    snapshot.doneRows = snapshot.doneRows + 1
                                elseif value > 0 then
                                    snapshot.activeRows = snapshot.activeRows + 1
                                end
                            end
                        end

                        if moduleEntry.totalRows > 0 and (mod.resetType == "weekly" or moduleEntry.doneRows < moduleEntry.totalRows) then
                            table.insert(snapshot.modules, moduleEntry)
                        end
                    end
                end
            end

            if snapshot.totalRows > 0 and ((showHidden and hidden) or ((not showHidden) and (not hidden))) then
                table.insert(results, snapshot)
            end
        end
    end

    table.sort(results, function(a, b)
        if a.isCurrent ~= b.isCurrent then
            return a.isCurrent
        end
        if a.stale ~= b.stale then
            return not a.stale
        end
        if a.doneRows ~= b.doneRows then
            return a.doneRows > b.doneRows
        end
        if a.realm ~= b.realm then
            return a.realm < b.realm
        end
        return a.name < b.name
    end)

    return results
end

function MR:IsAltBoardCharacterHidden(charKey)
    if not (self and self.db and self.db.profile and charKey) then
        return false
    end

    return self.db.profile.altBoardHiddenCharacters
        and self.db.profile.altBoardHiddenCharacters[charKey] == true
        or false
end

function MR:SetAltBoardCharacterHidden(charKey, hidden)
    if not (self and self.db and self.db.profile and charKey) then
        return
    end

    if not self.db.profile.altBoardHiddenCharacters then
        self.db.profile.altBoardHiddenCharacters = {}
    end

    if hidden then
        self.db.profile.altBoardHiddenCharacters[charKey] = true
    else
        self.db.profile.altBoardHiddenCharacters[charKey] = nil
    end
end

function MR:SetProgress(moduleKey, rowKey, value, maxVal)
    if not self.db.char.progress[moduleKey] then
        self.db.char.progress[moduleKey] = {}
    end
    self.db.char.progress[moduleKey][rowKey] = math.max(0, math.min(value, maxVal))
    self:RefreshUI()
end

function MR:ApplyScaleToAll(v)
    self.db.profile.scale          = v
    self.db.profile.raresScale     = v
    self.db.profile.renownScale    = v
    self.db.profile.gatheringScale = v
    if self.frame then self.frame:SetScale(v) end
    local rf = self.raresFrame
    if rf and rf:IsShown() then rf:SetScale(v) end
    local rnf = self.renownFrame
    if rnf and rnf:IsShown() then rnf:SetScale(v) end
    local gf = self.gatheringLocationsFrame
    if gf and gf:IsShown() then gf:SetScale(v) end
    if self.detachedFrames then
        for _, frame in pairs(self.detachedFrames) do
            frame:SetScale(v)
        end
    end
    if self.RepopulateRaresConfig     then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig    then self:RepopulateRenownConfig() end
    if self.RepopulateConfigFrame     then self:RepopulateConfigFrame() end
end

function MR:ApplyFontSizeToAll(v)
    self.db.profile.fontSize          = v
    self.db.profile.raresFontSize     = v
    self.db.profile.gatheringFontSize = v
    self.db.profile.renownFontSize    = v
    if self.ApplyFontSize then self.ApplyFontSize(v) end
    if self.RebuildRaresFrame             then self:RebuildRaresFrame() end
    if self.RebuildGatheringLocationsFrame then self:RebuildGatheringLocationsFrame() end
    if self.RebuildRenownFrame            then self:RebuildRenownFrame() end
    if self.RepopulateRaresConfig     then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig    then self:RepopulateRenownConfig() end
    if self.RepopulateConfigFrame     then self:RepopulateConfigFrame() end
end

function MR:BumpProgress(moduleKey, rowKey, delta, maxVal)
    self:SetProgress(moduleKey, rowKey, self:GetProgress(moduleKey, rowKey) + delta, maxVal)
end

local function CleanDisplayLabel(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end
    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

function MR:SetWaypoint(target)
    local mapID = target and target.zone
    local x = target and target.x and (target.x / 100)
    local y = target and target.y and (target.y / 100)
    local tomTom = _G and rawget(_G, "TomTom")

    if not mapID or not x or not y then
        return false, "Invalid coordinates"
    end

    local title = target.waypointTitle or CleanDisplayLabel(target.label)

    if tomTom and tomTom.AddWaypoint then
        local ok = pcall(function()
            tomTom:AddWaypoint(mapID, x, y, {
                title = title,
                persistent = false,
                minimap = true,
                world = true,
            })
        end)
        if ok then return true, "TomTom" end
    end

    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if point then
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
            return true, "Blizzard" end
    end

    return false, "No waypoint API available"
end

function MR:GetManualOverride(modKey, rowKey)
    local m = self.db.char.manualOverrides
    return (m and m[modKey] and m[modKey][rowKey]) or 0
end

function MR:SetManualOverride(modKey, rowKey, val, maxVal)
    if not self.db.char.manualOverrides then self.db.char.manualOverrides = {} end
    if not self.db.char.manualOverrides[modKey] then self.db.char.manualOverrides[modKey] = {} end
    if val <= 0 then
        self.db.char.manualOverrides[modKey][rowKey] = nil
        self:SetProgress(modKey, rowKey, 0, maxVal or 1)
        self:Scan()
    else
        self.db.char.manualOverrides[modKey][rowKey] = maxVal and math.min(val, maxVal) or val
        self:SetProgress(modKey, rowKey, self.db.char.manualOverrides[modKey][rowKey], maxVal)
    end
end

function MR:GetOrderedModules()
    if self._orderedModulesCache then return self._orderedModulesCache end
    local saved = self.db.char.moduleOrder
    if not saved or #saved == 0 then
        self._orderedModulesCache = self.modules
        return self.modules
    end
    local result, seen = {}, {}
    for _, mod in ipairs(self.modules) do seen[mod.key] = mod end
    for _, key in ipairs(saved) do
        if seen[key] then table.insert(result, seen[key]); seen[key] = nil end
    end
    for _, mod in ipairs(self.modules) do
        if seen[mod.key] then table.insert(result, mod) end
    end
    self._orderedModulesCache = result
    return result
end

function MR:SetModuleOrder(orderedKeys)
    self.db.char.moduleOrder  = orderedKeys
    self._orderedModulesCache = nil
end

function MR:IsModuleEnabled(key)
    local mod = self.moduleByKey[key]
    if mod and mod.profSkillLine and not self.playerProfessions[mod.profSkillLine] then
        return false
    end
    local s = self.db.char.modules[key]
    return not (s and s.enabled == false)
end

function MR:IsModuleOpen(key)
    local s = self.db.char.modules[key]
    if s == nil then
        local mod = self.moduleByKey[key]
        return not mod or mod.defaultOpen ~= false
    end
    return s.open ~= false
end

function MR:IsModuleDetached(key)
    local s = self.db.char.modules[key]
    return s and s.detached == true or false
end

function MR:SetModuleOpen(key, open)
    if not self.db.char.modules[key] then self.db.char.modules[key] = {} end
    self.db.char.modules[key].open = open
end

function MR:SetModuleDetached(key, detached)
    if not self.db.char.modules[key] then self.db.char.modules[key] = {} end
    self.db.char.modules[key].detached = detached and true or false
end

function MR:GetDetachedModulePosition(key)
    local s = self.db.char.modules[key]
    return s and s.detachedPos or nil
end

function MR:SetDetachedModulePosition(key, point, relPoint, x, y)
    if not self.db.char.modules[key] then self.db.char.modules[key] = {} end
    self.db.char.modules[key].detachedPos = {
        point = point,
        relPoint = relPoint,
        x = x,
        y = y,
    }
end

function MR:GetDetachedModuleSize(key)
    local s = self.db.char.modules[key]
    return s and s.detachedSize or nil
end

function MR:SetDetachedModuleSize(key, width, height)
    if not self.db.char.modules[key] then self.db.char.modules[key] = {} end
    self.db.char.modules[key].detachedSize = {
        width = width,
        height = height,
    }
end

function MR:SetModuleEnabled(key, enabled)
    if not self.db.char.modules[key] then self.db.char.modules[key] = {} end
    self.db.char.modules[key].enabled = enabled
    self:RefreshUI()
end

function MR:IsModuleHideComplete(modKey)
    local s = self.db.char.modules[modKey]
    if s and s.hideComplete ~= nil then return s.hideComplete end
    return self.db.char.hideComplete
end

function MR:SetModuleHideComplete(modKey, value)
    if not self.db.char.modules[modKey] then self.db.char.modules[modKey] = {} end
    self.db.char.modules[modKey].hideComplete = value
    self:RefreshUI()
end

function MR:IsRowEnabled(modKey, rowKey)
    local s = self.db.char.modules[modKey]
    if not s or not s.hiddenRows then return true end
    return s.hiddenRows[rowKey] ~= false
end

function MR:SetRowEnabled(modKey, rowKey, enabled)
    if not self.db.char.modules[modKey] then self.db.char.modules[modKey] = {} end
    if not self.db.char.modules[modKey].hiddenRows then
        self.db.char.modules[modKey].hiddenRows = {}
    end
    self.db.char.modules[modKey].hiddenRows[rowKey] = enabled and true or false
end

function MR:IsCharacterWindowLayoutEnabled()
    return self.db and self.db.profile and self.db.profile.characterWindowLayout == true
end

function MR:GetWindowLayoutValue(key)
    if not (self and self.db and key) then return nil end

    if self:IsCharacterWindowLayoutEnabled() then
        local charLayout = self.db.char and self.db.char.windowLayout
        if charLayout and charLayout[key] ~= nil then
            return charLayout[key]
        end
    end

    return self.db.profile[key]
end

function MR:SetWindowLayoutValue(key, value)
    if not (self and self.db and key) then return end

    if self:IsCharacterWindowLayoutEnabled() then
        if not self.db.char.windowLayout then
            self.db.char.windowLayout = {}
        end
        self.db.char.windowLayout[key] = value
    else
        self.db.profile[key] = value
    end
end

function MR:GetHeaderColor(modKey)
    if self.db.profile.headerColors and self.db.profile.headerColors[modKey] then
        return self.db.profile.headerColors[modKey]
    end
    local mod = self.moduleByKey[modKey]
    return mod and mod.labelColor or "#ffffff"
end

function MR:SetHeaderColor(modKey, hexColor)
    if not self.db.profile.headerColors then
        self.db.profile.headerColors = {}
    end
    self.db.profile.headerColors[modKey] = hexColor
    self:RefreshUI()
    self:RepopulateConfigFrame()
end

function MR:ResetHeaderColor(modKey)
    if self.db.profile.headerColors then
        self.db.profile.headerColors[modKey] = nil
    end
    self:RefreshUI()
end

function MR:GetRowColor(modKey, rowKey)
    local p = self.db.profile.rowColors
    if p and p[modKey] and p[modKey][rowKey] then
        return p[modKey][rowKey]
    end
end

function MR:SetRowColor(modKey, rowKey, hexColor)
    if not self.db.profile.rowColors then self.db.profile.rowColors = {} end
    if not self.db.profile.rowColors[modKey] then self.db.profile.rowColors[modKey] = {} end
    self.db.profile.rowColors[modKey][rowKey] = hexColor
    self:RefreshUI()
    self:RepopulateConfigFrame()
end

function MR:ResetRowColor(modKey, rowKey)
    local p = self.db.profile.rowColors
    if p and p[modKey] then
        p[modKey][rowKey] = nil
    end
    self:RefreshUI()
    self:RepopulateConfigFrame()
end

local PARENT_TO_MIDNIGHT = {
    [171]=2906, [164]=2907, [333]=2909, [202]=2910, [182]=2912,
    [773]=2913, [755]=2914, [165]=2915, [186]=2916, [393]=2917, [197]=2918,
}

MR.playerProfessions = MR.playerProfessions or {}

function MR:RefreshPlayerProfessions()
    wipe(self.playerProfessions)
    if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local lines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        if lines then
            for _, skillLineID in ipairs(lines) do
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID and
                             C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                if info and (info.skillLevel or 0) > 0 then
                    self.playerProfessions[skillLineID] = true
                    if info.parentProfessionID then
                        local mid = PARENT_TO_MIDNIGHT[info.parentProfessionID]
                        if mid then self.playerProfessions[mid] = true end
                    end
                end
            end
        end
    end
    for _, idx in ipairs({ GetProfessions() }) do
        if idx then
            local _, _, _, _, _, _, parentSkillLine = GetProfessionInfo(idx)
            if parentSkillLine then
                local mid = PARENT_TO_MIDNIGHT[parentSkillLine]
                if mid then self.playerProfessions[mid] = true end
            end
        end
    end
end

local spellIndex = {}

function MR:BuildSpellIndex()
    wipe(spellIndex)
    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.spellId then
                spellIndex[row.spellId] = {
                    modKey = mod.key,
                    rowKey = row.key,
                    amount = row.spellAmount or 1,
                    max    = row.max or 1,
                }
            end
        end
    end
end

local function WriteProgress(progress, modKey, rowKey, val, overrides)
    if not progress[modKey] then progress[modKey] = {} end
    if overrides and overrides[modKey] then
        local mo = overrides[modKey][rowKey]
        if mo and mo > val then val = mo end
    end
    if progress[modKey][rowKey] == val then return false end
    progress[modKey][rowKey] = val
    return true
end

function MR:Scan()
    if self._scanSuppressedUntil and GetTime() < self._scanSuppressedUntil then
        return
    end

    self.db.char.lastSyncAt = GetServerTime()

    local progress = self.db.char.progress
    local dirty    = false

    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.questIds then
                local done = 0
                for _, qid in ipairs(row.questIds) do
                    if C_QuestLog.IsQuestFlaggedCompleted(qid) then done = done + 1 end
                end
                if WriteProgress(progress, mod.key, row.key, math.min(done, row.max or done), self.db.char.manualOverrides) then
                    dirty = true
                end
            end
            if row.currencyId then
                local info = C_CurrencyInfo.GetCurrencyInfo(row.currencyId)
                if info then
                    local wallet  = info.quantity or 0
                    local weekly  = info.quantityEarnedThisWeek or 0
                    local weeklyCap = (info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0)
                                      and info.maxWeeklyQuantity or nil
                    local dynamicCap = nil
                    local raw = wallet

                    if info.maxQuantity and info.maxQuantity > 0 then
                        dynamicCap = info.maxQuantity
                        if info.useTotalEarnedForMaxQty and info.totalEarned ~= nil then
                            raw = info.totalEarned
                        else
                            raw = wallet
                        end
                    elseif weeklyCap then
                        dynamicCap = weeklyCap
                        raw = weekly
                    end

                    if dynamicCap and row.max ~= dynamicCap then
                        row.max = dynamicCap
                        dirty = true
                    end

                    if not progress[mod.key] then progress[mod.key] = {} end
                    local walletKey = row.key .. "_wallet"
                    if progress[mod.key][walletKey] ~= wallet then
                        progress[mod.key][walletKey] = wallet
                        dirty = true
                    end

                    local val = row.noMax and raw or math.min(raw, row.max or raw)
                    if WriteProgress(progress, mod.key, row.key, val, self.db.char.manualOverrides) then dirty = true end
                end
            end
            if row.itemId then
                local count = 0
                if C_Item and C_Item.GetItemCount then
                    count = C_Item.GetItemCount(row.itemId, false, false, true) or 0
                elseif GetItemCount then
                    count = GetItemCount(row.itemId, false, false) or 0
                end

                if WriteProgress(progress, mod.key, row.key, row.noMax and count or math.min(count, row.max or count), self.db.char.manualOverrides) then
                    dirty = true
                end
            end
        end

        if mod.onScan then
            local before = progress[mod.key] and next(progress[mod.key])
            mod.onScan(mod)
            if progress[mod.key] and next(progress[mod.key]) ~= before then dirty = true end
        end

        local mdb = progress[mod.key]
        if mdb then
            for _, row in ipairs(mod.rows) do
                if row.liveKey and row.liveKey ~= row.key and mdb[row.liveKey] ~= nil then
                    local capped = row.noMax and mdb[row.liveKey] or math.min(mdb[row.liveKey], row.max)
                    local _ov = self.db.char.manualOverrides
                    if _ov and _ov[mod.key] then
                        local mo = _ov[mod.key][row.key]
                        if mo and mo > capped then capped = mo end
                    end
                    if mdb[row.key] ~= capped then mdb[row.key] = capped; dirty = true end
                end
                if row.liveTierLabelKey then
                    row.vaultLabel = mdb[row.liveTierLabelKey]
                end
                if row.liveTierColorKey then
                    row.vaultColor = mdb[row.liveTierColorKey]
                end
            end
        end
    end

    if dirty then self:RefreshUI() end
    if self.SyncAllRareKills then self:SyncAllRareKills() end
    if self.RefreshRares  then self:RefreshRares()  end
    if self.RefreshRenown then self:RefreshRenown() end
end

local TURN_IN_COMPLETIONS = {
    [89268] = { mod = "s1_weekly",           row = "lost_legends"        },
    [89289] = { mod = "s1_weekly",           row = "saltherils_soiree"   },
    [93889] = { mod = "s1_weekly",           row = "saltherils_soiree"   },
    [91966] = { mod = "s1_weekly",           row = "saltherils_soiree"   },
    [90573] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90574] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90575] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90576] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [93744] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [93909] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [93911] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [93912] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [93910] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [90962] = { mod = "midnight_activities", row = "stormarion_assault"  },
    [94835] = { mod = "pvp_weeklies",        row = "early_training"      },
}

local WEEKLY_RESET_SCHEDULE = {
    [1] = { weekday = 3, hour = 3 }, 
    [2] = { weekday = 4, hour = 3 }, 
    [3] = { weekday = 3, hour = 3 }, 
    [4] = { weekday = 4, hour = 3 }, 
    [5] = { weekday = 4, hour = 3 }, 
}

function MR:GetLastDailyTimestamp()
    local cal = C_DateAndTime.GetCurrentCalendarTime()
    if not cal then return nil end
    local now = GetServerTime()
    local secondsSinceMidnight = (cal.hour * 3600) + (cal.minute * 60) + (cal.second or 0)
    return now - secondsSinceMidnight
end

function MR:CheckDailyReset()
    local lastDailyAt = self:GetLastDailyTimestamp()
    if not lastDailyAt then return end
    local prevDailyAt = self.db.char.lastDailyAt
    if not prevDailyAt or prevDailyAt == 0 then
        self.db.char.lastDailyAt = lastDailyAt
        return
    end
    if lastDailyAt > prevDailyAt + 300 then
        self:DoDailyReset()
    end
end

function MR:DoDailyReset()
    local ts = self:GetLastDailyTimestamp()
    if ts then self.db.char.lastDailyAt = ts end
    for _, mod in ipairs(self.modules) do
        if mod.resetType == "daily" then
            self.db.char.progress[mod.key] = {}
            if self.db.char.manualOverrides then
                self.db.char.manualOverrides[mod.key] = nil
            end
        end
    end
    self:RefreshUI()
end

function MR:GetLastResetTimestamp()
    local region    = GetCurrentRegion() or 1
    local resetInfo = WEEKLY_RESET_SCHEDULE[region]
    if not resetInfo then return nil end

    local cal = C_DateAndTime.GetCurrentCalendarTime()
    if not cal then return nil end

    local now                 = GetServerTime()
    local secondsSinceMidnight = (cal.hour * 3600) + (cal.minute * 60) + (cal.second or 0)
    local todayReset          = now - secondsSinceMidnight + (resetInfo.hour * 3600)
    local diffDays            = ((cal.weekday - resetInfo.weekday) + 7) % 7
    local candidate           = todayReset - (diffDays * 24 * 3600)

    if candidate > now then candidate = candidate - (7 * 24 * 3600) end

    return candidate
end

function MR:GetCurrentWeekKey()
    return self:GetLastResetTimestamp() or 0
end

function MR:CheckWeeklyReset()
    local lastResetAt = self:GetLastResetTimestamp()
    if not lastResetAt then return end

    local prevResetAt = self.db.char.lastResetAt

    if not prevResetAt then
        self.db.char.lastResetAt = lastResetAt
        return
    end

    if lastResetAt > prevResetAt + 300 then
        self:DoWeeklyReset()
    end
end

function MR:DoWeeklyReset()
    local ts = self:GetLastResetTimestamp()
    if ts then self.db.char.lastResetAt = ts end

    self._scanSuppressedUntil = GetTime() + 15

            for _, mod in ipairs(self:GetOrderedModules()) do
                if mod.resetType == "weekly" then
            self.db.char.progress[mod.key] = {}
            if self.db.char.manualOverrides then
                self.db.char.manualOverrides[mod.key] = nil
            end
        end
    end
    self.db.char.raresKills = {}
    self:RefreshUI()
    self:ScheduleTimer(function() self:Scan() end, 20)
    print(L["Weekly_Reset"])
end

function MR:OnInitialize()
    self.db = AceDB:New("MidnightRoutineDB", DEFAULTS, true)
    self:MigrateLegacySettings()
end

function MR:MigrateLegacySettings()
    local ch = self.db and self.db.char
    local pr = self.db and self.db.profile
    if not ch or not pr or ch.settingsMigrated then
        return
    end

    if IsTableEmpty(ch.modules) and type(pr.modules) == "table" then
        ch.modules = DeepCopy(pr.modules)
    elseif type(pr.modules) == "table" then
        MergeMissing(ch.modules, pr.modules)
    end

    if IsTableEmpty(ch.moduleOrder) and type(pr.moduleOrder) == "table" and #pr.moduleOrder > 0 then
        ch.moduleOrder = DeepCopy(pr.moduleOrder)
    end

    if ch.hideComplete == DEFAULTS.char.hideComplete and pr.hideComplete ~= nil then
        ch.hideComplete = pr.hideComplete
    end

    ch.settingsMigrated = true
end

local INSTANCE_HIDE_TYPES = {
    party = true,
    raid = true,
    arena = true,
    pvp = true,
    scenario = true,
}

function MR:ShouldHideFramesInCurrentInstance()
    if not self.db or not self.db.profile.hideFramesInInstances then return false end
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return false end
    return INSTANCE_HIDE_TYPES[instanceType] == true
end

function MR:CaptureManagedWindowState()
    local detached = {}
    if self.detachedFrames then
        for key, frame in pairs(self.detachedFrames) do
            if frame and frame:IsShown() then
                detached[key] = true
            end
        end
    end

    return {
        panel = self.frame and self.frame:IsShown() or false,
        renown = self.renownFrame and self.renownFrame:IsShown() or false,
        rares = self.raresFrame and self.raresFrame:IsShown() or false,
        gathering = self.gatheringLocationsFrame and self.gatheringLocationsFrame:IsShown() or false,
        detached = detached,
    }
end

function MR:ManagedWindowStateHasVisibleFrames(state)
    if not state then return false end
    return state.panel
        or state.renown
        or state.rares
        or state.gathering
        or (state.detached and next(state.detached) ~= nil)
end

function MR:HideManagedWindows()
    if self.frame then self.frame:Hide() end
    if self.HideDetachedModules then self:HideDetachedModules() end
    if self.HideConfig then self:HideConfig() end
    if self.HideRenown then self:HideRenown(false) end
    if self.HideRares then self:HideRares(false) end
    if self.HideGatheringLocations then self:HideGatheringLocations(false) end
end

function MR:RestoreManagedWindows(state)
    state = state or {}

    if state.panel then
        if not self.frame and self.BuildUI then
            self:BuildUI()
        elseif self.frame then
            self.frame:Show()
        end
    end

    if state.renown and self.EnsureRenownShown then
        self:EnsureRenownShown()
    end
    if state.rares and self.EnsureRaresShown then
        self:EnsureRaresShown()
    end
    if state.gathering and self.EnsureGatheringLocationsShown then
        self:EnsureGatheringLocationsShown()
    end

    if state.detached and self.detachedFrames then
        for key in pairs(state.detached) do
            local frame = self.detachedFrames[key]
            if frame then
                frame:Show()
            end
        end
    end
end

function MR:ToggleManagedWindows()
    if self._instanceFramesHidden then
        return false
    end

    if self._toggleRestoreState then
        self:RestoreManagedWindows(self._toggleRestoreState)
        self._toggleRestoreState = nil
        return true
    end

    local state = self:CaptureManagedWindowState()
    if self:ManagedWindowStateHasVisibleFrames(state) then
        self._toggleRestoreState = state
        self:HideManagedWindows()
        return false
    end

    if not self.frame and self.BuildUI then
        self:BuildUI()
    end
    if self.frame then
        self.frame:Show()
    end
    self.db.char.panelOpen = true
    return true
end

function MR:UpdateInstanceFrameVisibility()
    if not self.db then return end

    local shouldHide = self:ShouldHideFramesInCurrentInstance()
    if shouldHide then
        if self._instanceFramesHidden then return end

        self._instanceFramesHidden = true
        self._instanceRestoreState = self:CaptureManagedWindowState()
        self:HideManagedWindows()
        return
    end

    if not self._instanceFramesHidden then return end

    local state = self._instanceRestoreState or {}
    self._instanceFramesHidden = false
    self._instanceRestoreState = nil

    self:RestoreManagedWindows(state)
end

function MR:OnEnable()
    self:RegisterBucketEvent({
        "QUEST_LOG_UPDATE",
        "UNIT_QUEST_LOG_CHANGED",
        "QUEST_TURNED_IN",
        "LFG_COMPLETION_REWARD",
        "CURRENCY_DISPLAY_UPDATE",
        "AREA_POIS_UPDATED",
    }, 1, "Scan")

    self:RegisterBucketEvent({
        "SKILL_LINES_CHANGED",
        "TRADE_SKILL_LIST_UPDATE",
        "SKILL_LINE_SPECS_RANKS_CHANGED",
        "TRADE_SKILL_SHOW",
    }, 1, "OnProfessionChange")

    self:RegisterBucketEvent({
        "ZONE_CHANGED_NEW_AREA",
    }, 0.5, "OnZoneChanged")

    self:RegisterBucketEvent({
        "CHALLENGE_MODE_COMPLETED",
        "WEEKLY_REWARDS_UPDATE",
    }, 1, "OnVaultEvent")

    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellCast")
    self:RegisterEvent("ENCOUNTER_END",            "OnEncounterEnd")
    self:RegisterEvent("PLAYER_ENTERING_WORLD",    "OnEnteringWorld")

    self:ScheduleRepeatingTimer("CheckWeeklyReset", 60)
    self:ScheduleRepeatingTimer("CheckDailyReset",  60)

    if not self._questTurnInFrame then
        local addon = self
        local f = CreateFrame("Frame")
        f:RegisterEvent("QUEST_TURNED_IN")
        f:SetScript("OnEvent", function(_, _, questID)
            local entry = TURN_IN_COMPLETIONS[questID]
            if not entry or not addon.db then return end
            local ch = addon.db.char
            if not ch.progress[entry.mod] then ch.progress[entry.mod] = {} end
            ch.progress[entry.mod][entry.row] = 1
            addon:RefreshUI()
        end)
        self._questTurnInFrame = f
    end
end

function MR:OnEnteringWorld()
    local _, classFile = UnitClass("player")
    if classFile then
        self.db.char.classFile = classFile
    end
    self.db.char.lastSyncAt = GetServerTime()
    self:RefreshPlayerProfessions()
    self:BuildSpellIndex()
    local temporarilyHidden = self._toggleRestoreState ~= nil

    if not self.db.profile.firstSeen then
        self.db.char.panelOpen     = false
        self.db.profile.renownOpen = false
    end

    if not self.frame then
        self:BuildUI()
    else
        self:RefreshUI()
    end
    if self.frame and self.db.char.panelOpen == false then
        self.frame:Hide()
    end
    if temporarilyHidden then
        self:HideManagedWindows()
    end

    self:UpdateInstanceFrameVisibility()
    local shouldHideFrames = self._instanceFramesHidden == true

    self:MaybeShowWelcomeScreen()
    if self.OnRenownUpdate then
        self:RegisterBucketEvent({
            "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
            "UPDATE_FACTION",
            "COMBAT_TEXT_UPDATE",
        }, 1, "OnRenownUpdate")
    end
    if not shouldHideFrames and not temporarilyHidden and self.db.profile.renownOpen and self.EnsureRenownShown then
        self:ScheduleTimer(function() self:EnsureRenownShown() end, 1.5)
    end
    if not shouldHideFrames and not temporarilyHidden and self.db.profile.raresOpen and self.EnsureRaresShown then
        self:ScheduleTimer(function() self:EnsureRaresShown() end, 1.7)
    end
    if not shouldHideFrames and not temporarilyHidden and self.db.profile.gatheringLocOpen and self.EnsureGatheringLocationsShown then
        self:ScheduleTimer(function() self:EnsureGatheringLocationsShown() end, 1.9)
    end
    if self.db.profile.peekOnHover and self.ApplyPeekOnHover then
        self:ScheduleTimer(function() self:ApplyPeekOnHover(true) end, 2.5)
    end
    self:ScheduleTimer(function()
        self:CheckWeeklyReset()
        self:CheckDailyReset()
        self:RefreshPlayerProfessions()
        self:RefreshUI()
        self:UpdateInstanceFrameVisibility()
        if self.RefreshGatheringLocationsFrame then
            self:RefreshGatheringLocationsFrame()
        end
    end, 0.5)
    self:ScheduleTimer(function() self:Scan() end, 5)
    self:Scan()
end

function MR:OnProfessionChange()
    self:RefreshPlayerProfessions()
    self:RefreshUI()
    if self.RefreshGatheringLocationsFrame then
        self:RefreshGatheringLocationsFrame()
    end
end

function MR:OnSpellCast(_, unit, _, spellID)
    if unit ~= "player" then return end
    local entry = spellIndex[spellID]
    if not entry then return end
    self:BumpProgress(entry.modKey, entry.rowKey, entry.amount, entry.max)
end

function MR:OnVaultEvent()
    self:ScheduleTimer(function() self:Scan() end, 1.5)
end

function MR:OnZoneChanged()
    self:UpdateInstanceFrameVisibility()
    self:Scan()
    self:RefreshUI()
    if self.OnRaresZoneChanged then
        self:OnRaresZoneChanged()
    end
end

function MR:OnEncounterEnd(_, _, _, _, _, success)
    if success == 1 then
        self:ScheduleTimer(function() self:Scan() end, 1.5)
    end
end

SLASH_MIDROUTE1 = "/mr"
SLASH_MIDROUTE2 = "/midroute"
SlashCmdList["MIDROUTE"] = function(msg)
    msg = (msg or ""):lower():trim()
    local function ApplyMainScale(value)
        if MR.db.profile.syncWindowScale and MR.ApplyScaleToAll then
            MR:ApplyScaleToAll(value)
        else
            MR.db.profile.scale = value
            if MR.frame then MR.frame:SetScale(value) end
        end
    end

    if     msg == "reset"   then MR:DoWeeklyReset()
    elseif msg == "lock"    then
        MR.db.profile.locked = true
        if MR.frame then MR.frame:SetMovable(false) end
        print(L["Frame_Locked"])
    elseif msg == "unlock"  then
        MR.db.profile.locked = false
        if MR.frame then MR.frame:SetMovable(true) end
        print(L["Frame_Unlocked"])
    elseif msg == "hide"    then
        if MR.frame then MR.frame:Hide() end
        MR.db.char.panelOpen = false
    elseif msg == "show"    then
        if MR.frame then MR.frame:Show() end
        MR.db.char.panelOpen = true
    elseif msg == "toggle"  then
        MR:ToggleManagedWindows()
    elseif msg == "main" or msg == "main toggle" then
        if not MR.frame and MR.BuildUI then
            MR:BuildUI()
        end
        if MR.frame then
            if MR.frame:IsShown() then
                MR.frame:Hide()
                MR.db.char.panelOpen = false
            else
                MR.frame:Show()
                MR.db.char.panelOpen = true
            end
        end
    elseif msg == "main show" then
        if not MR.frame and MR.BuildUI then
            MR:BuildUI()
        end
        if MR.frame then MR.frame:Show() end
        MR.db.char.panelOpen = true
    elseif msg == "main hide" then
        if MR.frame then MR.frame:Hide() end
        MR.db.char.panelOpen = false
    elseif msg == "minimap" then
        local newHide = not (MR.db.profile.minimap and MR.db.profile.minimap.hide)
        MR:SetMinimapHidden(newHide)
        if newHide then
            print(L["Minimap_Hidden"])
        else
            print(L["Minimap_Shown"])
        end
    elseif msg == "scale" or msg == "scale toggle" then
        local current = tonumber(MR.db.profile.scale) or 1.0
        local target = math.abs(current - 0.5) < 0.001 and 2.0 or 0.5
        ApplyMainScale(target)
    elseif msg:match("^scale %d") then
        local s = tonumber(msg:match("scale (%S+)"))
        if s and s >= 0.5 and s <= 2 then
            ApplyMainScale(s)
        end
    elseif msg == "big"   then if MR.ApplyWidth then MR.ApplyWidth(500) end
    elseif msg == "small"   then if MR.ApplyWidth then MR.ApplyWidth(200) end
    elseif msg == "welcome" then MR:ShowWelcomeScreen()
    elseif msg == "renown"  then MR:ToggleRenown()
    elseif msg == "renown config" then MR:ToggleRenownConfig()
    elseif msg == "rares"   then MR:ToggleRares()
    elseif msg == "rares config" then MR:ToggleRaresConfig()
    elseif msg == "gathering" then MR:ToggleGatheringLocations()
    elseif msg == "sa debug" or msg == "sa_debug" then
        if MR.DebugSpecialAssignments then
            MR:DebugSpecialAssignments()
        end
    elseif msg == "dmf" then
        MR.debugDMF = not MR.debugDMF
        if MR.debugDMF then
            print("|cffcc99ff[MidnightRoutine]|r Darkmoon Faire test mode ON — module forced visible")
        else
            print("|cffcc99ff[MidnightRoutine]|r Darkmoon Faire test mode OFF")
        end
        MR:RefreshUI()
    else
        print(L["Chat_Commands"])
    end
end
