-- DragonUI Immersive Character Screen
-- Presentation-only companion: all gameplay data and clicks remain on DragonUI/Blizzard widgets.

local addonName = ...
local DragonUI = _G.DragonUI
local CP = DragonUI and DragonUI.CharacterPanel
if not (DragonUI and CP and DragonUICharacterScreen_ComputeLayout) then return end

local PARCHMENT = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\CharacterParchmentHD"
local PARCHMENT_BORDER = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\CharacterBorderHD"
local SECTION_BANNER = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\SectionBannerHD"
local CHROME_STRIP = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\ChromeStripHD"
local EQUIPMENT_BORDER = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\EquipmentBorderHD"
local EQUIPMENT_BACKING = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\EquipmentBackingHD"
local WEAPON_BACKING = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\WeaponBackingHD"
local PORTRAIT_RING = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\PortraitRingHD_Smooth"
local PARCHMENT_ALPHA = 0.82
local ROCK = "Interface\\AddOns\\DragonUI\\Textures\\UI\\ui-background-rock"

local LEFT_COLUMN = {
    "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot", "CharacterBackSlot",
    "CharacterChestSlot", "CharacterShirtSlot", "CharacterTabardSlot", "CharacterWristSlot",
}
local RIGHT_COLUMN = {
    "CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
    "CharacterFinger0Slot", "CharacterFinger1Slot", "CharacterTrinket0Slot", "CharacterTrinket1Slot",
}
local WEAPON_ROW = {
    "CharacterMainHandSlot", "CharacterSecondaryHandSlot", "CharacterRangedSlot",
}
local AUXILIARY_SLOTS = { "CharacterAmmoSlot" }

-- Pet and Currency intentionally live in the top utility cluster, not this footer.
local FOOTER_TABS = {
    { index = 1, label = CHARACTER or "Character" },
    { index = 3, label = REPUTATION or "Reputation" },
    { index = 4, label = SKILLS or "Skills" },
    { index = 6, label = HONOR or "Honor" },
}

local root, header, rail, paper, goldLine, portrait, nameText, levelText
local petButton, currencyButton
local equipmentLeftRail, equipmentRightRail, weaponTray
local currentLayout
local applying, scheduled, built
local scheduleLayout
local bagsOpenedByCompanion = false
local directRegions = {}
local recolored = {}
local actionBarState = {}
local actionBarsSuppressed = false
local pendingActionBarRestore = false

local REDUNDANT_IDENTITY = {
    "CharacterNameFrame", "CharacterNameText", "CharacterLevelText",
    "CharacterGuildText", "CharacterFramePortrait",
}

local MODEL_PRESENTATION = {
    "CharacterModelFrame", "DragonUIModelControls",
    "CharacterModelFrameRotateLeftButton", "CharacterModelFrameRotateRightButton",
}

local ACTION_BAR_NAMES = {
    "DragonUI_MainActionBar",
    "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
    "PetActionBarFrame", "ShapeshiftBarFrame", "PossessBarFrame",
    "BonusActionBarFrame", "MultiCastActionBarFrame", "DragonUI_TotemBar",
    "DragonUI_MicroButtonBar",
    -- DragonUI uses its menu frame as an anchor, but several buttons are independently parented.
    "CharacterMicroButton", "ProfessionMicroButton", "SpellbookMicroButton",
    "TalentMicroButton", "AchievementMicroButton", "QuestLogMicroButton",
    "SocialsMicroButton", "LFDMicroButton", "CollectionsMicroButton",
    "PVPMicroButton", "PathToAscensionMicroButton", "ChallengesMicroButton",
    "MainMenuMicroButton", "HelpMicroButton",
}

local function setShown(frame, shown)
    if not frame then return end
    if shown then frame:Show() else frame:Hide() end
end

local function clearAndPoint(frame, point, relativeTo, relativePoint, x, y)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, x, y)
end

local function anyBagOpen()
    for i = 1, 13 do
        local frame = _G["ContainerFrame" .. i]
        if frame and frame:IsShown() then return true end
    end
    return false
end

local function openIntegratedBags()
    if anyBagOpen() or not OpenAllBags then
        bagsOpenedByCompanion = false
        return
    end
    OpenAllBags()
    bagsOpenedByCompanion = true
end

local function closeIntegratedBags()
    if bagsOpenedByCompanion then
        CloseAllBags()
    end
    bagsOpenedByCompanion = false
end

local function hideOneActionBar(frame)
    if not frame then return end
    if not actionBarState[frame] then
        actionBarState[frame] = {
            shown = frame:IsShown() and true or false,
            alpha = frame:GetAlpha(),
            mouse = frame.IsMouseEnabled and frame:IsMouseEnabled() or nil,
        }
    end
    frame:SetAlpha(0)
    if not InCombatLockdown() then
        if frame.EnableMouse then frame:EnableMouse(false) end
        frame:Hide()
    end
    if not frame._duiImmersiveHideHook then
        frame._duiImmersiveHideHook = true
        frame:HookScript("OnShow", function(self)
            if actionBarsSuppressed then
                self:SetAlpha(0)
                if not InCombatLockdown() then self:Hide() end
            end
        end)
    end
