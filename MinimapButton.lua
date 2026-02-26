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
                    MidnightRoutineDB.panelOpen = false
                else
                    MR.frame:Show()
                    MidnightRoutineDB.panelOpen = true
                end
            end
        elseif button == "RightButton" then
            MR:ToggleConfig()
        end
    end,

    OnTooltipShow = function(tt)
        tt:AddLine("|cff2ae7c6Midnight Routine|r", 1, 1, 1)
        tt:AddLine("Left-click: Show / Hide",  0.8, 0.8, 0.8)
        tt:AddLine("Right-click: Options",     0.8, 0.8, 0.8)


    end,
})

local mmLoader = CreateFrame("Frame")
mmLoader:RegisterEvent("ADDON_LOADED")
mmLoader:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= "MidnightRoutine" then return end
    self:UnregisterAllEvents()

    if not MidnightRoutineDB.minimap then
        MidnightRoutineDB.minimap = { hide = false }
    end

    if not LDBIcon:IsRegistered("MidnightRoutine") then
        LDBIcon:Register("MidnightRoutine", minimapObject, MidnightRoutineDB.minimap)
    end

    C_Timer.After(0, function()
        if MidnightRoutineDB.panelOpen == false and MR.frame then
            MR.frame:Hide()
        end
    end)
end)

function MR:SetMinimapHidden(hide)
    if not MidnightRoutineDB or not MidnightRoutineDB.minimap then return end
    MidnightRoutineDB.minimap.hide = hide and true or false
    if LDBIcon:IsRegistered("MidnightRoutine") then
        if hide then
            LDBIcon:Hide("MidnightRoutine")
        else
            LDBIcon:Show("MidnightRoutine")
        end
    end
end
