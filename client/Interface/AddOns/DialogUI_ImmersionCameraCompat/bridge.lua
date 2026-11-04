-- DialogUI / Immersion camera compatibility bridge for WoW 3.3.5a.
-- This addon is deliberately separate from BOTH originals and has no SavedVariables.
-- RequiredDeps ensure this executes after the original DialogUI and Immersion.
-- Never Hide() DQuestFrame or DGossipFrame: Action Cam / Shoulder Camera rely on their visibility.

local PREFIX = "|cff74c7ecDialogUI-Immersion Compat|r: "
local function Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. message) end
end

local function Active()
    return IsAddOnLoaded and IsAddOnLoaded("DialogUI") and IsAddOnLoaded("Immersion")
end

local quest = _G.DQuestFrame
local gossip = _G.DGossipFrame
local focus = _G.DialogUI_Focus

-- Refuse partial activation: an incomplete or modified DialogUI source must not be tampered with.
if not Active() or not quest or not gossip or not focus
   or type(_G.DQuestFrame_SetKeys) ~= "function"
   or type(_G.DialogUI_AcceptOrComplete) ~= "function"
   or type(_G.DialogUI_DeclineOrCancel) ~= "function" then
    Print("Not activated: original DialogUI / Immersion lifecycle not detected. No frames changed.")
    return
end

local function GhostFrame(frame)
    -- Alpha does NOT change Show/Hide lifecycle: WXL can still observe the real frame.
    -- Disable hit testing recursively: clickable transparent buttons would block Immersion.
    frame:SetAlpha(0)
    frame:EnableMouse(false)
    if frame.EnableMouseWheel then frame:EnableMouseWheel(false) end
    if not frame.GetChildren then return end
    local children = {frame:GetChildren()}
    for i = 1, #children do
        local child = children[i]
        if child and child.EnableMouse then
            GhostFrame(child)
        end
    end
end

-- The quest/gossip OnShow code normally makes a full-screen backdrop that absorbs
-- clicks and dims Immersion. Prevent just that extra presentation side effect.
-- Do not replace the OnShow/OnHide scripts of the actual dialog frames.
local oldFocusOnShow = focus.OnShow
local oldFocusApply = focus.Apply
if type(oldFocusOnShow) == "function" then
    function focus:OnShow(frame)
        if Active() and (frame == quest or frame == gossip) then
            return -- preserve frame OnShow, but not the DialogUI-only focus backdrop
        end
        return oldFocusOnShow(self, frame)
    end
end

local function HideOldBackdrop()
    local bd = _G.DDialogFocusBackdrop
    if not bd then return end
    if UIFrameFadeRemoveFrame then UIFrameFadeRemoveFrame(bd) end
    bd:Hide()
    bd:SetAlpha(0)
    bd:EnableMouse(false)
end

if type(oldFocusApply) == "function" then
    function focus:Apply()
        if Active() then
            -- The quest dimmer is not the book dimmer; do not touch DBookBackdrop.
            HideOldBackdrop()
            return
        end
        return oldFocusApply(self)
    end
end

-- Do not let DialogUI bind SPACE, ESCAPE, or numeric keys on its ghost frame.
-- Immersion's own SetOverrideBindingClick handling must retain priority.
local oldQuestSetKeys = _G.DQuestFrame_SetKeys
_G.DQuestFrame_SetKeys = function(...)
    if Active() then
        if ClearOverrideBindings then ClearOverrideBindings(quest) end
        return
    end
    return oldQuestSetKeys(...)
end

local oldAccept = _G.DialogUI_AcceptOrComplete
local oldDecline = _G.DialogUI_DeclineOrCancel
_G.DialogUI_AcceptOrComplete = function(...)
    if Active() then return end
    return oldAccept(...)
end
_G.DialogUI_DeclineOrCancel = function(...)
    if Active() then return end
    return oldDecline(...)
end

-- ESC must go to Immersion rather than closing DialogUI's invisible UIPanel
-- (its OnHide invokes CloseQuest/CloseGossip). The frames remain fully shown.
if UISpecialFrames then
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == "DQuestFrame" or UISpecialFrames[i] == "DGossipFrame" then
            table.remove(UISpecialFrames, i)
        end
    end
end

GhostFrame(quest)
GhostFrame(gossip)
HideOldBackdrop()
if ClearOverrideBindings then ClearOverrideBindings(quest) end

-- Post-OnShow hook: original scripts still execute first, preserving camera signals.
-- Never react by hiding the frame (that would end a server dialog session).
quest:HookScript("OnShow", function(f)
    GhostFrame(f)
    HideOldBackdrop()
    if ClearOverrideBindings then ClearOverrideBindings(f) end
end)
gossip:HookScript("OnShow", function(f)
    GhostFrame(f)
    HideOldBackdrop()
end)

-- Preserve the prior book-only build's dedicated darken-background preference.
-- Original DialogUI has a book backdrop but no setting for it; keep the prior
-- account SavedVariable (bookDimEnabled) meaningful without editing the reader.
local function BookDimEnabled()
    return not (_G.DialogUISettings and _G.DialogUISettings.bookDimEnabled == false)