end

local function hideActionBars()
    actionBarsSuppressed = true
    pendingActionBarRestore = false
    for _, name in ipairs(ACTION_BAR_NAMES) do hideOneActionBar(_G[name]) end
end

local function restoreActionBars()
    actionBarsSuppressed = false
    if InCombatLockdown() then
        pendingActionBarRestore = true
        return
    end
    pendingActionBarRestore = false
    for frame, state in pairs(actionBarState) do
        frame:SetAlpha(state.alpha or 1)
        if state.mouse ~= nil and frame.EnableMouse then frame:EnableMouse(state.mouse) end
        if state.shown then frame:Show() else frame:Hide() end
    end
    actionBarState = {}
end

local function makePanel(name, parent, level)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(level or 4)
    frame:EnableMouse(false)
    frame:SetBackdrop({ bgFile = ROCK, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = true, tileSize = 32, edgeSize = 14,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    frame:SetBackdropColor(0.025, 0.02, 0.015, 0.92)
    frame:SetBackdropBorderColor(0.57, 0.39, 0.16, 0.95)
    return frame
end

local function makeEquipmentChrome(name, mirrored, weapon)
    local frame = CreateFrame("Frame", name, root)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(11)
    frame:EnableMouse(false)
    frame._duiBackingPieces = {}
    frame._duiMirrored = mirrored
    for i=1,3 do
        local backing = frame:CreateTexture(nil,"BACKGROUND")
        backing:SetTexture(weapon and WEAPON_BACKING or EQUIPMENT_BACKING)
        backing:SetAlpha(0.30)
        frame._duiBackingPieces[i] = backing
    end
    frame._duiBacking = frame._duiBackingPieces[1]
    frame._duiCapRatio = weapon and 0.35 or 0.38
    return frame
end

local function fitEquipmentChrome(frame, horizontal)
    -- The source's curved, feathered ends retain their natural aspect on both the long armor
    -- rails and the short weapon tray. Only the quiet straight leather between them stretches.
    local breadth = horizontal and frame:GetHeight() or frame:GetWidth()
    local length = horizontal and frame:GetWidth() or frame:GetHeight()
    local cap = math.min(breadth * frame._duiCapRatio, length * 0.45)
    for i,t in ipairs(frame._duiBackingPieces) do
        local v0 = i == 1 and 0 or (i == 2 and 0.12 or 0.88)
        local v1 = i == 1 and 0.12 or (i == 2 and 0.88 or 1)
        t:ClearAllPoints()
        if horizontal then
            t:SetTexCoord(1,v0,0,v0,1,v1,0,v1)
            t:SetPoint("TOPLEFT",frame,"TOPLEFT",i == 1 and 0 or (i == 2 and cap or length-cap),0)
            t:SetSize(i == 2 and length-2*cap or cap,breadth)
        else
            t:SetTexCoord(frame._duiMirrored and 1 or 0,frame._duiMirrored and 0 or 1,v0,v1)
            t:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-(i == 1 and 0 or (i == 2 and cap or length-cap)))
            t:SetSize(breadth,i == 2 and length-2*cap or cap)
        end
    end
end

local function makeChromeStrip(owner, layer, cap, texturePath)
    if not texturePath then return DragonUICharacterControlArt.Horizontal(owner,"ChromeAA",layer) end
    local pieces = {}
    for i = 1, 3 do
        local texture = owner:CreateTexture(nil, layer)
        texture:SetTexture(texturePath or CHROME_STRIP)
        texture:SetAlpha(1)
        if i == 1 then
            texture:SetTexCoord(0, 0.07, 0, 1)
            texture:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
            texture:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
            texture:SetWidth(cap)
        elseif i == 3 then
            texture:SetTexCoord(0.93, 1, 0, 1)
            texture:SetPoint("TOPRIGHT", owner, "TOPRIGHT", 0, 0)
            texture:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
            texture:SetWidth(cap)
        else
            texture:SetTexCoord(0.07, 0.93, 0, 1)
            texture:SetPoint("TOPLEFT", owner, "TOPLEFT", cap, 0)
            texture:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", -cap, 0)
        end
        pieces[i] = texture
    end
    return pieces
end

local function buildParchment()
    rail:SetBackdrop(nil)
    -- Independent slices keep the leather/bronze opaque while the paper alone admits the world.
    local xs, ys = { 0, 0.125, 0.875, 1 }, { 0, 0.0625, 0.9375, 1 }
    local slice = 48
    for row = 1, 3 do
        for col = 1, 3 do
            local center = row == 2 and col == 2
            local texture = rail:CreateTexture(nil, center and "BACKGROUND" or "BORDER")
            texture:SetTexture(PARCHMENT)
            texture:SetTexCoord(xs[col], xs[col + 1], ys[row], ys[row + 1])
            local horizontal = col == 3 and "RIGHT" or "LEFT"
            local vertical = row == 3 and "BOTTOM" or "TOP"
            local x, y = col == 2 and slice or 0, row == 2 and -slice or 0
            texture:SetPoint(vertical .. horizontal, rail, vertical .. horizontal, x, y)
            if center then
                texture:SetPoint("BOTTOMRIGHT", rail, "BOTTOMRIGHT", -slice, slice)
            elseif col == 2 then
                texture:SetHeight(slice)
                texture:SetPoint(vertical .. "RIGHT", rail, vertical .. "RIGHT", -slice, y)
            elseif row == 2 then
                texture:SetWidth(slice)
                texture:SetPoint("BOTTOM" .. horizontal, rail, "BOTTOM" .. horizontal, x, slice)
            else
                texture:SetSize(slice, slice)
            end
            texture:SetAlpha(PARCHMENT_ALPHA)
            local binding = rail:CreateTexture(nil, "BORDER")
            binding:SetTexture(PARCHMENT_BORDER)
            binding:SetTexCoord(xs[col], xs[col + 1], ys[row], ys[row + 1])
            binding:SetAllPoints(texture)
            binding:SetAlpha(1)
            if center then paper = texture end
        end
    end
end

local function makeUtilityButton(name, icon, tooltip, click)
    local button = CreateFrame("Button", name, root)
    button:SetSize(34, 34)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(18)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(EQUIPMENT_BORDER)
    bg:SetDrawLayer("OVERLAY", 4)
    bg:SetAllPoints(button)
    button.Bg = bg

    local image = button:CreateTexture(nil, "ARTWORK")
    image:SetTexture(icon)
    image:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
    image:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
    button.Icon = image

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(button)

    button:SetScript("OnClick", click)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(tooltip, 1, 0.82, 0)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function buildVisuals()
    if built then return end
    built = true

    root = CreateFrame("Frame", "DragonUIImmersiveCharacterRoot", UIParent)
    root:SetAllPoints(UIParent)
    root:SetFrameStrata("HIGH")
    root:SetFrameLevel(2)
    root:EnableMouse(false)
    root:Hide()

    header = makePanel("DragonUIImmersiveCharacterHeader", root, 5)
    header:SetBackdrop(nil)
    header._duiCharacterChrome = makeChromeStrip(header, "BACKGROUND", 28,
        "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\HeaderPlateHD")
    rail = makePanel("DragonUIImmersiveCharacterRail", root, 5)

    -- Quiet leather rails visually group the stock buttons while keeping the world character
    -- unobstructed. Their low opacity leaves item quality borders as the dominant color cue.
    equipmentLeftRail = makeEquipmentChrome("DragonUIImmersiveEquipmentLeftRail")
    equipmentRightRail = makeEquipmentChrome("DragonUIImmersiveEquipmentRightRail",true)
    weaponTray = makeEquipmentChrome("DragonUIImmersiveWeaponTray",false,true)

    buildParchment()

    goldLine = header:CreateTexture(nil, "ARTWORK")
    goldLine:SetTexture(0.74, 0.49, 0.18, 0.2)
    goldLine:SetHeight(1)
    goldLine:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 10, 5)
    goldLine:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -10, 5)

    portrait = header:CreateTexture("DragonUIImmersiveHeaderPortrait", "ARTWORK")
    portrait:SetSize(48, 48)
    portrait:SetPoint("LEFT", header, "LEFT", 18, 0)

    local portraitRing = header:CreateTexture("DragonUIImmersiveHeaderPortraitRing", "OVERLAY")
    portraitRing:SetTexture(PORTRAIT_RING)
    portraitRing:SetBlendMode("BLEND")
    portraitRing:SetSize(68, 68)
    portraitRing:SetPoint("CENTER", portrait, "CENTER", 0, 0)

    local identity = CreateFrame("Frame", "DragonUIImmersiveHeaderIdentity", header)
    identity:SetPoint("CENTER", header, "CENTER", 0, 0)
    identity:SetSize(600, 32)

    nameText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("TOP", identity, "TOP", 0, 0)
    nameText:SetJustifyH("CENTER")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetTextColor(1, 0.94, 0.82)
    nameText:SetShadowColor(0, 0, 0, 0.9)
    nameText:SetShadowOffset(1, -1)

    levelText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    levelText:SetPoint("BOTTOM", identity, "BOTTOM", 0, 0)
    levelText:SetJustifyH("CENTER")
    levelText:SetJustifyV("MIDDLE")
    levelText:SetTextColor(1, 0.82, 0)
    levelText:SetShadowColor(0, 0, 0, 0.9)
    levelText:SetShadowOffset(1, -1)

    petButton = makeUtilityButton("DragonUIImmersivePetButton",
        "Interface\\Icons\\Ability_Hunter_BeastCall", PETS or "Pet", function()
            if ToggleCharacter then ToggleCharacter("DragonUIPetFrame") end
        end)
    currencyButton = makeUtilityButton("DragonUIImmersiveCurrencyButton",
        "Interface\\Icons\\INV_Misc_Coin_01", CURRENCY or "Currency", function()
            if LoadAddOn and not IsAddOnLoaded("Blizzard_TokenUI") then LoadAddOn("Blizzard_TokenUI") end
            if ToggleCharacter then ToggleCharacter("TokenFrame") end
        end)
