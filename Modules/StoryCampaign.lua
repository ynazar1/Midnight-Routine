local LE_CAMPAIGN_STATE_COMPLETE = 2

local function GetActiveCampaignIDs()
    local active = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and info.campaignID and info.campaignID > 0 then
            active[info.campaignID] = true
        end
    end
    return active
end

local function ScanCampaign(mod)
    local campaignId = mod._campaignId
    local chapterIds = mod._chapterIds
    if not campaignId or not chapterIds then return end

    local state            = C_CampaignInfo.GetState and C_CampaignInfo.GetState(campaignId)
    local campaignComplete = (state == LE_CAMPAIGN_STATE_COMPLETE)
    local currentChapterId = C_CampaignInfo.GetCurrentChapterID and
                             C_CampaignInfo.GetCurrentChapterID(campaignId)

    local chapterPos = {}
    for i, cid in ipairs(chapterIds) do chapterPos[cid] = i end
    local currentPos = (currentChapterId and chapterPos[currentChapterId]) or (#chapterIds + 1)

    local db = MR.db.char.progress
    if not db[mod.key] then db[mod.key] = {} end

    for i, chapterId in ipairs(chapterIds) do
        local key = "ch_" .. chapterId
        db[mod.key][key] = (campaignComplete or i < currentPos) and 1 or 0
    end
end

local registeredCampaigns = {}

local function RegisterCampaignModules()
    if not C_CampaignInfo then return end
    local ids = C_CampaignInfo.GetAvailableCampaigns and C_CampaignInfo.GetAvailableCampaigns()
    if not ids or #ids == 0 then return end

    table.sort(ids, function(a, b) return a > b end)

    local didRegister = false

    for _, campaignId in ipairs(ids) do
        if not registeredCampaigns[campaignId] then
            local info       = C_CampaignInfo.GetCampaignInfo(campaignId)
            local chapterIds = C_CampaignInfo.GetChapterIDs(campaignId)
            if chapterIds and #chapterIds > 0 then
                local name = (info and info.name) or ("Campaign " .. campaignId)
                local rows = {}
                for _, chapterId in ipairs(chapterIds) do
                    local ch = C_CampaignInfo.GetCampaignChapterInfo(chapterId)
                    if ch and ch.name and ch.name ~= "" then
                        table.insert(rows, {
                            key          = "ch_" .. chapterId,
                            label        = "|cffffff88" .. ch.name .. ":|r",
                            max          = 1,
                            _chapterId   = chapterId,
                            spellTracked = true,
                        })
                    end
                end

                local mod = {
                    key         = "story_" .. campaignId,
                    label       = "Story: " .. name,
                    labelColor  = "#ffff99",
                    resetType   = "never",
                    defaultOpen = true,
                    rows        = rows,
                    _campaignId = campaignId,
                    _chapterIds = chapterIds,
                    onScan      = function(self) ScanCampaign(self) end,

                    isVisible   = function(self)
                        local active = GetActiveCampaignIDs()
                        if not active[self._campaignId] then return false end

                        for id, _ in pairs(active) do
                            if id > self._campaignId then return false end
                        end
                        return true
                    end,
                }

                MR:RegisterModule(mod)
                ScanCampaign(mod)
                registeredCampaigns[campaignId] = true
                didRegister = true
            end
        end
    end

    if MR.RefreshUI then
        MR:RefreshUI()
    end
end


MR:RegisterEvent("PLAYER_LOGIN", function()
    C_Timer.After(0, RegisterCampaignModules)
end)

MR:RegisterBucketEvent({ "QUEST_TURNED_IN", "QUEST_LOG_UPDATE" }, 1, function()
    RegisterCampaignModules()
    for _, mod in ipairs(MR.modules) do
        if mod._campaignId then ScanCampaign(mod) end
    end
    if MR.RefreshUI then MR:RefreshUI() end
end)
