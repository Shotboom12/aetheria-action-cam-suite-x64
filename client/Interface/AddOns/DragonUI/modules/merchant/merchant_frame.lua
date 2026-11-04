-- Copyright (c) 2026 NeticSoul. Licensed under the MIT License; see LICENSE.

local addon = select(2, ...)

local Merchant = { initialized = false, applied = false }

-- Shared with sell_junk.lua and buyback_undo.lua, which merchant.xml loads after this file.
local parts = addon.merchantParts or {}
addon.merchantParts = parts

local function localized(key)
    local strings = addon.L
    local text = strings and strings[key]
    if type(text) ~= "string" or text == "" then
        return key
    end
    return text
end
parts.localized = localized

if addon.RegisterModule then
    addon:RegisterModule("merchant", Merchant, localized("Merchant"), localized("Retail-style vendor window chrome"), {
        lifecyclePrefix = "Merchant",
        loadOnce = true,
    })
end

local windowBuilt = false
local chrome = {}
local tabWidth, tabGlow, recessed = {}, {}, {}
local questAnswer = {}
local scanTip

local MERCHANT_ROWS = 10
local ALL_ROWS = 12
local CONTROL_LIFT = 4
local TAB_GLOW_ALPHA = 0.4
-- Lower-center stone conversation layout; native merchant owns all transactions.
local WINDOW_W, WINDOW_H = 768, 436
local immersiveLayout
local layoutPending = false
local layoutBusy = false
local entrance
local entranceOffset = 0
local bottomOffset = 36

local CLASSIC_FILES = { "ui-merchant-top", "ui-merchant-bot", "ui-buyback-" }

-- Blizzard re-shows these on its own during updates.
local REAPPEARING = {
    "MerchantNameText", "MerchantRepairText",
    "MerchantFrameBottomLeftBorder", "MerchantFrameBottomRightBorder",
    "BuybackFrameTopLeft", "BuybackFrameTopRight", "BuybackFrameBotLeft", "BuybackFrameBotRight",
}

local SESSION_ANCHORS = {
    { "MerchantItem1", "TOPLEFT", "MerchantFrame", "TOPLEFT", 11, -69 },
    { "MerchantPrevPageButton", "CENTER", "MerchantFrame", "BOTTOMLEFT", 25, 96 },
    { "MerchantNextPageButton", "CENTER", "MerchantFrame", "BOTTOMLEFT", 310, 96 },
    { "MerchantMoneyFrame", "BOTTOMRIGHT", "MerchantFrame", "BOTTOMRIGHT", -6, 9 },
    { "MerchantBuyBackItem", "TOPLEFT", "MerchantItem10", "BOTTOMLEFT", 30, -53 },
}

local LIFTED = {
    "MerchantBuyBackItem", "MerchantPrevPageButton", "MerchantNextPageButton", "MerchantMoneyFrame",
    "MerchantRepairAllButton", "MerchantRepairItemButton", "MerchantGuildBankRepairButton",
    "DragonUI_MerchantSellAllJunkButton",
}
for row = 1, ALL_ROWS do
    LIFTED[#LIFTED + 1] = "MerchantItem" .. row
end

-- Texcoords on the 256x128 redbutton2x sheet: getter, left, right, top, bottom, blend.
local CLOSE_STATES = {
    { "GetNormalTexture", 0.15234375, 0.29296875, 0.0078125, 0.3046875 },
    { "GetPushedTexture", 0.15234375, 0.29296875, 0.6328125, 0.9296875 },
    { "GetDisabledTexture", 0.15234375, 0.29296875, 0.3203125, 0.6171875 },
    { "GetHighlightTexture", 0.44921875, 0.58984375, 0.0078125, 0.3046875, "ADD" },
}

-- Region suffix, width, height, anchor point, x offset, then left/right/top/bottom texcoords.
local TAB_CAPS = {
    { "Left", 35, 36, "TOPLEFT", -5, 0.015625, 0.5625, 0.816406, 0.957031 },
    { "Right", 37, 36, "TOPRIGHT", 5, 0.015625, 0.59375, 0.667969, 0.808594 },
    { "LeftDisabled", 35, 42, "TOPLEFT", -4, 0.015625, 0.5625, 0.496094, 0.660156 },
    { "RightDisabled", 37, 42, "TOPRIGHT", 6, 0.015625, 0.59375, 0.324219, 0.488281 },
}

-- Region suffix, cap suffix it spans between, height, then texcoords.
local TAB_FILLS = {
    { "Middle", "", 36, 0, 0.015625, 0.175781, 0.316406 },
    { "MiddleDisabled", "Disabled", 42, 0, 0.015625, 0.00390625, 0.167969 },
}

local REPAIR_ICON_ATLAS = {
    { "MerchantRepairAllButton", "MerchantRepairAllIcon", "spellicon-256x256-repairall" },
    { "MerchantRepairItemButton", nil, "spellicon-256x256-repair" },
    { "MerchantGuildBankRepairButton", "MerchantGuildBankRepairButtonIcon", "spellicon-256x256-repairallguild" },
}

local RECESS_OWNERS = {
    "MerchantRepairAllButton", "MerchantRepairItemButton", "MerchantGuildBankRepairButton",
    "DragonUI_MerchantSellAllJunkButton",
}


local GOLD_EDGE = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14 }

local function art(file)
    return addon._dir .. file