end

local function updateIdentity()
    if not nameText then return end
    nameText:SetText(UnitName("player") or "")
    local level = UnitLevel("player") or ""
    local race = UnitRace("player") or ""
    local class, classFile = UnitClass("player")
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    local classLabel = class or ""
    local spec = CP.ActiveSpec and CP.ActiveSpec()
    if spec and spec ~= "" then classLabel = spec .. " " .. classLabel end
    if color then
        classLabel = string.format("|cff%02x%02x%02x%s|r",
            math.floor(color.r * 255 + 0.5), math.floor(color.g * 255 + 0.5),
            math.floor(color.b * 255 + 0.5), classLabel)
    end
    levelText:SetTextColor(1, 0.82, 0)
    levelText:SetText(string.format(LEVEL .. " %s %s %s", tostring(level), race or "", classLabel))
    local identity = _G.DragonUIImmersiveHeaderIdentity
    if identity then identity:SetHeight(nameText:GetStringHeight()+levelText:GetStringHeight()+3) end
    if portrait then
        local classes = {WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,
            DEATHKNIGHT=true,SHAMAN=true,MAGE=true,WARLOCK=true,DRUID=true}
        if classes[classFile] then
            portrait:SetTexture("Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\ClassPortrait_"..classFile)
            portrait:SetTexCoord(0,1,0,1)
        else
            local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
            if coords then
                portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
                portrait:SetTexCoord(unpack(coords))
            end
        end
    end
