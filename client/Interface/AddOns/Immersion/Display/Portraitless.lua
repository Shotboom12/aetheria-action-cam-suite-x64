-- Portrait-free dialogue layout. Loaded last; no saved settings are changed.
local frame = ImmersionFrame
local box = frame.TalkBox
local name = box.NameFrame.Name
local text = box.TextFrame.Text
local subtitle = box.NameFrame:CreateFontString(nil, 'ARTWORK')
box.NameFrame.Subtitle = subtitle
subtitle:SetJustifyH('LEFT')
subtitle:SetJustifyV('TOP')
subtitle:SetTextColor(0.28, 0.19, 0.10, 1)
subtitle:Hide()

-- Keep the model objects for Immersion's playback bookkeeping, but never render
-- them, their background, or the decorative portrait frame.
local function HidePortrait(self) self:Hide() end
box.MainFrame.Model:HookScript('OnShow', HidePortrait)
box.PortraitFrame:HookScript('OnShow', HidePortrait)
box.MainFrame.Model:Hide()
box.PortraitFrame:Hide()

-- These intro effects lived outside the portrait frame and still flashed over
-- the reclaimed text area. Leave animation objects intact for the fade manager.
local overlay = box.MainFrame.Overlay
for _, region in ipairs({box.MainFrame.Sheen, box.MainFrame.TextSheen,
    overlay.Glow_TopBar, overlay.Glow_LeftBar, overlay.Glow_RightBar}) do
    region:Hide()
    region:SetTexture(nil)
end

local tooltip = CreateFrame('GameTooltip', 'ImmersionSubtitleTooltip', UIParent, 'GameTooltipTemplate')
local function GetSubtitle(speaker, explicitUnit)
    local unit = explicitUnit
    if not unit then
        if UnitExists('questnpc') then unit = 'questnpc'
        elseif UnitExists('npc') then unit = 'npc' end
    end
    -- Never borrow the selected target's title, or an unrelated live NPC's
    -- title during playback of another speaker's dialogue.
    if not unit or not UnitExists(unit) or UnitIsPlayer(unit) or UnitName(unit) ~= speaker then return end
    tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
    tooltip:ClearLines()
    tooltip:SetUnit(unit)
    local line = _G.ImmersionSubtitleTooltipTextLeft2
    local value = line and line:GetText()
    tooltip:Hide()
    if not value then return end
    value = value:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):match('^%s*(.-)%s*$')
    -- Untitled NPCs have their level/type here instead of a subtitle.
    if value == '' or value:find(LEVEL or 'Level', 1, true) == 1
        or value:find('%d') or value == PVP_ENABLED then return end
    if value:sub(1, 1) ~= '<' then value = '<' .. value .. '>' end
    return value
end

local function Layout()
    name:ClearAllPoints()
    name:SetPoint('TOPLEFT', box, 'TOPLEFT', 24, -22)
    name:SetPoint('TOPRIGHT', box, 'TOPRIGHT', -60, -22)
    local font, size = text:GetFont()
    if font then subtitle:SetFont(font, size, '') end
    subtitle:SetShadowOffset(0, 0)
    subtitle:SetShadowColor(0, 0, 0, 0)
    subtitle:ClearAllPoints()
    subtitle:SetPoint('TOPLEFT', name, 'BOTTOMLEFT', 0, -4)
    subtitle:SetPoint('TOPRIGHT', name, 'BOTTOMRIGHT', 0, -4)
    text:ClearAllPoints()
    if subtitle:GetText() and subtitle:GetText() ~= '' then
        subtitle:Show()
        text:SetPoint('TOPLEFT', subtitle, 'BOTTOMLEFT', 0, -8)
    else
        subtitle:Hide()
        text:SetPoint('TOPLEFT', name, 'BOTTOMLEFT', 0, -8)
    end
    text:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', -42, 22)
end

local UpdateTalkingHead = frame.UpdateTalkingHead
function frame:UpdateTalkingHead(speaker, dialogue, npcType, explicitUnit, isToastPlayback)
    subtitle:SetText(GetSubtitle(speaker, explicitUnit))
    Layout() -- establish available text height before Immersion fits its fonts
    return UpdateTalkingHead(self, speaker, dialogue, npcType, explicitUnit, isToastPlayback)
end

local OnDisplayLine = text.OnDisplayLineCallback
function text:OnDisplayLineCallback(...)
    -- Follow the actual dialogue font after Immersion's font fitting.
    Layout()
    return OnDisplayLine(self, ...)
end
Layout()
