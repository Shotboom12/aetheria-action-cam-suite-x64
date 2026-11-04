-- Copyright (c) 2026 NeticSoul. Licensed under the MIT License; see LICENSE.
-- Rewritten from a base module contributed by PentSec, with thanks.

local addon = select(2, ...)
local L = addon.L

-- Retail's Map & Quest Log over the windowed map; nothing here writes what Blizzard's map reads.

local WorldMapModule = { initialized = false, applied = false }
addon.WorldMap = addon.WorldMap or {}
local WM = addon.WorldMap

if addon.RegisterModule then
    addon:RegisterModule("worldmap", WorldMapModule,
        L["World Map"],
        L["Retail-style world map with breadcrumb navigation and a quest log side panel"],
        { lifecyclePrefix = "WorldMap", loadOnce = true })
end

-- FSP1: native-feeling fullscreen viewport, with the ORIGINAL DragonUI canvas,
-- quest log, cursor coordinates, mousewheel zoom and map drag retained.
-- This is still the *client's windowed map mode*. Switching to Blizzard's
-- fullscreen size would disable DragonUI's zoom.lua and side quest log.
-- FSP4: retire the dead ornamental title row. Nav sits in the top 40 UI
-- units, with the map directly below it. Preserve map tile aspect ratio.
-- FSP5: add a thin, crisp full-frame border polish.
-- FSP6: replace the procedural lines with a thin textured frame derived
-- from the user-provided ForeverFlavor chrome assets.
-- FSP7: make that border visibly read in-game by increasing its scale slightly
-- and layering subtle crisp linework beneath it for contrast on bright maps.
-- FSP10: tight FF sprite crops, continuous four-sided rail above nav chrome.
WM.SPACER_H = 52
WM.INSET_L, WM.INSET_R, WM.INSET_B = 0, 0, 0
WM.PANEL_W = 330 -- reflowed at runtime to absorb otherwise empty horizontal space
WM.QUEST_PANEL_MIN = 330
WM.FRAME_X, WM.FRAME_Y = 0, 0
WM.DETAIL_W, WM.DETAIL_H = 1002, 668
local VIEWPORT_BOTTOM_MARGIN, VIEWPORT_RIGHT_MARGIN = 0, 0
local MAP_REPLACERS = { "Mapster" }
local ROCK = addon._dir .. "UI\\ui-background-rock"
local BASE_LEVEL = 10

local function CP()
    return addon.CharacterPanel
end

local function loadedReplacer()
    for _, candidate in ipairs(MAP_REPLACERS) do
        if IsAddOnLoaded(candidate) then return candidate end
    end
end

function WM:Config()
    return addon:GetModuleConfig("worldmap") or {}
end

function WM:Enabled()
    return addon:IsModuleEnabled("worldmap")
end

-- Booted, so the quest pick shown on the map is ours; its hooks stay until the reload.
function WM.IsApplied()
    return WorldMapModule.applied == true
end

-- The client's one "am I windowed" test, read and never written.
function WM.IsWindowed()
    return WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE
end

-- FSP10 diagnostics: read-only status for the validated overlay hierarchy.
-- Intentionally read-only: status reports do not force/show/toggle frames.
SLASH_DRAGONUI_FSP3_STATUS1 = "/dfmap"
SlashCmdList.DRAGONUI_FSP3_STATUS = function()
    local function flag(object)
        if not object then return "nil" end
        return (object:IsShown() and "shown" or "hidden") .. "/"
            .. (object:IsVisible() and "visible" or "invisible")
            .. "/" .. (object:GetFrameStrata() or "?")
    end
    local f = _G.WorldMapFrame
    local out = "|cffffd56eDragonUI FSP13|r "
    local function say(line)
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(out .. line) end
    end
    say("map=" .. flag(f) .. " windowed=" .. tostring(WM.IsWindowed())
        .. " chrome=" .. flag(WM.border))
    say("quest=" .. flag(_G.DragonUIWorldMapQuestLog)
        .. " nav=" .. flag(_G.DragonUIWorldMapNavBar)
        .. " coords=" .. flag(_G.DragonUIWorldMapCoords)
        .. " close=" .. flag(_G.WorldMapFrameCloseButton))
    if WM.border then
        say("chrome parent=" .. (WM.border:GetParent() == UIParent and "UIParent" or "OTHER")
            .. " alpha=" .. tostring(WM.border:GetAlpha())
            .. " size=" .. tostring(math.floor(WM.border:GetWidth())) .. "x"
            .. tostring(math.floor(WM.border:GetHeight())))
    end