end

local function hideDirectCharacterArt()
    local frame = _G.CharacterFrame
    if not frame then return end
    if #directRegions == 0 then
        for _, region in ipairs({ frame:GetRegions() }) do
            if region.GetObjectType and region:GetObjectType() == "Texture" then
                directRegions[#directRegions + 1] = region
            end
        end
    end
    for _, region in ipairs(directRegions) do region:SetAlpha(0) end
    if frame._duiRockBg then frame._duiRockBg:SetAlpha(0) end
    if frame._duiStreaks then frame._duiStreaks:SetAlpha(0) end
    for _, key in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
                           "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }) do
        if frame[key] then frame[key]:SetAlpha(0) end
    end
    frame:EnableMouse(false)
end

local function hideRedundantIdentity()
    for _, name in ipairs(REDUNDANT_IDENTITY) do
        local widget = _G[name]
        if widget then widget:SetAlpha(0) end
    end
end

local function hideModelPresentation()
    for _, name in ipairs(MODEL_PRESENTATION) do
        local widget = _G[name]
        if widget then widget:Hide() end
    end
    local model = _G.CharacterModelFrame
    if model then
        if model._duiRaceBg then
            for _, texture in pairs(model._duiRaceBg) do texture:Hide() end
        end
        if model._duiRaceBgOverlay then model._duiRaceBgOverlay:Hide() end
    end
    if CP.InnerBorderPieces then
        for _, texture in ipairs(CP.InnerBorderPieces) do texture:SetAlpha(0) end
    end
end

local function hideInsetArt(inset)
    if not inset then return end
    for _, region in ipairs({ inset:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then region:SetAlpha(0) end
    end
    if inset._duiPanelGroundTex then inset._duiPanelGroundTex:SetAlpha(0) end
    if inset._duiMarble then inset._duiMarble:SetAlpha(0) end
end

local function dressReadableText(frame)
    if DragonUICharacterScreen_SkinPane then DragonUICharacterScreen_SkinPane(frame) end
end

local function dressEquipmentBorder(slot)
    slot:SetAlpha(1)
    -- The original asymmetric slices contain attachment wings for a contiguous paperdoll. Use
    -- the square metal cell on every detached slot and remove obsolete horizontal weapon links.
    local metal = slot._duiSlotFrame
    if metal then
        metal:SetTexture(EQUIPMENT_BORDER)
        metal:SetTexCoord(0, 1, 0, 1)
        metal:SetDrawLayer("OVERLAY", 4)
        metal:ClearAllPoints()
        metal:SetSize(43, 43)
        metal:SetPoint("CENTER", slot, "CENTER", 0, 0)
        metal:SetVertexColor(1, 1, 1, 1)
        metal:SetAlpha(1)
        metal:Show()
    end
    local normal = slot.GetNormalTexture and slot:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    if slot._duiGap then slot._duiGap:Hide() end
end

local function positionSlot(slot, x, top, size, scale)
    if not slot then return end
    scale = scale or (size / 37)
    -- DragonUI's stock-compatibility layer correctly restores these buttons under PaperDollFrame,
    -- but that narrow, independently scaled parent cannot own fullscreen coordinates reliably.
    -- Reparent the original buttons; their scripts, item data, drag/drop and tooltips stay intact.
    slot:SetParent(root)
    dressEquipmentBorder(slot)
    slot:SetScale(scale)
    slot:ClearAllPoints()
    -- WoW applies a frame's own scale to explicit anchor offsets. Compensate so the visible icon
    -- lands on the unscaled layout coordinate instead of drifting down/right as it grows.
    slot:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x / scale, -top / scale)
    slot:SetFrameStrata("HIGH")
    slot:SetFrameLevel(16)
    slot:Show()
end

local function positionEquipment(layout)
    local scale = layout.slotSize / 37
    local columnHeight = layout.columnCount * layout.slotSize
        + (layout.columnCount - 1) * (layout.slotStep - layout.slotSize)

    equipmentLeftRail:ClearAllPoints()
    equipmentLeftRail:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
        layout.leftColumn.x - 33, -layout.leftColumn.top + 36)
    equipmentLeftRail:SetSize(layout.slotSize + 76, columnHeight + 72)
    fitEquipmentChrome(equipmentLeftRail)

    equipmentRightRail:ClearAllPoints()
    equipmentRightRail:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
        layout.rightColumn.x - 43, -layout.rightColumn.top + 36)
    equipmentRightRail:SetSize(layout.slotSize + 76, columnHeight + 72)
    fitEquipmentChrome(equipmentRightRail)

    weaponTray:ClearAllPoints()
    local hasAmmo = not (UnitHasRelicSlot and UnitHasRelicSlot("player"))
    if layout.weapons.vertical then
        weaponTray._duiMirrored = layout.weapons.side == "right"
        local trayHeight = layout.weapons.height
        if hasAmmo then trayHeight = trayHeight + layout.slotSize + layout.weaponGap end
        weaponTray:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
            layout.weapons.x - (weaponTray._duiMirrored and 6 or 30), -layout.weapons.top + 24)
        weaponTray:SetSize(layout.slotSize + 36, trayHeight + 48)
        fitEquipmentChrome(weaponTray)
    else
        weaponTray:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
            layout.weapons.x - 24, layout.weapons.bottom - 30)
        weaponTray:SetSize(layout.weapons.width + (hasAmmo and layout.slotSize * 0.84 + 13 or 0) + 48,
            layout.slotSize + 30)
        fitEquipmentChrome(weaponTray,true)
    end

    for i, name in ipairs(LEFT_COLUMN) do
        positionSlot(_G[name], layout.leftColumn.x,
            layout.leftColumn.top + (i - 1) * layout.slotStep, layout.slotSize, scale)
    end
    for i, name in ipairs(RIGHT_COLUMN) do
        positionSlot(_G[name], layout.rightColumn.x,
            layout.rightColumn.top + (i - 1) * layout.slotStep, layout.slotSize, scale)
    end
    for i, name in ipairs(WEAPON_ROW) do
        local slot = _G[name]
        if slot then
            slot:SetParent(root)
            dressEquipmentBorder(slot)
            slot:SetScale(scale)
            slot:ClearAllPoints()
            local weaponX = layout.weapons.x / scale
            if layout.weapons.vertical then
                local weaponTop = (layout.weapons.top
                    + (i - 1) * (layout.slotSize + layout.weaponGap)) / scale
                slot:SetPoint("TOPLEFT", UIParent, "TOPLEFT", weaponX, -weaponTop)
            else
                weaponX = (layout.weapons.x
                    + (i - 1) * (layout.slotSize + layout.weaponGap)) / scale
                slot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
                    weaponX, layout.weapons.bottom / scale)
            end
            slot:SetFrameStrata("HIGH")
            slot:SetFrameLevel(16)
            slot:Show()
        end
    end
    local ammo = _G[AUXILIARY_SLOTS[1]]
    if ammo then
        local ammoScale = scale * 0.84
        ammo:SetParent(root)
        ammo:SetScale(ammoScale)
        ammo:ClearAllPoints()
        if layout.weapons.vertical then
            local ammoTop = layout.weapons.top
                + #WEAPON_ROW * (layout.slotSize + layout.weaponGap)
            ammo:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                layout.weapons.x / ammoScale, -ammoTop / ammoScale)
        else
            local ammoX = layout.weapons.x
                + #WEAPON_ROW * (layout.slotSize + layout.weaponGap)
            ammo:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
                ammoX / ammoScale, layout.weapons.bottom / ammoScale)
        end
        ammo:SetFrameStrata("HIGH")
        ammo:SetFrameLevel(16)
        if UnitHasRelicSlot and UnitHasRelicSlot("player") then ammo:Hide() else ammo:Show() end
    end
