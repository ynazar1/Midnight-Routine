

local LDB     = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local minimapObject = LDB:NewDataObject("MidnightRoutine", {
    type = "launcher",
    text = "MidnightRoutine",
    icon = "Interface\\AddOns\\MidnightRoutine\\Media\\Icon.tga",

    OnClick = function(_, button)
        if button == "LeftButton" then
            if MR.frame then
                if MR.frame:IsShown() then
                    MR.frame:Hide()
                    MR.db.profile.panelOpen = false
                else
                    MR.frame:Show()
                    MR.db.profile.panelOpen = true
                end
            end
        elseif button == "RightButton" then
            if MR.ToggleConfig then MR:ToggleConfig() end
        end
    end,

    OnTooltipShow = function(tt)
        tt:AddLine("|cff2ae7c6Midnight Routine|r", 1, 1, 1)
        tt:AddLine("Left-click: Show / Hide",  0.8, 0.8, 0.8)
        tt:AddLine("Right-click: Options",     0.8, 0.8, 0.8)
        tt:AddLine("/mr minimap — hide this icon", 0.5, 0.5, 0.5)
    end,
})


local mmLoader = CreateFrame("Frame")
mmLoader:RegisterEvent("PLAYER_LOGIN")
mmLoader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()

    if not LDBIcon:IsRegistered("MidnightRoutine") then
        LDBIcon:Register("MidnightRoutine", minimapObject, MR.db.profile.minimap)
    end
end)

function MR:SetMinimapHidden(hide)
    if not self.db then return end
    self.db.profile.minimap.hide = hide and true or false
    if LDBIcon:IsRegistered("MidnightRoutine") then
        if hide then LDBIcon:Hide("MidnightRoutine")
        else         LDBIcon:Show("MidnightRoutine") end
    end
end