end

-- Geometric, so the chrome answers for the canvas under it even though it takes no mouse itself.
function WM.CursorOverMap()
    if WM.border and WM.border:IsShown() then return WM.border:IsMouseOver() end
    return WorldMapFrame:IsMouseOver()
end

-- Overlays belong to the terrain view; Dalaran has none, its city and Underbelly are both floors.
function WM.OnTerrainFloor()
    local level = GetCurrentMapDungeonLevel()
    if DungeonUsesTerrainMap() then level = level - 1 end
    return level <= 0
end

-- WorldMap_OpenToQuest writes WorldMapFrame.blockWorldMapUpdate, re-read by its every WORLD_MAP_UPDATE.
function WM.OpenToQuest(questID)
    local shown = WorldMapFrame:IsShown()
    -- Only showing the map is protected; an open one moves freely in combat.
    if not questID or (InCombatLockdown() and not shown) then return false end
    -- Not a getter: it moves the map whatever it answers, so a quest it cannot place must not strand you.
    local before = (GetCurrentMapAreaID() or 0) - 1
    local area, floor = GetQuestWorldMapAreaID(questID)
    if area and area > 0 then
        SetMapByID(area)
        if floor and floor > 0 then SetDungeonMapLevel(floor) end
    elseif before > 0 then
        SetMapByID(before)
    end
    if not shown then ShowUIPanel(WorldMapFrame) end
    return true
end

-- ============================================================================
-- GEOMETRY
-- ============================================================================