end

local function setEquipmentWidgetsShown(shown)
    for _, list in ipairs({ LEFT_COLUMN, RIGHT_COLUMN, WEAPON_ROW, AUXILIARY_SLOTS }) do
        for _, name in ipairs(list) do
            local slot = _G[name]
            if slot then
                if shown and (name ~= "CharacterAmmoSlot" or not UnitHasRelicSlot
                    or not UnitHasRelicSlot("player")) then
                    slot:Show()
                else
                    slot:Hide()
                end
            end
        end
    end
end

local function setEquipmentChromeShown(shown)
    setShown(equipmentLeftRail, shown)
    setShown(equipmentRightRail, shown)
    setShown(weaponTray, shown)
end

local function activeTabName()
    return CP.ActiveTabName and CP.ActiveTabName() or "PaperDollFrame"
end

local function dressFooterTab(tab, spec)
    local name = tab:GetName()
    -- Leave Blizzard's state textures shown/hidden as usual so its selected-state logic stays
    -- authoritative, but let the companion supply the visible plate and consistent padding.
    local active = _G[name .. "MiddleDisabled"]
    local selected = active and active:IsShown() or (not active and spec.index == 1)
    for _, suffix in ipairs({ "Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled" }) do
        local texture = _G[name .. suffix]
        if texture then texture:SetAlpha(0) end
    end
    for _, texture in ipairs(tab._duiHighlight or {}) do texture:SetAlpha(0) end
    local stockHighlight = tab.GetHighlightTexture and tab:GetHighlightTexture()
    if stockHighlight then stockHighlight:SetAlpha(0) end
    if not tab._duiCharacterChrome then
        tab._duiCharacterChrome = makeChromeStrip(tab, "BACKGROUND", 17)
        tab._duiCharacterGlow = makeChromeStrip(tab, "ARTWORK", 17)
        for _, texture in ipairs(tab._duiCharacterGlow) do texture:SetBlendMode("ADD") end
    end
    for _, texture in ipairs(tab._duiCharacterChrome) do
        local tint = selected and 1 or 0.72
        texture:SetVertexColor(tint, tint, tint, 1)
    end
    for _, texture in ipairs(tab._duiCharacterGlow) do texture:SetAlpha(selected and 0.18 or 0) end
    local text = _G[name .. "Text"]
    if text then
        text:ClearAllPoints()
        text:SetPoint("CENTER", tab, "CENTER", 0, -1)
        text:SetWidth(math.max(1, tab:GetWidth() - 20))
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        text:SetTextColor(1, selected and 0.94 or 0.82, selected and 0.82 or 0.35)
        text:SetShadowColor(0, 0, 0, 0.9)
        text:SetShadowOffset(1, -1)
    end
