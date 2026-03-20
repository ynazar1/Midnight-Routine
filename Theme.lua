local _, ns = ...

local function ResolveDefaultFont()
    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end

    if GameFontNormal and GameFontNormal.GetFont then
        local font = GameFontNormal:GetFont()
        if type(font) == "string" and font ~= "" then
            return font
        end
    end

    return "Fonts\\FRIZQT__.TTF"
end

function ns.EnsureFonts()
    local defaultFont = ResolveDefaultFont()

    if type(ns.FONT_HEADERS) ~= "string" or ns.FONT_HEADERS == "" then
        ns.FONT_HEADERS = defaultFont
    end

    if type(ns.FONT_ROWS) ~= "string" or ns.FONT_ROWS == "" then
        ns.FONT_ROWS = defaultFont
    end

    return ns.FONT_HEADERS, ns.FONT_ROWS
end

ns.EnsureFonts()
ns.BACKDROP_FILE = "Interface\\Buttons\\WHITE8X8"

ns.COLORS = {
    complete = { 0, 1, 0.59 },
    half = { 1, 0.47, 0 },
    incomplete = { 0.6, 0.6, 0.6 },
    bg = { 0.02, 0.03, 0.07, 0.96 },
    accent = { 0.85, 0.65, 0.10 },
    border = { 0.15, 0.15, 0.20 },
    titlebar = { 0.05, 0.12, 0.22 },
}

local COLORS = ns.COLORS

function ns.Hex(h)
    h = h:gsub("#", "")
    return tonumber(h:sub(1, 2), 16) / 255,
        tonumber(h:sub(3, 4), 16) / 255,
        tonumber(h:sub(5, 6), 16) / 255
end

function ns.WrapColor(rrggbb, text)
    return string.format("|cff%s%s|r", rrggbb, text)
end

function ns.CountColor(done, max)
    if done >= max then
        return COLORS.complete[1], COLORS.complete[2], COLORS.complete[3]
    elseif done > 0 then
        return COLORS.half[1], COLORS.half[2], COLORS.half[3]
    end

    return COLORS.incomplete[1], COLORS.incomplete[2], COLORS.incomplete[3]
end

function ns.SetDotColor(tex, done, max)
    if done >= max then
        tex:SetColorTexture(COLORS.complete[1], COLORS.complete[2], COLORS.complete[3], 1)
    elseif done > 0 then
        tex:SetColorTexture(COLORS.half[1], COLORS.half[2], COLORS.half[3], 1)
    else
        tex:SetColorTexture(0.3, 0.3, 0.3, 1)
    end
end

ns.LOCALE_SETTINGS = ns.LOCALE_SETTINGS or {
    zhCN = { fontSizeMin = 13, fontSizeDefault = 13 },
    zhTW = { fontSizeMin = 13, fontSizeDefault = 13 },
    koKR = { fontSizeMin = 13, fontSizeDefault = 13 },
}

local localeSettings = (ns.LOCALE_SETTINGS or {})[GetLocale()] or {}
local fontSizeMin = localeSettings.fontSizeMin or 7
local fontSizeDefault = localeSettings.fontSizeDefault or 11

function ns.GetFontSize()
    local addon = ns.MR
    local size

    if addon and addon.db and addon.db.profile and addon.db.profile.fontSize then
        size = addon.db.profile.fontSize
    else
        size = fontSizeDefault
    end

    if size < fontSizeMin then
        size = fontSizeMin
    end

    return size
end

function ns.MakeBackdrop(edge)
    if edge == false then
        return { bgFile = ns.BACKDROP_FILE }
    end

    return {
        bgFile = ns.BACKDROP_FILE,
        edgeFile = ns.BACKDROP_FILE,
        edgeSize = 1,
    }
end

function ns.StyledFrame(parent, name, strata, level)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    frame:SetFrameStrata(strata or "MEDIUM")
    frame:SetFrameLevel(level or 10)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetBackdrop(ns.MakeBackdrop())
    frame:SetBackdropColor(COLORS.bg[1], COLORS.bg[2], COLORS.bg[3], COLORS.bg[4])
    frame:SetBackdropBorderColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], 1)
    return frame
end

function ns.TopAccent(parent, r, g, b)
    r, g, b = r or COLORS.accent[1], g or COLORS.accent[2], b or COLORS.accent[3]
    local tex = parent:CreateTexture(nil, "BORDER")
    tex:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    tex:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    tex:SetHeight(2)
    tex:SetColorTexture(r, g, b, 1)
    return tex