local function canvasSize()
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    local shown = WM.PanelShown()
    local minimumPanel = shown and WM.QUEST_PANEL_MIN or 0
    -- Always protect aspect ratio. The extra width on widescreens is offered
    -- to the right-hand quest log rather than left as a 40-100 px dead gutter.
    local totalW = math.max(100, sw - WM.FRAME_X - WM.INSET_L - WM.INSET_R
        - VIEWPORT_RIGHT_MARGIN)
    local roomW = math.max(100, totalW - minimumPanel)
    local roomH = math.max(100, sh - WM.FRAME_Y - WM.SPACER_H
        - WM.INSET_B - VIEWPORT_BOTTOM_MARGIN)
    local scale = math.min(roomW / WM.DETAIL_W, roomH / WM.DETAIL_H)
    local width = math.floor(WM.DETAIL_W * scale)
    local height = math.floor(WM.DETAIL_H * scale)
    if shown then
        -- At 2003x1125 (screenshot's effective UI size), this reclaims the
        -- previously empty ~45-100 px vertical gutter, depending on header.
        -- Never make the quest panel narrower than DragonUI's tested layout.
        WM.PANEL_W = WM.QUEST_PANEL_MIN + math.max(0, math.floor(totalW - minimumPanel - width))
    else
        WM.PANEL_W = WM.QUEST_PANEL_MIN
    end
    return width, height
end

-- Both passes write implicitly protected frames, so both are combat-deferred.
local canvasW, canvasH

local function scaleArrows(value)
    for _, name in ipairs({ "PlayerArrowFrame", "PlayerArrowEffectFrame" }) do
        local arrow = _G[name]
        if arrow then arrow:SetScale(value) end
    end
end

local function layoutCanvas()
    local f = WorldMapFrame
    local detail = WorldMapDetailFrame
    canvasW, canvasH = canvasSize()
    WM.canvasW, WM.canvasH = canvasW, canvasH
    local scale = canvasW / WM.DETAIL_W * (WM.zoom or 1)
    WM.canvasScale = scale
    -- WorldMapButton_OnUpdate multiplies POI and arrow offsets by this size; ours differs by it.
    WM.poiScale = scale / WORLDMAP_SETTINGS.size

    detail:SetScale(scale)
    detail:ClearAllPoints()
    if not (WM.LayoutZoom and WM.LayoutZoom()) then
        detail:SetPoint("TOPLEFT", f, "TOPLEFT", (WM.FRAME_X + WM.INSET_L) / scale, -(WM.FRAME_Y + WM.SPACER_H) / scale)
    end
    WorldMapButton:SetScale(scale)
    WorldMapBlobFrame:SetScale(scale)
    -- Blizzard recomputes the blob hit box when this is nil, which keeps the value secure.
    WorldMapBlobFrame.xRatio = nil
    -- The window's scale whatever it hangs off: zoom.lua moves it out from under the button.
    local area = WorldMapFrameAreaFrame
    area:SetScale(f:GetEffectiveScale() / area:GetParent():GetEffectiveScale())

    scaleArrows(WM.poiScale)
    if WM.RefreshPlayerArrow then WM.RefreshPlayerArrow() end
    if WM.SizeGroupPins then WM.SizeGroupPins() end
    if WM.RefreshPins then WM.RefreshPins() end
    if WM.RefreshMapPins then WM.RefreshMapPins() end
    if WM.RefreshBlobs then WM.RefreshBlobs() end
end

local function windowSize()
    -- The shell, unlike the map canvas, always covers the ENTIRE viewport.
    return UIParent:GetWidth() - WM.FRAME_X, UIParent:GetHeight() - WM.FRAME_Y
end

-- One placement owner for startup, resize and sidebar toggling.
function WM.LayoutSidebar()
    local quest=_G.DragonUIWorldMapQuestLog
    if not quest or not WM.border then return end
    local left=WM.canvasW or (WM.border:GetWidth()-WM.PANEL_W)
    local width=math.max(140,WM.border:GetWidth()-left-8)
    if math.abs(quest:GetWidth()-width)>.5 then quest:SetWidth(width) end
    quest:ClearAllPoints()
    quest:SetPoint("TOPRIGHT",WM.border,"TOPRIGHT",-8,-52)
    quest:SetPoint("BOTTOMRIGHT",WM.border,"BOTTOMRIGHT",-8,8)
    if WM.closeButton then
        WM.closeButton:ClearAllPoints()
        WM.closeButton:SetPoint("TOPRIGHT",WM.border,"TOPRIGHT",-14,-14)
    end
end

-- The chrome is ours and follows the panel at once; the frame under it is protected in combat.
local function layoutChrome()
    local w, h = windowSize()
    WM.border:SetSize(w, h)
    local panel = WM.PanelShown() and WM.PANEL_W or 0
    WM.spacer:SetPoint("BOTTOMRIGHT", WM.border, "TOPRIGHT", -(WM.INSET_R + panel), -WM.SPACER_H)
    WM.sideToggle:SetPoint("BOTTOMRIGHT", WM.border, "BOTTOMRIGHT", -(WM.INSET_R + panel + 14), WM.INSET_B + 16)
    -- Original DragonUI quest log listens to the panel's actual dimensions.
    -- Reflow only its width; preserve search, scrollbar, quest cards and clicks.
    WM.LayoutSidebar()
    if WM.OnLayout then WM.OnLayout() end
    if WM.LayoutPanelDivider then WM.LayoutPanelDivider() end
end

local function layoutWindow()
    local w, h = windowSize()
    WorldMapFrame:SetSize(WM.FRAME_X + w, WM.FRAME_Y + h)
    layoutChrome()
end

function WM.Layout(canvasChanged)
    if not (WM.border and WM.IsWindowed()) then return end
    if InCombatLockdown() then
        addon.CombatQueue:Add("worldmap_layout", WM.Layout, canvasChanged or WM.canvasDirty)
        WM.canvasDirty = WM.canvasDirty or canvasChanged
        if canvasW and not WM.canvasDirty then layoutChrome() end
        return
    end
    WM.canvasDirty = nil
    if canvasChanged or not canvasW then layoutCanvas() end
    layoutWindow()
end

-- ============================================================================
-- CHROME
-- ============================================================================

-- Hidden parent rather than a swapped Show: that method taints every secure caller reaching it.
local holder = CreateFrame("Frame", "DragonUIWorldMapHolder", UIParent)
holder:Hide()

local RETIRED = {
    "WorldMapZoneMinimapDropDown", "WorldMapContinentDropDown", "WorldMapZoneDropDown",
    "WorldMapZoomOutButton", "WorldMapMagnifyingGlassButton", "WorldMapLevelDropDown",
    "WorldMapLevelUpButton", "WorldMapLevelDownButton", "WorldMapFrameSizeUpButton",
    "WorldMapFrameSizeDownButton", "WorldMapTrackQuest", "WorldMapTitleButton",
}

-- Parked here between filter-menu visits; only a real click on it runs its OnClick clean.
local function retirePermanently()
    if WorldMapQuestShowObjectives:GetParent() == holder then return end
    WorldMapQuestShowObjectives:SetParent(holder)
end

-- _NPCScan.Overlay anchors this toggle to the objectives box, so it lives in the filter menu too.
function WM.NPCScanToggle()
    local overlay = _NPCScan and _NPCScan.Overlay
    local module = overlay and overlay.Modules and overlay.Modules.List and overlay.Modules.List.WorldMap
    return module and module.Loaded and module.Toggle or nil
end

-- Past VARIABLES_LOADED: that handler reads GetChecked() into WatchFrame.showObjectives.
local function retireAfterLogin()
    if IsLoggedIn() then
        retirePermanently()
        return
    end
    local waiter = CreateFrame("Frame")
    waiter:RegisterEvent("PLAYER_LOGIN")
    waiter:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        retirePermanently()
    end)