end

local function layoutFooterTabs(layout)
    local previous
    for order, spec in ipairs(FOOTER_TABS) do
        local tab = _G["CharacterFrameTab" .. spec.index]
        if tab then
            tab:SetParent(root)
            tab._duiRelayout = scheduleLayout
            tab:Show()
            tab:SetAlpha(1)
            tab:EnableMouse(true)
            tab:SetScale(1)
            tab:SetWidth(layout.tabs.width)
            tab:SetHeight(layout.tabs.height)
            tab:ClearAllPoints()
            if previous then
                tab:SetPoint("BOTTOMLEFT", previous, "BOTTOMRIGHT", layout.tabs.gap, 0)
            else
                tab:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", layout.tabs.x, layout.tabs.bottom)
            end
            tab:SetFrameStrata("HIGH")
            tab:SetFrameLevel(15)
            dressFooterTab(tab, spec)
            previous = tab
        end
    end
    for _, index in ipairs({ 2, 5 }) do
        local tab = _G["CharacterFrameTab" .. index]
        if tab then
            tab:SetParent(root)
            tab:SetAlpha(0)
            tab:EnableMouse(false)
            tab:ClearAllPoints()
            tab:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -200, -200)
        end
    end
end

local function layoutHeader(layout)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", UIParent, "TOPLEFT", layout.header.x, -layout.header.top)
    header:SetSize(layout.header.width, layout.header.height)

    local close = _G.CharacterFrameCloseButton
    if close then
        -- Stock OnClick closes GetParent(): retain its logical owner while anchoring to our bar.
        close:SetParent(CharacterFrame)
        close:SetScale(header:GetEffectiveScale()/CharacterFrame:GetEffectiveScale())
        local closeY = -(layout.header.height-26)/2
        close._duiOwner, close._duiX, close._duiY = header, -14, closeY
        close:SetSize(26,26)
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -14, closeY)
        close:SetFrameStrata("HIGH")
        close:SetFrameLevel(22)
        close:Show()
    end

    local cog = _G.DragonUICharacterSettingsCog
    if cog then
        cog:SetParent(root)
        cog:ClearAllPoints()
        cog:SetPoint("RIGHT", header, "RIGHT", -54, 0)
        cog:SetFrameStrata("HIGH")
        cog:SetFrameLevel(18)
    end