end

function ns.LeftAccent(parent, r, g, b)
    r, g, b = r or COLORS.accent[1], g or COLORS.accent[2], b or COLORS.accent[3]
    local tex = parent:CreateTexture(nil, "BORDER")
    tex:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    tex:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    tex:SetWidth(3)
    tex:SetColorTexture(r, g, b, 1)
    return tex
end

function ns.TitleBar(parent, height)
    height = height or 36
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(height)
    bar:SetBackdrop(ns.MakeBackdrop(false))
    bar:SetBackdropColor(COLORS.titlebar[1], COLORS.titlebar[2], COLORS.titlebar[3], 1)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    return bar
end

function ns.CloseButton(parent, onClose)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(16, 16)
    btn:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
    btn:SetBackdrop(ns.MakeBackdrop())
    btn:SetBackdropColor(0.12, 0.04, 0.04, 1)
    btn:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(ns.FONT_HEADERS, 11, "OUTLINE")
    lbl:SetPoint("CENTER", btn, "CENTER", 0, 1)
    lbl:SetText("x")
    lbl:SetTextColor(0.75, 0.28, 0.28)

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.35, 0.06, 0.06, 1)
        btn:SetBackdropBorderColor(0.90, 0.25, 0.25, 1)
        lbl:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.12, 0.04, 0.04, 1)
        btn:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)
        lbl:SetTextColor(0.75, 0.28, 0.28)
    end)

    if onClose then
        btn:SetScript("OnClick", onClose)
    end

    return btn
end

function ns.SaveFramePos(frame, key)
    local addon = ns.MR
    if not addon or not addon.db then
        return
    end

    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = frame:GetPoint()
        addon.db.profile[key] = { point = point, relPoint = relPoint, x = x, y = y }
    end)
end

function ns.RestoreFramePos(frame, key, defaultX, defaultY)
    local addon = ns.MR
    if addon and addon.db and addon.db.profile[key] then
        local pos = addon.db.profile[key]
        frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x, pos.y)
        return
    end

    frame:SetPoint("CENTER", UIParent, "CENTER", defaultX or 0, defaultY or 0)
end

function ns.OptionsGap(body, yOff, height)
    return yOff - (height or 4)
end

function ns.OptionsDivider(body, yOff, pad)
    pad = pad or 8
    local frame = CreateFrame("Frame", nil, body, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
    frame:SetHeight(1)
    frame:SetBackdrop(ns.MakeBackdrop(false))
    frame:SetBackdropColor(1, 1, 1, 0.07)
    return yOff - 6
end

function ns.OptionsSectionLabel(body, yOff, text, pad, fontSize)
    pad = pad or 8
    local fs = body:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ns.FONT_ROWS, fontSize or 9, "OUTLINE")
    fs:SetText("|cff888888" .. text .. "|r")
    fs:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    fs:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return yOff - 14
end

function ns.OptionsCheckbox(body, yOff, label, getVal, setVal, r, g, b, pad, onRefresh, fontSize)
    pad = pad or 8
    local frame = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
    frame:SetSize(20, 20)
    frame:SetPoint("TOPLEFT", body, "TOPLEFT", pad - 2, yOff)
    frame:SetChecked(getVal())
    frame:EnableMouse(true)
    frame:SetScript("OnClick", function(self)
        setVal(self:GetChecked())
        if onRefresh then
            onRefresh()
        end
    end)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(ns.FONT_ROWS, fontSize or 10, "OUTLINE")
    lbl:SetText(label)
    lbl:SetTextColor(r or 0.88, g or 0.88, b or 0.88)
    lbl:SetPoint("LEFT", frame, "RIGHT", 2, 0)
    lbl:SetPoint("RIGHT", body, "RIGHT", -pad, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetWordWrap(false)
    return yOff - 22
end

function ns.OptionsBtn(body, yOff, label, onClick, width, pad, fontSize)
    pad = pad or 8
    width = width or 184

    local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
    btn:SetSize(width, 20)
    btn:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    btn:SetBackdrop(ns.MakeBackdrop())
    btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
    btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ns.FONT_ROWS, fontSize or 10, "OUTLINE")
    fs:SetPoint("LEFT", btn, "LEFT", 6, 0)
    fs:SetWidth(width - 12)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs:SetText(label)
    fs:SetTextColor(0.70, 0.88, 0.85)

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
        btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
        fs:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        fs:SetTextColor(0.70, 0.88, 0.85)
    end)

    return yOff - 26