end

local function retireBlizzardWidgets()
    for _, name in ipairs(RETIRED) do
        _G[name]:SetParent(holder)
    end
    local npcScan = WM.NPCScanToggle()
    if npcScan then npcScan:SetParent(holder) end
    WorldMapFrameTitle:Hide()
    WorldMapFrameMiniBorderLeft:Hide()
    WorldMapFrameMiniBorderRight:Hide()
end

-- The client's fullscreen map still needs its own controls.
local function restoreBlizzardWidgets()
    for _, name in ipairs(RETIRED) do
        _G[name]:SetParent(WorldMapFrame)
    end
    local npcScan = WM.NPCScanToggle()
    if npcScan then
        npcScan:SetParent(WorldMapFrame)
        -- A menu loan sets its strata explicitly, which a new parent may not override.
        npcScan:SetFrameStrata(WorldMapFrame:GetFrameStrata())
    end
    WorldMapFrameTitle:Show()
end

-- The advanced map is a "center" panel the manager never re-anchors, so a drag keeps its spot.
local function savePosition()
    local f = WorldMapFrame
    WM:Config().position = { x = f:GetLeft(), y = f:GetTop() - UIParent:GetHeight() }
end

function WM.Place()
    -- Window manager / UIPanel logic can move the 3.3.5a map on open.
    -- Re-pin to the full UIParent after the client's mini-mode pass.
    if InCombatLockdown() then
        addon.CombatQueue:Add("worldmap_place", WM.Place)
        return
    end
    local f = WorldMapFrame
    f:SetMovable(false) -- Zone-map drag is still WorldMapButton's PAN, not frame movement.
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    -- Keep the native map canvas BELOW the DragonUI chrome. FSP1 raised both
    -- to FULLSCREEN_DIALOG; the large native WorldMapButton/detail frame could
    -- then occlude quest log, breadcrumbs, coords and close controls. The map
    -- remains fullscreen and zoom/pan remain in the original handlers.
    -- The independent DragonUI UIParent overlay stays FULLSCREEN_DIALOG.
    f:SetFrameStrata("FULLSCREEN")
    f:EnableMouse(true) -- block clicks through full-screen stone gutters.
end