end


local function layoutSidebarControls(tabName)
    local strip = _G.DragonUICharacterSidebarTabs
    if not strip then return end
    strip:SetParent(root)
    strip:SetSize(118,34)
    for _, region in ipairs({strip:GetRegions()}) do
        if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
    end
    for i=1,3 do
        local tab = _G["DragonUICharacterSidebarTab"..i]
        if tab then
            tab:SetSize(34,34); tab:ClearAllPoints()
            tab:SetPoint("LEFT",strip,"LEFT",(i-1)*42,0)
            for _, key in ipairs({"TabBg","Hider","Highlight"}) do
                if tab[key] then tab[key]:SetAlpha(0) end
            end
            if tab.Icon then
                tab.Icon:ClearAllPoints(); tab.Icon:SetPoint("CENTER",tab,"CENTER",0,0)
                tab.Icon:SetSize(26,26)
            end
            if not tab._duiHeaderFrame then
                tab._duiHeaderFrame = tab:CreateTexture(nil,"OVERLAY",nil,4)
                tab._duiHeaderFrame:SetTexture(EQUIPMENT_BORDER)
                tab._duiHeaderFrame:SetAllPoints(tab)
                local hover = tab:CreateTexture(nil,"HIGHLIGHT")
                hover:SetTexture(EQUIPMENT_BORDER); hover:SetAllPoints(tab)
                hover:SetBlendMode("ADD"); hover:SetAlpha(0.25)
            end
        end
    end
    strip:ClearAllPoints()
    local cog = _G.DragonUICharacterSettingsCog
    if cog then
        strip:SetPoint("RIGHT", cog, "LEFT", -12, 0)
    else
        strip:SetPoint("RIGHT", header, "RIGHT", -81, 0)
    end
    strip:SetFrameStrata("HIGH")
    strip:SetFrameLevel(18)
    currencyButton:ClearAllPoints()
    currencyButton:SetPoint("RIGHT", strip, "LEFT", -12, 0)
    petButton:ClearAllPoints()
    petButton:SetPoint("RIGHT", currencyButton, "LEFT", -10, 0)
    if tabName == "PaperDollFrame" then strip:Show() else strip:Hide() end
    -- DragonUI's third sidebar tab is the live equipment-manager entry point. The old stock toggle
    -- is deliberately retired so it cannot float at its former model-frame coordinates.
    local gear = _G.GearManagerToggleButton
    if gear then gear:Hide() end
end

local function layoutRail(layout, tabName)
    rail:ClearAllPoints()
    rail:SetPoint("TOPLEFT", UIParent, "TOPLEFT", layout.rail.x, -layout.rail.top)
    rail:SetSize(layout.rail.width, layout.rail.height)

    local hasFilter = tabName == "ReputationFrame" or tabName == "SkillFrame" or tabName == "TokenFrame"
    local contentTop = hasFilter and 68 or 26
    local contentBottom = 24
    local contentLeft = 26
    local contentRight = 26
    local inset = _G.CharacterFrame and _G.CharacterFrame.Inset
    local insetRight = _G.CharacterFrame and _G.CharacterFrame.InsetRight
    hideInsetArt(inset)
    hideInsetArt(insetRight)

    if tabName == "PaperDollFrame" then
        if insetRight then
            insetRight:ClearAllPoints()
            insetRight:SetPoint("TOPLEFT", rail, "TOPLEFT", contentLeft, -contentTop)
            insetRight:SetPoint("BOTTOMRIGHT", rail, "BOTTOMRIGHT", -contentRight, contentBottom)
            insetRight:SetFrameStrata("HIGH")
            insetRight:SetFrameLevel(9)
            insetRight:Show()
        end
        if inset then inset:Hide() end
        dressReadableText(_G.DragonUICharacterStatsPane)
    else
        if insetRight then insetRight:Hide() end
        if inset then
            inset:ClearAllPoints()
            inset:SetPoint("TOPLEFT", rail, "TOPLEFT", contentLeft, -contentTop)
            inset:SetPoint("BOTTOMRIGHT", rail, "BOTTOMRIGHT", -contentRight, contentBottom)
            inset:SetFrameStrata("HIGH")
            inset:SetFrameLevel(9)
            inset:Show()
        end
        dressReadableText(inset)
        dressReadableText(_G.DragonUIReputationPane)
        dressReadableText(_G.DragonUISkillsPane)
        dressReadableText(_G.DragonUIHonorFrame)
        dressReadableText(_G.DragonUIPetFrame)
        dressReadableText(_G.DragonUICurrencyPane)
    end
    for _, entry in ipairs({
        {"DragonUIReputationFilter", "ReputationFrame", REPUTATION or "Reputation"},
        {"DragonUISkillsFilter", "SkillFrame", SKILLS or "Skills"},
        {"DragonUICurrencyFilter", "TokenFrame", CURRENCY or "Currency"},
    }) do
        local filter = _G[entry[1]]
        if filter then
            local ratio = rail:GetEffectiveScale()/filter:GetEffectiveScale()
            filter:ClearAllPoints()
            filter:SetPoint("RIGHT", rail, "TOPRIGHT", -28*ratio, -38*ratio)
        end
        if tabName == entry[2] then
            if not rail._duiPageTitle then
                rail._duiPageTitle = rail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                rail._duiPageTitle:SetPoint("TOPLEFT", rail, "TOPLEFT", 34, -30)
                rail._duiPageTitle:SetTextColor(0.22,0.11,0.035)
                rail._duiPageTitle:SetShadowOffset(0,0)
            end
            rail._duiPageTitle:SetText(entry[3]); rail._duiPageTitle:Show()
        end
    end
    if not hasFilter and rail._duiPageTitle then rail._duiPageTitle:Hide() end
    layoutSidebarControls(tabName)