end

-- MoveAnything's saved merchant position was suppressing SetPoint and slide
-- motion. Release only this frame's runtime locks; never alter its saved profile.
local function releaseMerchantLocks(frame)
    local manager = _G.MovAny
    if manager then
        if type(manager.UnlockPoint) == "function" then manager:UnlockPoint(frame) end
        if type(manager.UnlockScale) == "function" then manager:UnlockScale(frame) end
    end
end

local function place(region, point, anchor, relativePoint, x, y)
    if region == _G.MerchantFrame then releaseMerchantLocks(region) end
    region:ClearAllPoints()
    -- Forced-lock mode replaces SetPoint with a no-op and saves the real method.
    local setter = region == _G.MerchantFrame and region.MASetPoint or region.SetPoint
    setter(region, point, anchor, relativePoint, x, y)
end

local function span(region, host, left, top, right, bottom)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", host, "TOPLEFT", left, top)
    region:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", right, bottom)
end

local function toggle(region, visible)
    if not region then
        return
    end
    if visible then
        region:Show()
    else
        region:Hide()
    end
end

local function lowerPath(texture)
    local file = texture and texture:GetTexture()
    if type(file) ~= "string" then
        return ""
    end
    return file:lower()
end

local function texturesOf(frame)
    local found = {}
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            found[#found + 1] = region
        end
    end
    return found
end

local function applySlices(host, layoutName)
    local slicer = _G.DragonUI_NineSlice
    if not slicer or not slicer.GetLayout or not slicer.ApplyLayout then
        return
    end
    local layout = slicer.GetLayout(layoutName)
    if layout then
        slicer.ApplyLayout(host, layout)
    end
end

local function marbleFloor(host)
    local ground = host:CreateTexture(nil, "BACKGROUND", nil, -5)
    ground:SetTexture(art("UI\\ui-background-marble"))
    ground:SetHorizTile(true)
    ground:SetVertTile(true)
    ground:SetAllPoints(host)
end

local function isClassicFile(file)
    for i = 1, #CLASSIC_FILES do
        if file:find(CLASSIC_FILES[i], 1, true) then
            return true
        end
    end
end

local function hideReappearing()
    for i = 1, #REAPPEARING do
        local region = _G[REAPPEARING[i]]
        if region then
            region:Hide()
        end
    end
end

local function stripStockArt(frame)
    local portrait = _G.MerchantFramePortrait
    for _, tex in ipairs(texturesOf(frame)) do
        if tex ~= portrait and tex ~= chrome.streaks then
            local layer = tex:GetDrawLayer()
            local stock = layer == "BACKGROUND"
                or ((layer == "BORDER" or layer == "ARTWORK") and isClassicFile(lowerPath(tex)))
            if stock then
                tex:Hide()
            end
        end
    end
end

local function shapeWindow(frame)
    WINDOW_H = 436
    frame:SetSize(WINDOW_W, WINDOW_H)
    frame:SetHitRectInsets(0, 0, 0, 0)
end

local function anchorControls()
    for _, spec in ipairs(SESSION_ANCHORS) do
        local region, target = _G[spec[1]], _G[spec[3]]
        if region and target then
            place(region, spec[2], target, spec[4], spec[5], spec[6])
        end
    end
end

-- FontStrings have no frame level; the holder lifts the page text above the bottom band.
local function housePageText(frame)
    local holder = CreateFrame("Frame", nil, frame)
    holder:EnableMouse(false)
    holder:SetSize(180, 20)
    holder:SetPoint("BOTTOM", frame, "BOTTOM", 0, 114)
    holder:Show()
    chrome.pageHolder = holder

    local label = _G.MerchantPageText
    if label then
        label:SetParent(holder)
        place(label, "BOTTOM", holder, "BOTTOM", 0, 0)
        label:SetWidth(180)
        label:SetJustifyH("CENTER")
    end
end

local function liftControls()
    local level = _G.MerchantFrame:GetFrameLevel() + CONTROL_LIFT
    for _, name in ipairs(LIFTED) do
        local widget = _G[name]
        if widget then
            widget:SetFrameLevel(level)
        end
    end
    if chrome.pageHolder then
        chrome.pageHolder:SetFrameLevel(level)
    end
end

local function paintBody(frame)
    local header=CreateFrame("Frame",nil,frame);header:EnableMouse(false);header:SetSize(280,74)
    header:SetPoint("TOP",frame,"TOP");chrome.header=header
end

local function addStreaks(frame)end

local function titleText()
    local source = _G.MerchantNameText
    return source and source:GetText() or ""
end

local function ensureTitle(frame)
    local title = frame.Title
    if not title then
        title = chrome.header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", chrome.header, "TOPLEFT", 12, -27)
        title:SetPoint("TOPRIGHT", chrome.header, "TOPRIGHT", -12, -27)
        title:SetHeight(22)
        title:SetWordWrap(false)
        title:SetFont("Fonts\\MORPHEUS.TTF", 19, "")
        title:SetJustifyH("LEFT")
        frame.Title = title
    end
    title:SetText(titleText())
end

-- Compact name/title-only header: the user requested no portrait.
local function refreshPortrait()
    if _G.MerchantFramePortrait then _G.MerchantFramePortrait:Hide() end
end

local function seatPortrait(frame)
    refreshPortrait()
end

-- User-supplied ForeverFlavor chrome atlas; identical bytes already installed
-- for the map. Reuse its matched rail family and hollow L-shaped corners.
local FF_FRAME_TEX = "Interface\\AddOns\\DragonUI\\modules\\worldmap\\textures\\ff_chrome_frame"
local FF_SHEET_W, FF_SHEET_H = 1024, 512
local FF_CORNER = 32 * 0.4
local FF_TOP = 4.8
local FF_BOTTOM = 4.8
local FF_SIDE = 4.8

local function ffTexCoord(l, t, r, b)
    return l / FF_SHEET_W, r / FF_SHEET_W, t / FF_SHEET_H, b / FF_SHEET_H
end

-- Coordinates share the same outer origin and 12-pixel rail cross-section.
-- Reversed coordinates reflect the artwork using the client's native UVs.
local FF_SLICES = {
    top    = {550, 294, 790, 306},
    bottom = {550, 306, 790, 294},
    left   = {490, 330, 502, 400},
    right  = {502, 330, 490, 400},
    tl     = {490, 294, 522, 326},
    tr     = {522, 294, 490, 326},
    bl     = {490, 326, 522, 294},
    br     = {522, 326, 490, 294},
}

local function matchingBorder(parent)
    local holder = CreateFrame("Frame", nil, parent)
    -- Half-overlap the panel edge, protecting its content padding.
    local outset = 2
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", -outset, outset)
    holder:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", outset, -outset)
    holder:SetFrameLevel(parent:GetFrameLevel() + 8)
    holder:EnableMouse(false)

    local function piece(kind, sublevel, crop)
        local spec = crop or FF_SLICES[kind]
        local texture = holder:CreateTexture(nil, "OVERLAY", nil, sublevel or 0)
        texture:SetTexture(FF_FRAME_TEX)
        texture:SetTexCoord(ffTexCoord(spec[1], spec[2], spec[3], spec[4]))
        return texture
    end

    -- Four independent edge strips fill the entire length between corners.
    -- Their height/width describe VISIBLE texture, not blank atlas padding.
    local top = piece('top')
    top:SetPoint('TOPLEFT', holder, 'TOPLEFT', FF_CORNER, 0)
    top:SetPoint('TOPRIGHT', holder, 'TOPRIGHT', -FF_CORNER, 0)
    top:SetHeight(FF_TOP)

    local bottom = piece('bottom')
    bottom:SetPoint('BOTTOMLEFT', holder, 'BOTTOMLEFT', FF_CORNER, 0)
    bottom:SetPoint('BOTTOMRIGHT', holder, 'BOTTOMRIGHT', -FF_CORNER, 0)
    bottom:SetHeight(FF_BOTTOM)

    local left = piece('left')
    left:SetPoint('TOPLEFT', holder, 'TOPLEFT', 0, -FF_CORNER)
    left:SetPoint('BOTTOMLEFT', holder, 'BOTTOMLEFT', 0, FF_CORNER)
    left:SetWidth(FF_SIDE)

    local right = piece('right')
    right:SetPoint('TOPRIGHT', holder, 'TOPRIGHT', 0, -FF_CORNER)
    right:SetPoint('BOTTOMRIGHT', holder, 'BOTTOMRIGHT', 0, FF_CORNER)
    right:SetWidth(FF_SIDE)

    -- Matching mirrored corners meet the rails at the same source scale.
    -- Same texture sheet; no procedural gold or solid-color strokes.
    local corners = {}
    for _, corner in ipairs({
        {'tl', 'TOPLEFT'}, {'tr', 'TOPRIGHT'},
        {'bl', 'BOTTOMLEFT'}, {'br', 'BOTTOMRIGHT'},
    }) do
        -- Draw an L instead of the atlas cell's opaque interior square.
        -- The two non-overlapping rectangles retain the original bevel and UV scale.
        local key, anchor = corner[1], corner[2]
        local spec = FF_SLICES[key]
        local isTop = key == 'tl' or key == 'tr'
        local isLeft = key == 'tl' or key == 'bl'
        local function crop(u0, v0, u1, v1)
            local l, t, r, b = unpack(spec)
            return {l + (r-l)*u0, t + (b-t)*v0,
                    l + (r-l)*u1, t + (b-t)*v1}
        end
        local fraction = 12 / 32
        local h0, h1 = isTop and 0 or (1-fraction), isTop and fraction or 1
        local v0, v1 = isTop and fraction or 0, isTop and 1 or (1-fraction)
        local u0, u1 = isLeft and 0 or (1-fraction), isLeft and fraction or 1
        local horizontal = piece(key, 1, crop(0, h0, 1, h1))
        horizontal:SetSize(FF_CORNER, FF_TOP)
        horizontal:SetPoint(anchor, holder, anchor, 0, 0)
        local vertical = piece(key, 1, crop(u0, v0, u1, v1))
        vertical:SetSize(FF_SIDE, FF_CORNER - FF_TOP)
        vertical:SetPoint(anchor, holder, anchor, 0, isTop and -FF_TOP or FF_BOTTOM)
        corners[key] = {horizontal, vertical}
    end
    holder.pieces = {top=top, bottom=bottom, left=left, right=right,
                     tl=corners.tl, tr=corners.tr, bl=corners.bl, br=corners.br}
    return holder
end

local function buildGrid(frame, level)
    local grid=CreateFrame("Frame",nil,frame);grid:EnableMouse(false);grid:SetFrameLevel(level);grid:SetAllPoints(frame)
    chrome.grid=grid;chrome.gridRim=CreateFrame("Frame",nil,grid)
    chrome.wash=grid:CreateTexture(nil,"BACKGROUND");chrome.wash:SetTexture(nil);chrome.wash:Hide()
end

local function buildBand(frame, level)
    local band=CreateFrame("Frame",nil,frame);band:SetFrameLevel(level);band:SetHeight(64)
    band:SetPoint("BOTTOM",frame,"BOTTOM",0,38);band:SetWidth(684)
    chrome.bandRim=CreateFrame("Frame",nil,band);chrome.band=band
end

local function buildPurse(frame, level)
    -- The toolbar supplies the only backing. No detached inset or gold rim.
    if _G.MerchantMoneyFrame then _G.MerchantMoneyFrame:SetParent(chrome.band) end
end

local function findCloseButton(frame)
    local known = frame.CloseButton or _G.MerchantFrameCloseButton
    if known then
        return known
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:IsObjectType("Button") and lowerPath(child:GetNormalTexture()):find("ui-panel-minimizebutton", 1, true) then
            return child
        end
    end
end

local function styleCloseButton(frame)
    local button = findCloseButton(frame)
    if not button then
        return
    end
    frame.CloseButton = button
    button:SetSize(16, 16)
    place(button, "TOPRIGHT", chrome.grid, "TOPRIGHT", -8, -11)
    button:SetFrameLevel(frame:GetFrameLevel() + 20)

    local sheet = art("UI\\redbutton2x")
    for _, look in ipairs(CLOSE_STATES) do
        local tex = button[look[1]](button)
        if tex then
            tex:SetTexture(sheet)
            tex:ClearAllPoints()
            tex:SetAllPoints(button)
            tex:SetTexCoord(look[2], look[3], look[4], look[5])
            if look[6] then
                tex:SetBlendMode(look[6])
            end
        end
    end
end

local function dressPager(button, direction)
    if not button then
        return
    end
    button:SetSize(24, 24)
    local backing = art("Merchant\\pagebutton-background")
    for _, tex in ipairs(texturesOf(button)) do
        if tex:GetDrawLayer() == "BACKGROUND" then
            tex:SetTexture(backing)
            tex:ClearAllPoints()
            tex:SetAllPoints(button)
            tex:Show()
        end
    end

    local stem = "Merchant\\pagebutton-" .. direction .. "-"
    button:SetNormalTexture(art(stem .. "normal"))
    button:SetPushedTexture(art(stem .. "pressed"))
    button:SetDisabledTexture(art(stem .. "disabled"))
    button:SetHighlightTexture(art("Merchant\\pagebutton-hover"))
    for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
        local texture = button[getter](button)
        if texture then texture:ClearAllPoints(); texture:SetAllPoints(button) end
    end
    local hover = button:GetHighlightTexture()
    if hover then
        hover:SetBlendMode("ADD")
    end
end

local function addQuestBang(button)
    local bang = button:CreateTexture(nil, "OVERLAY")
    bang:SetTexture(_G.TEXTURE_ITEM_QUEST_BANG or "Interface\\ContainerFrame\\QuestBang")
    bang:SetSize(37, 38)
    bang:SetPoint("TOP", button, "TOP", 0, 0)
    bang:Hide()
    button.IconQuestTexture = bang
end

local function reskinRow(prefix, isBuybackRow)
    local recess = _G[prefix .. "SlotTexture"]
    if recess then
        recess:SetTexture(art("Merchant\\emptyslot"))
    end

    local button = _G[prefix .. "ItemButton"]
    local ring = button and button:GetNormalTexture()
    if ring then
        ring:SetTexture(art("UI\\ui-quickslot2"))
        ring:SetSize(64, 64)
        place(ring, "CENTER", button, "CENTER", 0, -1)
    end

    local plate = _G[prefix .. "NameFrame"]
    if plate and isBuybackRow then
        plate:Hide()
    elseif plate then
        plate:SetTexture(art("Merchant\\labelslots"))
        plate:SetVertexColor(0.5, 0.5, 0.5, 1)
        plate:Show()
    end

    if button and not isBuybackRow and not button.IconQuestTexture then
        addQuestBang(button)
    end
end

local function questScanner()
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "DragonUI_MerchantQuestScan", UIParent, "GameTooltipTemplate")
    end
    -- A GameTooltip loses its owner whenever it hides and then reports no lines.
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    return scanTip
end