-- FSP11: use one continuous rail family from ForeverFlavor's upper frame.
-- FSP10 mixed independently cropped sprites: its top included a second rail,
-- and nonuniform corner scaling moved the rail endpoints away from the edges.
-- Keep a common 2/3 source-pixel scale across corners and rail thickness.
-- Mirror the matching upper-left corner instead of mixing unlike atlas cells.
local FF_FRAME_TEX = "Interface\\AddOns\\DragonUI\\modules\\worldmap\\textures\\ff_chrome_frame"
local FF_SHEET_W, FF_SHEET_H = 1024, 512
local FF_CORNER = 32 * 2 / 3
local FF_TOP = 8
local FF_BOTTOM = 8
local FF_SIDE = 8

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

local function BuildPolishBorder(parent)
    local holder = CreateFrame("Frame", nil, parent)
    -- FSP13: move only the decorative rail outward; keep controls and map fixed.
    -- Three UI units leave a visible rim while clearing the right-side controls.
    local outset = 3
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", -outset, outset)
    holder:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", outset, -outset)
    -- DragonUI's nav-bar rim uses BASE_LEVEL+33. The prior polish frame
    -- was at BASE_LEVEL+8, behind that rim, hiding the full top edge.
    -- An overlay at +60 draws *above* the rim while taking NO mouse input.
    holder:SetFrameLevel(parent:GetFrameLevel() + 60)
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

-- Continue the outer frame's bevel through the narrow map/quest-panel join.
function WM.LayoutPanelDivider()
    local quest=_G.DragonUIWorldMapQuestLog
    if not quest or not WM.border then return end
    local divider=WM.panelDivider
    if not divider then
        divider=CreateFrame("Frame",nil,WM.border)
        divider:SetFrameLevel(WM.border:GetFrameLevel()+10)
        divider:EnableMouse(false)
        local rail=divider:CreateTexture(nil,"OVERLAY")
        rail:SetTexture(WM.Style.ART.."MapBronzeHD.tga")
        rail:SetTexCoord(0,.078125,.3,.7)
        rail:SetAllPoints(divider)
        WM.panelDivider=divider
    end
    divider:ClearAllPoints()
    divider:SetPoint("TOPLEFT",WM.border,"TOPLEFT",(WM.canvasW or 0)-3,-52)
    divider:SetPoint("BOTTOMLEFT",WM.border,"BOTTOMLEFT",(WM.canvasW or 0)-3,8)
    divider:SetWidth(6)
    divider:SetShown(WM.PanelShown())
end

