-- Immersion / DialogUI parchment theme -- WoW 3.3.5a.
-- Pure presentation. No changes to events, clicks, OnShow/OnHide, bound keys,
-- DialogueUI camera bridge, handwriting sound, NPC gossip API, or saved settings.
-- Toggle with /duiparchment off; uninstall folder to remove completely.

local ns = 'Immersion_DialogUITheme'
local fmt = string.format
local prefix = '|cffffd892Immersion Parchment|r: '
local P = 'Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\'
local PARCHMENT = P .. 'Parchment'
local OPTION = P .. 'OptionBackground-Common'
local OPTION_GREY = P .. 'OptionBackground-Grey'
local OPTION_HOLLOW = P .. 'OptionBackground-Hollow'
local OPTION_HILITE = P .. 'ButtonHighlight-Gossip'
local DIVIDER = P .. 'Divider-H'

-- Saved variables belong solely to this skin; never overwrite the two add-ons'.
DUIImmersionParchment = DUIImmersionParchment or {}
local settings = DUIImmersionParchment
if settings.enabled == nil then settings.enabled = true end
if settings.scope ~= 'gossip' and settings.scope ~= 'all' then settings.scope = 'all' end
-- New fields default to the exact v1.0.0 text metrics. Old SavedVariables migrate
-- automatically; no modifications to Immersion or DialogUI settings.
local FONT_PATHS = {
    friz = 'Fonts\\FRIZQT__.TTF',
    morpheus = 'Fonts\\MORPHEUS.TTF',
    skurri = 'Fonts\\SKURRI.TTF',
    arial = 'Fonts\\ARIALN.TTF',
    dialogui = 'Interface\\AddOns\\DialogUI\\src\\assets\\font\\frizqt__.ttf',
}
if settings.font ~= 'default' and not FONT_PATHS[settings.font] then settings.font = 'default' end
if type(settings.fontSize) ~= 'number' or settings.fontSize < 0 or settings.fontSize > 26 then
    settings.fontSize = 0
end
if settings.titleFont ~= 'default' and not FONT_PATHS[settings.titleFont] then settings.titleFont = nil end
if settings.bodyFont ~= 'default' and not FONT_PATHS[settings.bodyFont] then settings.bodyFont = nil end

local frame = _G.ImmersionFrame
local book = _G.DBookFrame
local quest = _G.DQuestFrame
local gossip = _G.DGossipFrame
local titles = frame and frame.TitleButtons
local talk = frame and frame.TalkBox
local bg = talk and talk.BackgroundFrame
local nameText = talk and talk.NameFrame and talk.NameFrame.Name
local speechText = talk and talk.TextFrame and talk.TextFrame.Text
local progressText = talk and talk.TextFrame and talk.TextFrame.SpeechProgress
local elements = talk and talk.Elements
local hilite = talk and talk.Hilite

local function Chat(s)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(prefix .. s) end
end

-- Fail closed on incompatible or incomplete installations. Do not create
-- phantom frames or globally remap any Immersion functions.
if not (IsAddOnLoaded('Immersion') and IsAddOnLoaded('DialogUI')
        and IsAddOnLoaded('DialogUI_ImmersionCameraCompat'))
    or not (frame and titles and talk and bg and bg.TextBackground and bg.SolidBackground)
    or not (nameText and speechText and progressText and gossip and quest and book and elements and hilite and elements.Content)
    or type(titles.GetButton) ~= 'function'
    or type(titles.GOSSIP_SHOW) ~= 'function'
    or type(titles.QUEST_GREETING) ~= 'function'
    or type(_G.DQuestFrame_SetKeys) ~= 'function' then
    Chat('Not activated: expected original add-ons and camera bridge are not present. Nothing changed.')
    return
end