local function beginsQuest(link)
    local itemID = link and tonumber(link:match("item:(%d+)"))
    if not itemID then return false end
    if questAnswer[itemID] ~= nil then
        return questAnswer[itemID]
    end

    local tip = questScanner()
    tip:ClearLines()
    tip:SetHyperlink(link)
    local lineCount = tip:NumLines()
    local verdict = false
    for line = 2, lineCount do
        local left = _G["DragonUI_MerchantQuestScanTextLeft" .. line]
        if left and left:GetText() == ITEM_STARTS_QUEST then
            verdict = true
            break
        end
    end
    -- An uncached item answers with a one-line tooltip: that is "unknown", not "no".
    if verdict or lineCount > 1 then
        questAnswer[itemID] = verdict
    end
    return verdict
end

local function nameColour(link)
    if link then
        local quality = select(3, GetItemInfo(link))
        if quality ~= nil then
            local swatch = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
            if swatch then
                return swatch.r, swatch.g, swatch.b
            end
        else
            -- Uncached items have no quality yet, but the link already carries their colour.
            local r, g, b = link:match("^|c%x%x(%x%x)(%x%x)(%x%x)")
            if r then
                return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
            end
        end
    end
    local plain = NORMAL_FONT_COLOR
    return plain.r, plain.g, plain.b