local function buildChrome()
    local f = WorldMapFrame

    -- The stone sits at the map's own level so the detail frame draws over it.
    local ground = CreateFrame("Frame", "DragonUIWorldMapGround", f)
    ground:SetFrameLevel(f:GetFrameLevel())
    ground:EnableMouse(false)
    WM.ground = ground

    -- FSP3: map chrome must NOT be a child of the native WorldMapFrame.
    -- Raising a CHILD's strata (FSP2) did not restore its quest log/nav/coords
    -- in the actual client. An independent UIParent overlay escapes native map
    -- drawing/visibility ownership but retains DragonUI's original child tree.
    local border = CreateFrame("Frame", "DragonUIWorldMapBorder", UIParent)
    border:SetFrameStrata("FULLSCREEN_DIALOG")
    border:SetFrameLevel(BASE_LEVEL)
    border:SetPoint("TOPLEFT", f, "TOPLEFT", WM.FRAME_X, -WM.FRAME_Y)
    border:EnableMouse(false)
    WM.border = border
    -- The root is independent now; it must never appear with the map closed.
    border:Hide()
    WM.polishBorder = WM.Style.Frame(border,border,22,true)
    WM.header = WM.Style.Header(border)

    -- Opaque black underlay guarantees that unit frames, action bars and the
    -- rendered world do not shine through empty canvas/gutter areas.
    local underlay = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    underlay:SetTexture("Interface\\Buttons\\WHITE8X8")
    underlay:SetVertexColor(0.025, 0.020, 0.014, 1)
    underlay:SetAllPoints(f)
    WM.underlay = underlay

    ground:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    ground:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    local rock = ground:CreateTexture(nil, "BACKGROUND")
    rock:SetTexture(WM.Style.ART.."MapPaperHD.tga", "REPEAT", "REPEAT")
    rock:SetHorizTile(true)
    rock:SetVertTile(true)
    rock:SetAllPoints(ground)

    -- Fullscreen has no floating window border/title. Navigation and quest log
    -- carry their own independent DragonUI styling; avoid an empty gold rail.

    -- Retail's TitleCanvasSpacerFrame: the band the breadcrumb lives in, stopping at the canvas.
    local spacer = CreateFrame("Frame", "DragonUIWorldMapSpacer", border)
    spacer:SetPoint("TOPLEFT", border, "TOPLEFT", WM.INSET_L, 0)
    spacer:SetFrameLevel(BASE_LEVEL + 1)
    spacer:EnableMouse(true)
    WM.spacer = spacer

    local separator = border:CreateTexture(nil, "BACKGROUND", nil, -5)
    separator:SetAlpha(0)
    separator:SetTexture(WM.Style.ART.."MapBorderHD.tga")
    separator:SetTexCoord(.2,.8,0,.012)
    separator:SetHeight(3)
    separator:SetPoint("TOPLEFT", border, "TOPLEFT", WM.INSET_L, -(WM.SPACER_H - 4))
    separator:SetPoint("RIGHT", spacer, "RIGHT", 0, 0)

    -- The dedicated Map & Quest Log title row/drag handle is retired.
    -- Quest search and breadcrumbs are now the only header controls.

    -- Textures only: the close button's secure OnClick is what closes the map in combat.
    -- The stock button stays on the native map. A secure click proxy lives on
    -- DragonUI's independent visible chrome and invokes that same native button.
    local close = CreateFrame("Button","DragonUIWorldMapCloseButton",border,"SecureActionButtonTemplate")
    close:SetAttribute("type","click")
    close:SetAttribute("clickbutton",WorldMapFrameCloseButton)
    for _,state in ipairs({"Normal","Pushed","Disabled","Highlight"}) do close["Set"..state.."Texture"](close,ROCK) end
    CP().ModernizeCloseButton(close,border,-14,-14)
    close:SetFrameStrata("FULLSCREEN_DIALOG");close:SetFrameLevel(BASE_LEVEL+80)
    WM.closeButton=close

    WM.maxMin = WM.BuildMaxMinButton(border, close)
    WM.maxMin:Hide() -- no duplicate maximize/resize mode in fullscreen.
    WM.sideToggle = WM.BuildSideToggle(border)
end

local function chromeAlpha(opacity)
    local alpha = 0.5 + (1 - (opacity or 0)) * 0.5
    WM.border:SetAlpha(alpha)
    WM.ground:SetAlpha(alpha)
end

-- ============================================================================
-- CONTROLS
-- ============================================================================

local function setButtonState(button, atlas)
    button:GetNormalTexture():SetAtlasTexture(atlas)
    button:GetPushedTexture():SetAtlasTexture(atlas .. "-pressed")
    button:GetDisabledTexture():SetAtlasTexture(atlas .. "-disabled")
end

function WM.BuildMaxMinButton(border, close)
    local button = CreateFrame("Button", "DragonUIWorldMapMaximizeButton", border)
    button:SetSize(24, 24)
    button:SetPoint("RIGHT", close, "LEFT", -1, 0)
    button:SetFrameLevel(BASE_LEVEL + 5)
    button:SetNormalTexture(ROCK)
    button:SetPushedTexture(ROCK)
    button:SetDisabledTexture(ROCK)
    button:SetHighlightTexture(ROCK)
    button:GetHighlightTexture():SetAtlasTexture("redbutton-highlight")
    button:GetHighlightTexture():SetBlendMode("ADD")

    local function refresh()
        setButtonState(button, WM:Config().maximized and "redbutton-condense" or "redbutton-expand")
    end
    button:SetScript("OnClick", function()
        -- Rescaling the canvas writes the protected blob frame; the client refuses that in combat.
        if InCombatLockdown() then
            UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.1, 0.1, 1.0)
            return
        end
        WM:Config().maximized = not WM:Config().maximized
        refresh()
        WM.Layout(true)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(WM:Config().maximized and MINIMIZE or L["Maximize"])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    refresh()
    return button