end

local function ApplyBookDim()
    local reader = _G.DBookFrame
    local bd = _G.DBookBackdrop
    if not reader or not bd or not reader:IsShown() then return end
    if BookDimEnabled() then
        if not bd:IsShown() then
            bd:Show()
            bd:SetAlpha(0)
            if UIFrameFadeIn then UIFrameFadeIn(bd, 0.5, 0, 1) else bd:SetAlpha(1) end
        end
    else
        if UIFrameFadeRemoveFrame then UIFrameFadeRemoveFrame(bd) end
        bd:Hide()
    end
end

-- Fade the page texture's outer shadow to zero at its bounds. The source
-- parchment stays intact; adjacent texture slices share exact UV boundaries.
-- WoW 3.3.5 has no texture masks, so use narrow gradient strips at the corners.
local function FeatherBookShadow()
    local page = _G.DBookPageTexture
    local reader = _G.DBookFrame
    if not page or not reader or reader.edgeFeathered then return end
    reader.edgeFeathered = true
    local file = page:GetTexture()
    local w, h = reader:GetWidth(), reader:GetHeight()
    local xedge, yedge = w * 16/512, h * 20/512
    local function slice(x, y, width, height, leftAlpha, rightAlpha, vertical)
        local t = reader:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(file)
        t:SetPoint("TOPLEFT", reader, "TOPLEFT", x, -y)
        t:SetWidth(width); t:SetHeight(height)
        t:SetTexCoord(x/w, (x+width)/w, y/h, (y+height)/h)
        t:SetGradientAlpha(vertical and "VERTICAL" or "HORIZONTAL",
            1,1,1,leftAlpha, 1,1,1,rightAlpha)
    end
    slice(xedge,yedge,w-2*xedge,h-2*yedge,1,1)
    slice(0,yedge,xedge,h-2*yedge,0,1)
    slice(w-xedge,yedge,xedge,h-2*yedge,1,0)
    -- VERTICAL gradients run bottom to top.
    slice(xedge,0,w-2*xedge,yedge,1,0,true)
    slice(xedge,h-yedge,w-2*xedge,yedge,0,1,true)
    for i=0,7 do
        local width = xedge/8
        local alpha = (i+0.5)/8
        slice(i*width,0,width,yedge,alpha,0,true)
        slice(i*width,h-yedge,width,yedge,0,alpha,true)
        slice(w-(i+1)*width,0,width,yedge,alpha,0,true)
        slice(w-(i+1)*width,h-yedge,width,yedge,0,alpha,true)
    end
    page:Hide()
end
FeatherBookShadow()

if _G.DBookFrame then
    _G.DBookFrame:HookScript("OnShow", ApplyBookDim)
    _G.DBookFrame:HookScript("OnHide", function()
        if not BookDimEnabled() and _G.DBookBackdrop then
            if UIFrameFadeRemoveFrame then UIFrameFadeRemoveFrame(_G.DBookBackdrop) end
            _G.DBookBackdrop:Hide()
        end
    end)
end

-- Keep the dedicated reader checkbox the previous book-only edition introduced.
-- This is a new control on DialogUI's original options panel, not a replacement
-- for any existing setting or an Immersion setting.
if _G.DialogUIOptionsPanel then
    local cb = CreateFrame("CheckButton", "DialogUIBookDimCheck", _G.DialogUIOptionsPanel,
        "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", _G.DialogUIOptionsPanel, "TOPLEFT", 300, -73)
    local caption = _G.DialogUIBookDimCheckText
    if caption then caption:SetText("Darken background while reading") end
    cb.tooltipText = "Show the dark backdrop behind books, letters, and readable objects."
    cb:SetScript("OnShow", function(self) self:SetChecked(BookDimEnabled()) end)
    cb:SetScript("OnClick", function(self)
        if not _G.DialogUISettings then _G.DialogUISettings = {} end
        _G.DialogUISettings.bookDimEnabled = self:GetChecked() and true or false
        ApplyBookDim()
    end)
end

SLASH_DIALOGUI_IMMERSION_COMPAT1 = "/duic"
SlashCmdList["DIALOGUI_IMMERSION_COMPAT"] = function()
    local function Info(frame)
        if not frame then return "missing" end
        local on = frame:IsVisible() and "shown" or "hidden"
        return on .. ", alpha=" .. tostring(frame:GetAlpha()) .. ", mouse=" .. tostring(frame:IsMouseEnabled())
    end
    Print("ACTIVE. DQuestFrame: " .. Info(quest))
    Print("DGossipFrame: " .. Info(gossip))
    Print("DBookFrame: " .. Info(_G.DBookFrame))
    Print("ImmersionFrame: " .. Info(_G.ImmersionFrame))
end

Print("Ready: DialogUI quest/gossip frames kept alive but visually and interactively suppressed; books untouched.")