end

local function tintName(label, link)
    if label then
        label:SetTextColor(nameColour(link))
    end
end

local function spaceRows(gap)
    for index = 3, 9, 2 do
        local row, above = _G["MerchantItem" .. index], _G["MerchantItem" .. (index - 2)]
        if not row or not above then
            return
        end
        row:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, gap)
    end
    local lastRow, above = _G.MerchantItem11, _G.MerchantItem9
    if lastRow and above then
        place(lastRow, "TOPLEFT", above, "BOTTOMLEFT", 0, gap)
    end
end

local function afterMerchantInfo()
    spaceRows(-8)
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10
    local offset = ((_G.MerchantFrame.page or 1) - 1) * perPage
    for row = 1, MERCHANT_ROWS do
        local link = GetMerchantItemLink(offset + row)
        tintName(_G["MerchantItem" .. row .. "Name"], link)
        local button = _G["MerchantItem" .. row .. "ItemButton"]
        local bang = button and button.IconQuestTexture
        toggle(bang, bang ~= nil and beginsQuest(link))
    end

    local stored = GetNumBuybackItems() or 0
    tintName(_G.MerchantBuyBackItemName, stored > 0 and GetBuybackItemLink(stored) or nil)
end

-- Catalog sorting passes real vendor identities into the existing row decoration.
parts.decorateVendorRow = function(row,index)
    local link=GetMerchantItemLink(index)
    tintName(_G["MerchantItem"..row.."Name"],link)
    local button=_G["MerchantItem"..row.."ItemButton"]
    local bang=button and button.IconQuestTexture
    toggle(bang,bang~=nil and beginsQuest(link))