end

local function applyLayout()
    scheduled = false
    if applying or not (_G.CharacterFrame and _G.CharacterFrame:IsShown()) then return end
    applying = true

    buildVisuals()
    root:Show()
    currentLayout = DragonUICharacterScreen_ComputeLayout(UIParent:GetWidth(), UIParent:GetHeight())
    updateIdentity()
    hideDirectCharacterArt()
    hideRedundantIdentity()
    hideModelPresentation()

    local tabName = activeTabName()
    layoutHeader(currentLayout)
    layoutRail(currentLayout, tabName)
    layoutFooterTabs(currentLayout)
    local showEquipment = tabName == "PaperDollFrame"
    setEquipmentChromeShown(showEquipment)
    setEquipmentWidgetsShown(showEquipment)
    if showEquipment then positionEquipment(currentLayout) end

    applying = false
end

scheduleLayout = function()
    if scheduled then return end
    scheduled = true
    if DragonUI.After then
        DragonUI:After(0, applyLayout)
    else
        local waiter = CreateFrame("Frame")
        waiter:SetScript("OnUpdate", function(self)
            self:SetScript("OnUpdate", nil)
            applyLayout()
        end)
    end
end

local function onCharacterShow()
    buildVisuals()
    root:Show()
    if DragonUICharacterScreen_Animate then
        DragonUICharacterScreen_Animate(root,CharacterFrame,true)
    end
    hideActionBars()
    if DragonUICharacterScreen_HideHUD then DragonUICharacterScreen_HideHUD() end
    scheduleLayout()
    if DragonUI.After then DragonUI:After(0, openIntegratedBags) else openIntegratedBags() end
end

local function onCharacterHide()
    local function finish()
        closeIntegratedBags()
        restoreActionBars()
        if DragonUICharacterScreen_RestoreHUD then DragonUICharacterScreen_RestoreHUD() end
    end
    if root and DragonUICharacterScreen_Animate then
        DragonUICharacterScreen_Animate(root,CharacterFrame,false,finish)
    else
        if root then root:Hide() end
        finish()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UNIT_NAME_UPDATE")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("PLAYER_TALENT_UPDATE")
events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_REGEN_ENABLED" and pendingActionBarRestore then
        restoreActionBars()
        return
    end
    if event == "UNIT_NAME_UPDATE" and unit ~= "player" then return end
    if not _G.CharacterFrame then return end
    buildVisuals()
    if not _G.CharacterFrame._duiImmersiveHooked then
        _G.CharacterFrame._duiImmersiveHooked = true
        CharacterFrame:HookScript("OnShow", onCharacterShow)
        CharacterFrame:HookScript("OnHide", onCharacterHide)
        UIParent:HookScript("OnSizeChanged", scheduleLayout)
        if _G.CharacterModelFrame then
            _G.CharacterModelFrame:HookScript("OnShow", function(model)
                if CharacterFrame:IsShown() then model:Hide() end
            end)
        end
        for _, name in ipairs(MODEL_PRESENTATION) do
            local widget = _G[name]
            if widget and not widget._duiImmersiveHideHook then
                widget._duiImmersiveHideHook = true
                widget:HookScript("OnShow", function(self)
                    if CharacterFrame:IsShown() then self:Hide() end
                end)
            end
        end
        hooksecurefunc("CharacterFrame_ShowSubFrame", function() scheduleLayout() end)
        hooksecurefunc("PanelTemplates_UpdateTabs", function(frame)
            if frame == CharacterFrame then scheduleLayout() end
        end)
        for _, functionName in ipairs({ "PanelTemplates_SelectTab", "PanelTemplates_DeselectTab" }) do
            if _G[functionName] then
                hooksecurefunc(functionName, function(tab)
                    if tab and tab._duiCharacterChrome then scheduleLayout() end
                end)
            end
        end
    end
    if CharacterFrame:IsShown() then
        hideActionBars()
        if DragonUICharacterScreen_HideHUD then DragonUICharacterScreen_HideHUD() end
        scheduleLayout()
    end
end)