end

function WM.BuildSideToggle(border)
    local button = CreateFrame("Button", "DragonUIWorldMapQuestLogToggle", border)
    button:SetSize(24, 24)
    button:SetFrameLevel(BASE_LEVEL + 5)
    button:SetNormalTexture(ROCK)
    button:SetPushedTexture(ROCK)
    button:SetHighlightTexture(ROCK)
    button:GetHighlightTexture():SetBlendMode("ADD")

    -- On the frame like its left twin, not the button: the button's level put it over the bottom rail.
    local shadow = border:CreateTexture(nil, "ARTWORK")
    shadow:SetAtlasTexture("mapcornershadow-right", true)
    shadow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 5, -5)

    -- No highlight cell in the sheet, so the arrow brightens itself and follows the pressed art.
    function button:SetHighlightArt(pressed)
        local state = WM.PanelShown() and "hide" or "show"
        self:GetHighlightTexture():SetAtlasTexture("questcollapse-" .. state .. (pressed and "-down" or "-up"))
    end

    function button:Refresh()
        local state = WM.PanelShown() and "hide" or "show"
        self:GetNormalTexture():SetAtlasTexture("questcollapse-" .. state .. "-up")
        self:GetPushedTexture():SetAtlasTexture("questcollapse-" .. state .. "-down")
        self:SetHighlightArt(false)
    end
    button:SetScript("OnMouseDown", function(self) self:SetHighlightArt(true) end)
    button:SetScript("OnMouseUp", function(self) self:SetHighlightArt(false) end)
    button:SetScript("OnClick", function()
        WM.SetPanelShown(not WM.PanelShown())
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(WM.PanelShown() and L["Hide Quest Log"] or L["Show Quest Log"])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:Refresh()
    return button
end

function WM.PanelShown()
    return WM:Config().questLog ~= false
end

-- The panel is ours and shows at once; the window width it needs is the protected part.
function WM.SetPanelShown(shown)
    -- Maximized, the canvas is sized around the panel, and the canvas is protected in combat.
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.1, 0.1, 1.0)
        return
    end
    WM:Config().questLog = shown and true or false
    WM.sideToggle:Refresh()
    if WM.SetQuestLogShown then WM.SetQuestLogShown(shown) end
    WM.Layout(true)
end

-- ============================================================================
-- BLIZZARD SIZE MODES
-- ============================================================================

-- The size keybind still reaches Blizzard's fullscreen map, where our chrome gets out of the way.
local function onWindowedChanged()
    -- Its release would hand lent widgets back to the parents they had before this switch.
    addon.Menu.Close()
    -- The clip is sized to the windowed canvas and would crop Blizzard's fullscreen map.
    if WM.ResetZoom then WM.ResetZoom() end
    local windowed = WM.IsWindowed()
    if windowed then
        -- UIParent-parented chrome is explicitly gated by map visibility.
        WM.border:SetShown(WorldMapFrame:IsShown())
        WM.ground:Show()
        retireBlizzardWidgets()
        WM.Place()
        -- Both size toggles re-anchor the close button to the chrome they just showed.
        if WM.closeButton then
            WM.closeButton:ClearAllPoints()
            WM.closeButton:SetPoint("TOPRIGHT",WM.border,"TOPRIGHT",-14,-14)
        end
        WM.Layout(true)
    else
        WM.border:Hide()
        WM.ground:Hide()
        -- Blizzard never touches this scale, so our canvas compensation would follow it into fullscreen.
        scaleArrows(1)
        -- No canvas layout runs fullscreen, so the pins take Blizzard's scale here.
        if WM.SizeGroupPins then WM.SizeGroupPins() end
        restoreBlizzardWidgets()
    end
    if WM.OnModeChanged then WM.OnModeChanged(windowed) end
end