end

local function afterBuybackInfo()
    spaceRows(-15)
    for row = 1, BUYBACK_ITEMS_PER_PAGE or ALL_ROWS do
        tintName(_G["MerchantItem" .. row .. "Name"], GetBuybackItemLink(row))
        local button = _G["MerchantItem" .. row .. "ItemButton"]
        if button and button.IconQuestTexture then
            button.IconQuestTexture:Hide()
        end
    end
end

local function clampLabel(label, width)
    if not label then
        return
    end
    label:SetWordWrap(false)
    if label.SetMaxLines then
        label:SetMaxLines(1)
    end
    label:SetWidth(width)
end

local function clampNames()
    for row = 1, ALL_ROWS do
        clampLabel(_G["MerchantItem" .. row .. "Name"], 196)
    end
    -- The recent-buyback footer slot is narrower than the inventory columns.
    clampLabel(_G.MerchantBuyBackItemName, 116)
end

local function glowPiece(tab, sheet, left, right, top, bottom)
    local glow = tab:CreateTexture(nil, "HIGHLIGHT")
    glow:SetTexture(sheet)
    glow:SetTexCoord(left, right, top, bottom)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(TAB_GLOW_ALPHA)
    glow:SetHeight(30)
    return glow
end

local function addTabGlow(tab, sheet, leftCap, rightCap)
    local west = glowPiece(tab, sheet, 0.015625, 0.5625, 0.816406, 0.933594)
    west:SetWidth(35)
    west:SetPoint("TOPLEFT", leftCap, "TOPLEFT", 0, 0)

    local east = glowPiece(tab, sheet, 0.015625, 0.59375, 0.667969, 0.785156)
    east:SetWidth(37)
    east:SetPoint("TOPLEFT", rightCap, "TOPLEFT", 0, 0)

    local between = glowPiece(tab, sheet, 0, 0.015625, 0.175781, 0.292969)
    between:SetPoint("TOPLEFT", west, "TOPRIGHT", 0, 0)
    between:SetPoint("TOPRIGHT", east, "TOPLEFT", 0, 0)

    tabGlow[tab] = { west, between, east }
end

local function dressTab(tab)
    local name = tab:GetName()
    tab:SetFrameLevel(tab:GetFrameLevel() + CONTROL_LIFT)
    for _, texture in ipairs(texturesOf(tab)) do texture:SetTexture(nil) end
    tab:SetBackdrop({bgFile=art("UI\\ui-background-rock"),
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=10,
        insets={left=2,right=2,top=2,bottom=2}})
    tab:SetNormalFontObject(GameFontNormalSmall)
    tab:SetHighlightFontObject(GameFontHighlightSmall)
    local label = _G[name .. "Text"]
    tabWidth[tab] = math.max(70, (label and label:GetStringWidth() or 50) + 20)
    tab:SetSize(tabWidth[tab], 22)
end