-- Passive texture pieces with no mouse region; corners retain their natural
-- proportions while the parchment middle stretches to fit the frame.
local function NinePatch(parent, expandX, expandY, corner, opacity, texture)
    local group = {}
    local cut = 0.125
    local function Piece(u0,u1,v0,v1)
        local t = parent:CreateTexture(nil, 'BACKGROUND', nil, -1)
        t:SetTexture(texture or PARCHMENT)
        t:SetTexCoord(u0,u1,v0,v1)
        t:SetVertexColor(1,1,1,opacity or 0.95)
        group[#group + 1] = t
        return t
    end
    local tl = Piece(0,cut,0,cut)
    local tm = Piece(cut,1-cut,0,cut)
    local tr = Piece(1-cut,1,0,cut)
    local ml = Piece(0,cut,cut,1-cut)
    local mm = Piece(cut,1-cut,cut,1-cut)
    local mr = Piece(1-cut,1,cut,1-cut)
    local bl = Piece(0,cut,1-cut,1)
    local bm = Piece(cut,1-cut,1-cut,1)
    local br = Piece(1-cut,1,1-cut,1)

    tl:SetPoint('TOPLEFT', parent, 'TOPLEFT', -expandX, expandY)
    tl:SetSize(corner,corner)
    tr:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', expandX, expandY)
    tr:SetSize(corner,corner)
    bl:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', -expandX, -expandY)
    bl:SetSize(corner,corner)
    br:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', expandX, -expandY)
    br:SetSize(corner,corner)
    tm:SetPoint('TOPLEFT',tl,'TOPRIGHT')
    tm:SetPoint('BOTTOMRIGHT',tr,'BOTTOMLEFT')
    bm:SetPoint('TOPLEFT',bl,'TOPRIGHT')
    bm:SetPoint('BOTTOMRIGHT',br,'BOTTOMLEFT')
    ml:SetPoint('TOPLEFT',tl,'BOTTOMLEFT')
    ml:SetPoint('BOTTOMRIGHT',bl,'TOPRIGHT')
    mr:SetPoint('TOPLEFT',tr,'BOTTOMLEFT')
    mr:SetPoint('BOTTOMRIGHT',br,'TOPRIGHT')
    mm:SetPoint('TOPLEFT',tl,'BOTTOMRIGHT')
    mm:SetPoint('BOTTOMRIGHT',br,'TOPLEFT')
    for _, t in ipairs(group) do t:Hide() end
    return group
end

local talkParchment = NinePatch(bg, 2, 2, 24)

-- Gossip keeps its decorated individual buttons, but the shared backing
-- now uses separate top/middle/bottom texture pieces so it does not distort
-- badly when the option stack becomes tall.
local titlesShadow = CreateFrame('Frame', nil, titles)
titlesShadow:SetFrameLevel(titles:GetFrameLevel() - 1)
titlesShadow:Hide()
local titleBGTop = titlesShadow:CreateTexture(nil, 'BACKGROUND')
titleBGTop:SetTexture(OPTION_GREY)
titleBGTop:SetTexCoord(0,1,0,0.22)
titleBGTop:SetVertexColor(0.22, 0.16, 0.12, 0.64)
local titleBGMid = titlesShadow:CreateTexture(nil, 'BACKGROUND')
titleBGMid:SetTexture(OPTION_GREY)
titleBGMid:SetTexCoord(0,1,0.22,0.78)
titleBGMid:SetVertexColor(0.22, 0.16, 0.12, 0.64)
local titleBGBot = titlesShadow:CreateTexture(nil, 'BACKGROUND')
titleBGBot:SetTexture(OPTION_GREY)
titleBGBot:SetTexCoord(0,1,0.78,1)
titleBGBot:SetVertexColor(0.22, 0.16, 0.12, 0.64)
local titleEdgeTop = titlesShadow:CreateTexture(nil, 'BORDER')
titleEdgeTop:SetTexture(OPTION_HOLLOW)
titleEdgeTop:SetTexCoord(0,1,0,0.22)
titleEdgeTop:SetVertexColor(0.70, 0.56, 0.40, 0.58)
local titleEdgeMid = titlesShadow:CreateTexture(nil, 'BORDER')
titleEdgeMid:SetTexture(OPTION_HOLLOW)
titleEdgeMid:SetTexCoord(0,1,0.22,0.78)
titleEdgeMid:SetVertexColor(0.70, 0.56, 0.40, 0.58)
local titleEdgeBot = titlesShadow:CreateTexture(nil, 'BORDER')
titleEdgeBot:SetTexture(OPTION_HOLLOW)
titleEdgeBot:SetTexCoord(0,1,0.78,1)
titleEdgeBot:SetVertexColor(0.70, 0.56, 0.40, 0.58)
for _,t in ipairs({titleBGTop,titleBGMid,titleBGBot,titleEdgeTop,titleEdgeMid,titleEdgeBot}) do t:Hide() end

-- Replace the stock framed quest backdrop, rather than layering faint art
-- over its still-visible hard border. Preserve it exactly for the skin toggle.
local questStockBackdrop = elements:GetBackdrop()
local questStockColor = {elements:GetBackdropColor()}
local questStockBorder = {elements:GetBackdropBorderColor()}

-- Seven rough, translucent silhouettes build a feathered transition. Each is
-- nine-sliced so the worn edge stays small when the reward section grows.
-- Only passive background textures: no extra frames, scripts or input regions.
local questFeather = {}
for layer = 0, 6 do
    local outset = 10 - layer * 3
    local pieces = NinePatch(elements, outset, outset, 16, 0.12, OPTION_GREY)
    for _, texture in ipairs(pieces) do
        texture:SetVertexColor(0.10, 0.08, 0.06, 0.12)
        questFeather[#questFeather + 1] = texture
    end
end

-- Warm parchment unifies the lower panel with the dialogue above. Three
-- faint inset passes retain paper grain and its worn silhouette without a
-- strong rolled outline. The wider dark feather remains underneath for contrast.
local questPaper = {}
for layer = 0, 2 do
    local inset = -2 - layer * 2
    local pieces = NinePatch(elements, inset, inset, 16, 0.08)
    for _, texture in ipairs(pieces) do
        texture:SetDrawLayer('BACKGROUND', 0)
        texture:SetVertexColor(1, 0.94, 0.84, 0.08)
        questPaper[#questPaper + 1] = texture
    end
end

-- Move the objectives/rewards section slightly down from the main talk box.
local questAnchor = {x = 0, y = -4}

-- The gold interaction outline is the *existing* clickable TalkBox's Hilite;
-- keeping that exact frame preserves Immersion's hover/fade, Action Cam, and
-- Shoulder Camera integration. UI-Tooltip-Border is neutral, unlike the stock
-- blue glow's baked-in colour.
local goldHighlight = {
    edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
    edgeSize=14,
    insets={left=4,right=4,top=4,bottom=4},
}
local oldR, oldG, oldB, oldA = hilite:GetBackdropBorderColor()
local stockHighlight = {backdrop=hilite:GetBackdrop(),
    border={oldR or 1, oldG or 1, oldB or 1, oldA or 1}}

-- Precise original state for runtime toggles and reloads.
local function CaptureTexture(t)
    local a,b,c,d = t:GetTexCoord()
    return {file=t:GetTexture(), coords={a,b,c,d},
        shown=t:IsShown(), color={t:GetVertexColor()}}
end
local function RestoreTexture(t,state)
    t:SetTexture(state.file)
    t:SetTexCoord(unpack(state.coords))
    t:SetVertexColor(unpack(state.color))
    if state.shown then t:Show() else t:Hide() end
end
local textBG = CaptureTexture(bg.TextBackground)
local solidBG = CaptureTexture(bg.SolidBackground)

local function CaptureFont(font)
    local path, size, flags = font:GetFont()
    return {font=font:GetFontObject(), path=path, size=size, flags=flags,
            color={font:GetTextColor()}}
end
local function RestoreFont(font,original)
    if original.font then font:SetFontObject(original.font) end
    -- An existing addon can have a per-region font override, not just a shared
    -- FontObject. Restore it exactly, without modifying the shared FontObject.
    if original.path and original.size then
        font:SetFont(original.path, original.size, original.flags or '')
    end
    font:SetTextColor(unpack(original.color))
end
local originalFonts = {}
local modifiedFonts = {}
local function RememberFont(font)
    if font and not originalFonts[font] then originalFonts[font] = CaptureFont(font) end
    return font and originalFonts[font]
end
for _, font in ipairs({nameText, speechText, progressText}) do RememberFont(font) end

-- Role-aware font sizes keep long quest text and gossip buttons readable.
-- fontSize=0 means original per-widget sizing with no override.
local function ApplyFont(font, role)
    local old = RememberFont(font)
    if not old then return end
    local chosen = settings.font
    if role == 'name' or role == 'header' then
        chosen = settings.titleFont or settings.font
    else
        chosen = settings.bodyFont or settings.font
    end
    local path = FONT_PATHS[chosen] or old.path
    if chosen == 'default' and settings.fontSize == 0 then
        if modifiedFonts[font] then
            RestoreFont(font,old)
            modifiedFonts[font] = nil
        end
        return
    end
    local size = old.size
    if settings.fontSize > 0 then
        local adjust = (role == 'name' and 4) or (role == 'progress' and -1)
            or (role == 'counter' and -3) or (role == 'header' and 2) or 0
        size = math.max(8, math.min(30, settings.fontSize + adjust))
    end
    if path and size then
        if font:SetFont(path,size,old.flags or '') == false then
            RestoreFont(font,old)
            modifiedFonts[font] = nil
        else
            modifiedFonts[font] = true
        end
    end
end
local function ApplyKnownFonts()
    ApplyFont(nameText,'name')
    ApplyFont(speechText,'body')
    ApplyFont(progressText,'progress')
    local content = elements.Content
    for _, key in ipairs({'ObjectivesText','GroupSize','RewardText'}) do
        ApplyFont(content[key], 'body')
    end
    ApplyFont(content.ObjectivesHeader,'header')
    local progress = elements.Progress
    if progress then
        ApplyFont(progress.ReqText, 'header')
        ApplyFont(progress.MoneyText, 'body')
    end
    local rewards = content.RewardsFrame
    if rewards then
        ApplyFont(rewards.Header,'header')
        for _, key in ipairs({'ItemChooseText','ItemReceiveText','PlayerTitleText'}) do
            ApplyFont(rewards[key],'body')
        end
        if rewards.XPFrame then
            ApplyFont(rewards.XPFrame.ReceiveText,'body')
            ApplyFont(rewards.XPFrame.ValueText,'body')
        end
        for _, b in pairs(rewards.Buttons or {}) do ApplyFont(b.Name,'body') end
    end
end
local function RestoreKnownFonts()
    for font,old in pairs(originalFonts) do
        if modifiedFonts[font] then
            RestoreFont(font,old)
            modifiedFonts[font] = nil
        end
    end
end

local originalButtons = {}
local function CaptureButton(button)
    if originalButtons[button] then return originalButtons[button] end
    local state = {
        backdrop=button:GetBackdrop(),
        overlay=button.Overlay and button.Overlay:GetBackdrop(),
        hilite=button.Hilite and button.Hilite:GetBackdrop(),
        label=button.Label and RememberFont(button.Label),
        counter=button.Counter and RememberFont(button.Counter),
        texture=button.HighlightTexture and CaptureTexture(button.HighlightTexture),
    }
    originalButtons[button] = state
    return state
end

local function StyleButton(button, active)
    if not (button and button.SetBackdrop) then return end
    local old = CaptureButton(button)
    if active then
        button:SetBackdrop({bgFile=OPTION,
            insets={left=1,right=1,top=2,bottom=2}})
        if button.Overlay then button.Overlay:SetBackdrop(nil) end
        if button.Hilite then button.Hilite:SetBackdrop(nil) end
        if button.HighlightTexture then
            button.HighlightTexture:SetTexture(OPTION_HILITE)
            button.HighlightTexture:SetTexCoord(0,1,0,1)
            button.HighlightTexture:SetVertexColor(1,0.81,0.55,1)
        end
        if button.Label then
            ApplyFont(button.Label, 'body')
            button.Label:SetTextColor(0.94,0.86,0.69,1)
        end
        if button.Counter then
            ApplyFont(button.Counter, 'counter')
            button.Counter:SetTextColor(0.9,0.79,0.55,1)
        end
    else
        button:SetBackdrop(old.backdrop)
        if button.Overlay then button.Overlay:SetBackdrop(old.overlay) end
        if button.Hilite then button.Hilite:SetBackdrop(old.hilite) end
        if button.HighlightTexture and old.texture then
            RestoreTexture(button.HighlightTexture,old.texture)
        end
        if button.Label and old.label then RestoreFont(button.Label,old.label) end
        if button.Counter and old.counter then RestoreFont(button.Counter,old.counter) end
    end
end

local activeTalk, activeTitles, activeQuest = false, false, false
local function SetGroup(group, active)
    for _, texture in ipairs(group) do
        if active then texture:Show() else texture:Hide() end
    end
end
local function IsGossip()
    local event = frame.lastEvent
    return event == 'GOSSIP_SHOW' or event == 'QUEST_GREETING'
end
local function IsQuestDetails()
    local event = frame.lastEvent
    return event == 'QUEST_DETAIL' or event == 'QUEST_PROGRESS'
        or event == 'QUEST_COMPLETE'
end
local function WantTalk()
    return settings.enabled and (settings.scope == 'all' or IsGossip())
end
local function WantTitles()
    return settings.enabled and (settings.scope == 'all'
        or titles.type == 'Gossip' or titles.type == 'Quests')
end
local function WantQuestDecoration()
    return settings.enabled and settings.scope == 'all'
        and IsQuestDetails() and elements:IsShown()
end

local function PositionQuestPanel(active)
    elements:ClearAllPoints()
    if active then
        elements:SetPoint('TOP', talk, 'BOTTOM', questAnchor.x, questAnchor.y)
    else
        elements:SetPoint('TOP', talk, 'BOTTOM', 0, 8)
    end
end

local function UpdateTitlesShadow(active)
    local pieces = {titleBGTop,titleBGMid,titleBGBot,titleEdgeTop,titleEdgeMid,titleEdgeBot}
    if not active then
        titlesShadow:Hide()
        for _,t in ipairs(pieces) do t:Hide() end
        return
    end
    local first, last
    for i, button in ipairs(titles.Buttons or {}) do
        if button and button:IsShown() then
            if not first then first = button end
            last = button
        end
    end
    if first and last then
        local topCap, botCap = 10, 10
        titlesShadow:ClearAllPoints()
        titlesShadow:SetPoint('TOPLEFT', first, 'TOPLEFT', -14, 12)
        titlesShadow:SetPoint('BOTTOMRIGHT', last, 'BOTTOMRIGHT', 14, -12)
        titleBGTop:ClearAllPoints(); titleBGTop:SetPoint('TOPLEFT', titlesShadow, 'TOPLEFT'); titleBGTop:SetPoint('TOPRIGHT', titlesShadow, 'TOPRIGHT'); titleBGTop:SetHeight(topCap)
        titleBGBot:ClearAllPoints(); titleBGBot:SetPoint('BOTTOMLEFT', titlesShadow, 'BOTTOMLEFT'); titleBGBot:SetPoint('BOTTOMRIGHT', titlesShadow, 'BOTTOMRIGHT'); titleBGBot:SetHeight(botCap)
        titleBGMid:ClearAllPoints(); titleBGMid:SetPoint('TOPLEFT', titleBGTop, 'BOTTOMLEFT'); titleBGMid:SetPoint('BOTTOMRIGHT', titleBGBot, 'TOPRIGHT')
        titleEdgeTop:ClearAllPoints(); titleEdgeTop:SetAllPoints(titleBGTop)
        titleEdgeMid:ClearAllPoints(); titleEdgeMid:SetAllPoints(titleBGMid)
        titleEdgeBot:ClearAllPoints(); titleEdgeBot:SetAllPoints(titleBGBot)
        titlesShadow:Show()
        for _,t in ipairs(pieces) do t:Show() end
    else
        titlesShadow:Hide()
        for _,t in ipairs(pieces) do t:Hide() end
    end
end

local function UpdateTalk()
    local active = WantTalk()
    if active ~= activeTalk then
        activeTalk = active
        if active then
            -- Render the original Immersion window via its same native frame;
            -- only its texture changes, never event/keyboard/mouse ownership.
            bg.TextBackground:SetTexture(nil)
            bg.SolidBackground:SetTexture(nil)
            SetGroup(talkParchment, true)
            hilite:SetBackdrop(goldHighlight)
            hilite:SetBackdropBorderColor(0.98,0.73,0.24,1)
            nameText:SetTextColor(0.34,0.22,0.12,1)
            speechText:SetTextColor(0.19,0.17,0.13,1)
            progressText:SetTextColor(0.44,0.28,0.16,1)
        else
            SetGroup(talkParchment, false)
            hilite:SetBackdrop(stockHighlight.backdrop)
            hilite:SetBackdropBorderColor(unpack(stockHighlight.border))
            RestoreTexture(bg.TextBackground,textBG)
            RestoreTexture(bg.SolidBackground,solidBG)
            RestoreKnownFonts()
            for _, font in ipairs({nameText, speechText, progressText}) do
                font:SetTextColor(unpack(originalFonts[font].color))
            end
        end
    end
    if active then
        ApplyKnownFonts()
        nameText:SetTextColor(0.34,0.22,0.12,1)
        speechText:SetTextColor(0.19,0.17,0.13,1)
        progressText:SetTextColor(0.44,0.28,0.16,1)
    end
end

local function UpdateQuest()
    local active = WantQuestDecoration()
    if active ~= activeQuest then
        activeQuest = active
        SetGroup(questFeather,active)
        SetGroup(questPaper,active)
        if active then
            elements:SetBackdrop(nil)
        else
            elements:SetBackdrop(questStockBackdrop)
            elements:SetBackdropColor(unpack(questStockColor))
            elements:SetBackdropBorderColor(unpack(questStockBorder))
        end
        PositionQuestPanel(active)
    end
end

local function UpdateTitles()
    local active = WantTitles()
    activeTitles = active
    UpdateTitlesShadow(active)
    for _, button in pairs(titles.Buttons or {}) do
        if button._duiParchmentStyled ~= active then
            StyleButton(button,active)
            button._duiParchmentStyled = active
        elseif active then
            -- Fonts can change while the gossip list is already open.
            ApplyFont(button.Label,'body')
            ApplyFont(button.Counter,'counter')
            button.Label:SetTextColor(0.94,0.86,0.69,1)
            button.Counter:SetTextColor(0.9,0.79,0.55,1)
        end
    end
end
local function Refresh()
    UpdateTalk()
    UpdateTitles()
    UpdateQuest()
end

-- Hook only AFTER normal Immersion event code. No hooks on the two hidden
-- DialogueUI frames: WXL Action Cam/Shoulder Camera depend on their lifecycle.
frame:HookScript('OnEvent', function(self, event)
    if event == 'GOSSIP_SHOW' or event == 'QUEST_GREETING'
        or event == 'QUEST_DETAIL' or event == 'QUEST_PROGRESS'
        or event == 'QUEST_COMPLETE' or event == 'QUEST_FINISHED'
        or event == 'GOSSIP_CLOSED' then
        Refresh()
    end
end)
-- Quest content can be hidden or revealed independently of the parent event.
-- Hooks are passive and never change Elements ownership, OnShow, or input.
elements:HookScript('OnShow', UpdateQuest)
elements:HookScript('OnHide', UpdateQuest)

hooksecurefunc(titles, 'GetButton', function(self, idx)
    -- Style buttons added dynamically after opening an NPC's options.
    if self.Buttons and self.Buttons[idx] then
        local button = self.Buttons[idx]
        local active = WantTitles()
        if button._duiParchmentStyled ~= active then
            StyleButton(button,active)
            button._duiParchmentStyled = active
        end
        UpdateTitlesShadow(active)
    end
end)
hooksecurefunc(titles,'GOSSIP_SHOW', UpdateTitles)
hooksecurefunc(titles,'QUEST_GREETING', UpdateTitles)

Refresh()

SLASH_DUI_IMMERSION_PARCHMENT1 = '/duiparchment'
SLASH_DUI_IMMERSION_PARCHMENT2 = '/duitheme'
local function PrintHelp()
    Chat('Controls: on | off | scope gossip/all | font list | font X | titlefont X | bodyfont X | fontsize 0 or 10-26')
    Chat('Font size 0 = original sizes. Gossip option spacing refreshes on next conversation.')
end
SlashCmdList.DUI_IMMERSION_PARCHMENT = function(message)
    local cmd, arg = (message or ''):lower():match('^%s*(%S*)%s*(%S*)')
    if cmd == 'on' then
        settings.enabled = true
    elseif cmd == 'off' then
        settings.enabled = false
    elseif cmd == 'scope' and (arg == 'gossip' or arg == 'all') then
        settings.scope = arg
    elseif cmd == 'font' and arg == 'list' then
        Chat('Fonts: default, friz, morpheus, skurri, arial, dialogui')
        return
    elseif cmd == 'font' and (arg == 'default' or FONT_PATHS[arg]) then
        settings.font = arg
        settings.titleFont = arg
        settings.bodyFont = arg
    elseif cmd == 'titlefont' and (arg == 'default' or FONT_PATHS[arg]) then
        settings.titleFont = arg
    elseif cmd == 'bodyfont' and (arg == 'default' or FONT_PATHS[arg]) then
        settings.bodyFont = arg
    elseif cmd == 'fontsize' then
        local n = tonumber(arg)
        if n and n == math.floor(n) and (n == 0 or (n >= 10 and n <= 26)) then
            settings.fontSize = n
        else
            Chat('Font size must be 0 (original) or 10 through 26. No change made.')
            return
        end
    elseif cmd == 'status' or cmd == '' then
        Chat('Skin: ' .. (settings.enabled and 'ON' or 'OFF') ..
             ' | scope: ' .. settings.scope .. ' | title font: ' .. tostring(settings.titleFont or settings.font) ..
             ' | body font: ' .. tostring(settings.bodyFont or settings.font) ..
             ' | text size: ' .. (settings.fontSize == 0 and 'original' or tostring(settings.fontSize)))
        PrintHelp()
        return
    else
        PrintHelp()
        return
    end
    Refresh()
    Chat('Skin ' .. (settings.enabled and 'ON' or 'OFF') ..
         '; scope ' .. settings.scope .. '; title font ' .. tostring(settings.titleFont or settings.font) ..
         '; body font ' .. tostring(settings.bodyFont or settings.font) ..
         '; size ' .. tostring(settings.fontSize))
end

Chat('1.1.5 visual-only skin loaded; feathered quest panel edge and split title/body fonts. /duiparchment for options.')