local function installHooks()
    retireAfterLogin()
    hooksecurefunc("WorldMap_ToggleSizeUp", onWindowedChanged)
    hooksecurefunc("WorldMap_ToggleSizeDown", onWindowedChanged)
    -- Every windowed re-layout of Blizzard's runs through here and re-anchors the canvas.
    hooksecurefunc("WorldMapFrame_SetMiniMode", function()
        if WM.IsWindowed() then
            WM.Place()
            WM.Layout(true)
        end
    end)
    hooksecurefunc("WorldMapFrame_SetOpacity", chromeAlpha)

    local events = CreateFrame("Frame")
    events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    events:RegisterEvent("UI_SCALE_CHANGED")
    events:SetScript("OnEvent", function()
        WM.Place()
        WM.Layout(true)
    end)
    -- The map frame is a Blizzard UIPanel; other addons/CVars may re-anchor it
    -- when shown. Keep the fullscreen viewport on top with no global overrides.
    WorldMapFrame:HookScript("OnShow", function()
        WM.Place()
        WM.Layout(true)
        if WM.IsWindowed() and WM.border then
            WM.border:Show()
        end
    end)
    WorldMapFrame:HookScript("OnHide", function()
        -- The floating overlay must follow Blizzard's actual map lifetime.
        -- This also covers map close during loading screens and other addons.
        if WM.border then WM.border:Hide() end
    end)
end

-- ============================================================================
-- BOOT
-- ============================================================================

-- Blizzard reads these once, at VARIABLES_LOADED, and toggles itself down there; later costs a reload.
local function prepareWindowedMode()
    if not GetCVarBool("miniWorldMap") then SetCVar("miniWorldMap", 1) end
    if not GetCVarBool("advancedWorldMap") then SetCVar("advancedWorldMap", 1) end
end

local function boot()
    -- OnInitialize refreshes every module at our own ADDON_LOADED, when addons after us are still
    -- unloaded and no map replacer would be seen. Only the CVars are worth doing that early.
    if not IsLoggedIn() then
        prepareWindowedMode()
        return
    end
    if InCombatLockdown() then
        addon.CombatQueue:Add("worldmap_boot", boot)
        return
    end
    if WorldMapModule.initialized then return end
    WorldMapModule.initialized = true

    -- They reparent the same frame and drag it out of windowed mode on login; the two cannot share it.
    local replacer = loadedReplacer()
    if replacer then
        addon:Print(format(L["World map module disabled: %s replaces the same map frame."], replacer))
        return
    end

    prepareWindowedMode()

    buildChrome()
    installHooks()
    if WM.BuildNavBar then WM.BuildNavBar() end
    if WM.BuildPins then WM.BuildPins() end
    if WM.BuildQuestLog then
        WM.BuildQuestLog()
        WM.LayoutSidebar()
    end
    if WM.BuildFog then WM.BuildFog() end
    if WM.BuildMapPins then WM.BuildMapPins() end
    if WM.BuildCoords then WM.BuildCoords() end
    if WM.BuildPlayerArrow then WM.BuildPlayerArrow() end
    if WM.BuildGroupPins then WM.BuildGroupPins() end
    if WM.BuildFade then WM.BuildFade() end
    if WM.BuildZoom then WM.BuildZoom() end

    chromeAlpha(WORLDMAP_SETTINGS.opacity)
    onWindowedChanged()
    WorldMapModule.applied = true
end

function addon.ApplyWorldMapSystem()
    if WM:Enabled() and not WorldMapModule.applied then boot() end
end

function addon.RefreshWorldMapSystem()
    if not WorldMapModule.applied then
        addon.ApplyWorldMapSystem()
        return
    end
    WM.RefreshLandmarks()
    WM.RefreshFog()
    WM.RefreshMapPins()
    WM.RefreshNavBar()
    WM.RefreshZoneLabel()
    WM.RefreshCoords()
    WM.RefreshGroupPins()
    WM.RefreshFade()
end

-- Hooks and reparented widgets cannot be undone in-session, so a disable waits for the reload.
function addon.RestoreWorldMapSystem()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    addon.ApplyWorldMapSystem()
end)