local function chainTabs(frame)
    local band = chrome.band
    if not band then return end
    local tabs, width = {}, 0
    for index = 1, 2 do
        local tab = _G["MerchantFrameTab" .. index]
        if tab and tab:IsShown() then
            tabs[#tabs+1] = tab
            width = width + (tabWidth[tab] or 66)
        end
    end
    width = width + math.max(0, #tabs-1) * 4
    local x = band:GetWidth() - width - 38
    for _, tab in ipairs(tabs) do
        place(tab, "BOTTOMLEFT", band, "BOTTOMLEFT", x, 20)
        tab:SetHeight(24)
        x = x + (tabWidth[tab] or 66) + 4
    end
end

local function syncTabs(selected)
    for index = 1, 2 do
        local tab = _G["MerchantFrameTab" .. index]
        if tab then
            local active = index == selected
            tab:SetNormalFontObject(GameFontNormalSmall)
            tab:SetHighlightFontObject(GameFontHighlightSmall)
            tab:SetDisabledFontObject(active and GameFontHighlightSmall or GameFontNormalSmall)
            tab:SetBackdropColor(active and 0.36 or 0.20, active and 0.31 or 0.19, active and 0.23 or 0.17, 1)
            tab:SetBackdropBorderColor(active and 0.72 or 0.38, active and 0.59 or 0.35, active and 0.33 or 0.29, 0.9)
            if tabWidth[tab] then tab:SetSize(tabWidth[tab], 22) end
            local label = _G[tab:GetName() .. "Text"]
            if label then place(label, "CENTER", tab, "CENTER", 0, 0) end
        end
    end
end

local function fitRepairIcons()
    for _, entry in ipairs(REPAIR_ICON_ATLAS) do
        local button = _G[entry[1]]
        local icon = entry[2] and _G[entry[2]]
        if button and not icon then
            for _, tex in ipairs(texturesOf(button)) do
                if lowerPath(tex):find("ui-merchant-repairicons", 1, true) then
                    icon = tex
                    break
                end
            end
        end
        if button and icon then
            local keys={ ["spellicon-256x256-repairall"]="RepairAll", ["spellicon-256x256-repair"]="RepairItem", ["spellicon-256x256-repairallguild"]="RepairGuild" }
            addon.MerchantStyle.ServiceIcon(icon,keys[entry[3]],button)
        end
    end
end

local function sinkButtons()end -- Generated service rims provide the only inset.

-- Blizzard re-anchors these every update and shrinks two to 32 when guild repair is available.
local function centerMoney()
    local money, band = _G.MerchantMoneyFrame, chrome.band
    if not money or not band or InCombatLockdown() then return end
    local coins, width = {}, 0
    for _, suffix in ipairs({"GoldButton", "SilverButton", "CopperButton"}) do
        local button = _G[money:GetName() .. suffix]
        if button and button:IsShown() then
            coins[#coins+1] = button
            width = width + button:GetWidth()
        end
    end
    -- Native code still supplies amounts, visibility and widths. Only arrange
    -- those existing buttons locally, avoiding scale/absolute-coordinate feedback.
    if #coins > 0 and width > 0 then
        money:SetSize(width, 16)
        local previous
        for _, button in ipairs(coins) do
            if previous then place(button, "LEFT", previous, "RIGHT", 0, 0)
            else place(button, "LEFT", money, "LEFT", 0, 0) end
            previous = button
        end
    end
    place(money, "CENTER", band, "CENTER", 0, 0)
end

local function arrangeRepairCluster()
    toggle(_G.MerchantRepairText, false)
    local window, band = _G.MerchantFrame, chrome.band
    if not window or not band then return end
    local buying, controls = window.selectedTab == 1, {}
    if buying then
        local repair = _G.CanMerchantRepair()
        for _, name in ipairs({"MerchantRepairItemButton", "MerchantRepairAllButton", "MerchantGuildBankRepairButton"}) do
            local button = _G[name]
            if button and repair and (name ~= "MerchantGuildBankRepairButton" or CanGuildBankRepair()) then
                controls[#controls+1] = button
            end
        end
        local junk = _G.DragonUI_MerchantSellAllJunkButton
        if junk then controls[#controls+1] = junk end
        if _G.MerchantBuyBackItem then controls[#controls+1] = _G.MerchantBuyBackItem end
    end
    local money = _G.MerchantMoneyFrame
    local moneyWidth = math.max(160, money and money:GetWidth() or 0)
    local tabsWidth = (tabWidth[_G.MerchantFrameTab1] or 66) + 4
        + (tabWidth[_G.MerchantFrameTab2] or 66)
    local iconsWidth = math.max(0, #controls * 40 - 8)
    band:SetWidth(684);band:SetHeight(64)
    local x = 38
    for _, button in ipairs(controls) do
        button:SetSize(32, 32)
        place(button, "BOTTOMLEFT", band, "BOTTOMLEFT", x, 16)
        if button.Icon then span(button.Icon, button, 4, -4, -4, 4) end
        x = x + 40
    end
    -- Keep last-item information on its native tooltip, with one compact icon
    -- in the top row instead of an inline name/price widening the whole panel.
    if _G.MerchantBuyBackItemName then _G.MerchantBuyBackItemName:Hide() end
    if _G.MerchantBuyBackItemMoneyFrame then _G.MerchantBuyBackItemMoneyFrame:Hide() end
    if money then
        money:SetWidth(moneyWidth)
        centerMoney()
    end
    chainTabs(window)
    if chrome.grid then span(chrome.grid, window, 10, 0, -10, buying and 106 or 76) end
end
-- Reuse the original frame, item buttons, money/currency widgets, tabs and
-- close script. ESC, merchant distance, bags, modifiers and confirmations stay native.
immersiveLayout = function()
    local window = _G.MerchantFrame
    if layoutBusy or not windowBuilt or not window or not window:IsShown() then return end
    if InCombatLockdown() then layoutPending = true; return end
    layoutPending = false
    layoutBusy = true
    releaseMerchantLocks(window)
    shapeWindow(window)
    -- A short lower-center panel keeps the NPC visible, leaving bag space at right.
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    local fit = math.min(1, math.max(0.4, (sw - 40) / WINDOW_W),
        math.max(0.4, (sh - 100) / WINDOW_H))
    window:SetScale(fit)
    local cfg = _G.ImmersionSetup
    local requested = cfg and tonumber(cfg.boxoffsetY) or 36
    bottomOffset = math.max(16, math.min(requested, sh - WINDOW_H * fit - 20))
    place(window, "BOTTOM", UIParent, "BOTTOM", 0, (bottomOffset + entranceOffset) / fit)
    local geometry=addon.MerchantStyle.Geometry(window.selectedTab==1)
    if window.CloseButton then place(window.CloseButton,"TOPRIGHT",chrome.grid,"TOPRIGHT",-8,window.selectedTab==1 and -11 or -6) end
    for index = 1, ALL_ROWS do
        local row = _G["MerchantItem" .. index]
        if row then
            local col = (index - 1) % 2
            local line = math.floor((index - 1) / 2)
            place(row, "TOPLEFT", window, "TOPLEFT", geometry.left + col * geometry.column, -geometry.top - line * geometry.stride)
            addon.MerchantStyle.Row(index,geometry)
        end
    end
    local function move(name, point, x, y)
        local widget = _G[name]
        if widget then place(widget, point, window, point, x, y) end
    end
    move("MerchantPrevPageButton", "BOTTOMLEFT", 22, 112)
    move("MerchantNextPageButton", "BOTTOMRIGHT", -22, 112)
    move("MerchantMoneyFrame", "BOTTOMRIGHT", -12, 10)
    local recent, recentButton = _G.MerchantBuyBackItem, _G.MerchantBuyBackItemItemButton
    if recent and recentButton then
        place(recent, "BOTTOMLEFT", window, "BOTTOMLEFT", 204, 44)
        recent:SetSize(32, 32)
        recentButton:SetSize(32, 32)
        local ring = recentButton:GetNormalTexture()
        if ring then ring:SetSize(48, 48); place(ring, "CENTER", recentButton, "CENTER", 0, 0) end
        local recess = _G.MerchantBuyBackItemSlotTexture
        if recess then recess:SetSize(42, 42); place(recess, "CENTER", recentButton, "CENTER", 0, 0) end
        place(recentButton, "BOTTOMLEFT", recent, "BOTTOMLEFT", 0, 0)
        if _G.MerchantBuyBackItemName then
            place(_G.MerchantBuyBackItemName, "TOPLEFT", recent, "TOPLEFT", 40, -1)
            _G.MerchantBuyBackItemName:SetHeight(16)
        end
        if _G.MerchantBuyBackItemMoneyFrame then
            place(_G.MerchantBuyBackItemMoneyFrame, "BOTTOMLEFT", recent, "BOTTOMLEFT", 40, 0)
        end
    end
    if chrome.pageHolder then
        chrome.pageHolder:Hide()
    end
    chainTabs(window)
    clampNames()
    arrangeRepairCluster()
    addon.MerchantStyle.Apply(chrome)
    layoutBusy = false
end

local function syncWindow()
    local window = _G.MerchantFrame
    hideReappearing()
    syncTabs(window.selectedTab)
    if window.Title then
        window.Title:SetText(titleText())
        chrome.header:SetWidth(math.min(WINDOW_W-20, math.max(280, window.Title:GetStringWidth()+32)))
    end
    local buying = window.selectedTab == 1
    toggle(chrome.wash, not buying)
    toggle(chrome.band, true)
    toggle(_G.DragonUI_MerchantSellAllJunkButton, buying)
    clampNames()
    refreshPortrait()
    if chrome.subtitle then
        chrome.subtitle:SetText(buying and (_G.MERCHANT or "Merchant") or (_G.BUYBACK or "Buyback"))
    end
    immersiveLayout()
end

local function buildWindow()
    local window = _G.MerchantFrame
    local insetLevel = window:GetFrameLevel() + 1

    paintBody(window)
    addStreaks(window)
    ensureTitle(window)
    seatPortrait(window)
    local subtitle = chrome.header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", chrome.header, "TOPLEFT", 12, -52)
    subtitle:SetTextColor(0.82, 0.77, 0.65)
    chrome.subtitle = subtitle
    chrome.header:Hide()
    -- Equal-level siblings stack by creation order, which is what keeps grid < band < purse.
    buildGrid(window, insetLevel)
    buildBand(window, insetLevel)
    buildPurse(window, insetLevel)
    styleCloseButton(window)
    dressPager(_G.MerchantPrevPageButton, "prev")
    dressPager(_G.MerchantNextPageButton, "next")

    for row = 1, ALL_ROWS do
        reskinRow("MerchantItem" .. row, false)
    end
    reskinRow("MerchantBuyBackItem", true)

    for index = 1, 2 do
        local tab = _G["MerchantFrameTab" .. index]
        if tab then
            dressTab(tab)
        end
    end
    chainTabs(window)

    fitRepairIcons()
    if parts.buildSellButton then
        parts.buildSellButton()
    end
    if parts.buildUndoArrow then
        parts.buildUndoArrow()
    end
    sinkButtons()
    -- Last, so the sell button is lifted too: at +1 it tied with the band and lost the draw order.
    liftControls()
end

local function startEntrance()
    local window = _G.MerchantFrame
    if not windowBuilt or not window:IsShown() then return end
    local cfg = _G.ImmersionSetup
    local instant = cfg and cfg.anidivisor and cfg.anidivisor <= 1
    entrance.elapsed = instant and 0.28 or 0
    entranceOffset = instant and 0 or -64
    immersiveLayout()
    refreshPortrait()
    if addon.VisibilityFade then addon.VisibilityFade.RefreshAll() end
    window:SetAlpha(instant and 1 or 0)
    -- Native panel placement can bypass Lua SetPoint hooks. Maintain only this
    -- visible merchant's bottom-center anchor after those layout passes. Keep
    -- the driver alive until native OnHide, even after the entrance completes.
    entrance:SetScript("OnUpdate", function(self, elapsed)
        if not window:IsShown() then
            self:SetScript("OnUpdate", nil)
            entranceOffset = 0
            window:SetAlpha(1)
            return
        end
        self.elapsed = math.min(0.28, self.elapsed + elapsed)
        local progress = self.elapsed / 0.28
        local eased = 1 - (1 - progress) ^ 3
        entranceOffset = -64 * (1 - eased)
        if not InCombatLockdown() then
            layoutBusy = true
            place(window, "BOTTOM", UIParent, "BOTTOM", 0,
                (bottomOffset + entranceOffset) / window:GetScale())
            layoutBusy = false
        end
        centerMoney()
        window:SetAlpha(math.min(1, progress * 1.4))
    end)
end

-- MerchantFrame registered MERCHANT_SHOW first, so the window is already shown and filled here.
local function onFirstMerchantShow(listener)
    listener:UnregisterEvent("MERCHANT_SHOW")
    listener:SetScript("OnEvent", nil)

    local ok, err = pcall(buildWindow)
    if not ok then
        addon:Error("Merchant build failed: " .. tostring(err))
        return
    end
    windowBuilt = true
    immersiveLayout()
    startEntrance()

    if _G.MerchantFrame:IsShown() then
        -- Retexturing the anvils dropped the grey OnShow gave them; these put it back.
        MerchantFrame_UpdateCanRepairAll()
        MerchantFrame_UpdateGuildBankRepair()
        MerchantFrame_Update()
    else
        syncWindow()
    end
end

local function prepareSession(frame)
    stripStockArt(frame)
    hideReappearing()
    shapeWindow(frame)
    anchorControls()
    housePageText(frame)
    liftControls()

    hooksecurefunc("MerchantFrame_Update", function()
        if windowBuilt then
            syncWindow()
        end
    end)
    hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
        if windowBuilt then
            afterMerchantInfo()
            immersiveLayout()
        end
    end)
    hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
        if windowBuilt then
            afterBuybackInfo()
            immersiveLayout()
        end
    end)
    hooksecurefunc("MerchantFrame_UpdateRepairButtons", arrangeRepairCluster)
    -- UIPanel placement runs again when bags or other panels open/close.
    -- Post-hook just this merchant's geometry; do not replace the panel manager.
    hooksecurefunc("UpdateUIPanelPositions", function()
        if windowBuilt then immersiveLayout() end
    end)
    -- BlizzMove and the UIPanel manager may SetPoint after OnShow callbacks.
    -- A guarded post-hook converges only this frame back to its chosen anchor.
    hooksecurefunc(frame, "SetPoint", function()
        if not layoutBusy and windowBuilt then immersiveLayout() end
    end)
    entrance = CreateFrame("Frame")
    frame:HookScript("OnShow", startEntrance)
    frame:HookScript("OnHide", function()
        entrance:SetScript("OnUpdate", nil)
        entranceOffset = 0
        frame:SetAlpha(1)
        if addon.VisibilityFade then addon.VisibilityFade.RefreshAll() end
    end)
    local layoutEvents = CreateFrame("Frame")
    layoutEvents:RegisterEvent("DISPLAY_SIZE_CHANGED")
    layoutEvents:RegisterEvent("UI_SCALE_CHANGED")
    layoutEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    layoutEvents:SetScript("OnEvent", function(_, event)
        if event ~= "PLAYER_REGEN_ENABLED" or layoutPending then immersiveLayout() end
    end)


    local listener = CreateFrame("Frame")
    listener:SetScript("OnEvent", onFirstMerchantShow)
    listener:RegisterEvent("MERCHANT_SHOW")
end

function addon.ApplyMerchantSystem()
    if not addon:IsModuleEnabled("merchant") then
        return
    end
    Merchant.applied = true

    local window = _G.MerchantFrame
    if Merchant.initialized or not window then
        return
    end
    Merchant.initialized = true
    prepareSession(window)
end

function addon.RestoreMerchantSystem()
    Merchant.applied = false
end

local loginWatcher = CreateFrame("Frame")
loginWatcher:RegisterEvent("PLAYER_LOGIN")
loginWatcher:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    addon.ApplyMerchantSystem()
end)