end

function ns.OptionsSlider(body, yOff, label, min, max, step, getVal, setVal, fillR, fillG, fillB, pad, disabled, fontSize)
    pad = pad or 8
    if disabled then
        fillR, fillG, fillB = 0.30, 0.30, 0.30
    else
        fillR = fillR or 0.85
        fillG = fillG or 0.65
        fillB = fillB or 0.10
    end

    local lbl = body:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(ns.FONT_ROWS, fontSize or 9, "OUTLINE")
    lbl:SetText("|cff" .. (disabled and "555555" or "888888") .. label .. "|r")
    lbl:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    lbl:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
    lbl:SetJustifyH("LEFT")
    lbl:SetWordWrap(false)

    yOff = yOff - 14

    local bg = CreateFrame("Frame", nil, body, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    bg:SetSize(138, 14)
    bg:SetBackdrop(ns.MakeBackdrop())
    bg:SetBackdropColor(0, 0, 0, disabled and 0.25 or 0.5)
    bg:SetBackdropBorderColor(0.25, 0.25, 0.3, disabled and 0.4 or 1)

    local fill = bg:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", bg, "LEFT", 2, 0)
    fill:SetHeight(10)
    fill:SetColorTexture(fillR, fillG, fillB, disabled and 0.4 or 0.85)

    local valBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
    valBox:SetPoint("LEFT", bg, "RIGHT", 4, 0)
    valBox:SetSize(44, 14)
    valBox:SetBackdrop(ns.MakeBackdrop())
    valBox:SetBackdropColor(0, 0, 0, disabled and 0.25 or 0.5)
    valBox:SetBackdropBorderColor(0.25, 0.25, 0.3, disabled and 0.4 or 1)

    local valTxt = valBox:CreateFontString(nil, "OVERLAY")
    valTxt:SetFont(ns.FONT_ROWS, fontSize or 9, "OUTLINE")
    valTxt:SetPoint("CENTER", valBox, "CENTER", 0, 0)
    valTxt:SetTextColor(disabled and 0.4 or 1, disabled and 0.4 or 1, disabled and 0.4 or 1)

    local function UpdateVis(value)
        local pct = (value - min) / (max - min)
        fill:SetWidth(math.max(2, (bg:GetWidth() - 4) * pct))
        valTxt:SetText(string.format("%.2f", value):gsub("%.?0+$", ""))
    end

    local slider = CreateFrame("Slider", nil, bg)
    slider:SetAllPoints(bg)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:Hide()
    end

    slider:SetValue(getVal())
    UpdateVis(getVal())

    if disabled then
        slider:EnableMouse(false)
    else
        slider:SetScript("OnValueChanged", function(self, value)
            UpdateVis(value)
        end)
        slider:SetScript("OnMouseUp", function(self)
            setVal(self:GetValue())
        end)
    end

    return yOff - 18
end

function ns.OptionsColorSwatch(parent, r, g, b, onPick, onReset, tooltip)
    local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetBackdrop(ns.MakeBackdrop())
    swatch:SetBackdropColor(r, g, b, 1)
    swatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    swatch:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b,
                hasOpacity = false,
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    r, g, b = nr, ng, nb
                    swatch:SetBackdropColor(r, g, b, 1)
                    if onPick then
                        onPick(r, g, b)
                    end
                end,
                cancelFunc = function(prev)
                    r, g, b = prev.r, prev.g, prev.b
                    swatch:SetBackdropColor(r, g, b, 1)
                    if onPick then
                        onPick(r, g, b)
                    end
                end,
            })
        elseif button == "RightButton" and onReset then
            r, g, b = onReset()
            swatch:SetBackdropColor(r, g, b, 1)
        end
    end)
    swatch:SetScript("OnEnter", function()
        swatch:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
        GameTooltip:SetOwner(swatch, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip or "Color", 1, 1, 1)
        GameTooltip:AddLine("Left-click: Pick color", 0.5, 0.5, 0.5)
        if onReset then
            GameTooltip:AddLine("Right-click: Reset", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function()
        swatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        GameTooltip:Hide()
    end)
    return swatch
end
