-- Copyright (c) 2026 NeticSoul. Licensed under the MIT License; see LICENSE.

local addon = select(2, ...)
local L = addon.L

local _G = _G
local type = type
local pairs = pairs
local BACKPACK_CONTAINER = BACKPACK_CONTAINER or 0
local KEYRING_CONTAINER = KEYRING_CONTAINER or -2
local NUM_BAG_SLOTS = NUM_BAG_SLOTS or 4
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS or 7
local MAX_CONTAINER_ITEMS = 36
local MAX_CONTAINER_FRAMES = 13
local BAG_VERTICAL_GAP = 4
local BAG_HORIZONTAL_GAP = 9

local assets = addon._dir
local newBagSkin = assets .. "BagLeatherBronze\\"
local borderSkin = assets .. "BagLeatherBronzeGenerated\\"
local textures = {
    slot = newBagSkin .. "SlotNormal",
    bankSlot = newBagSkin .. "SlotBank",
    metal = borderSkin .. "Corners",
    metalHorizontal = newBagSkin .. "FrameHorizontal",
    metalVertical = newBagSkin .. "FrameVertical",
    background = newBagSkin .. "Leather",
    close = newBagSkin .. "CloseButtons",
    pushed = assets .. "UI\\ui-quickslot-depress",
    highlight = assets .. "UI\\buttonhilight-square",
    slotBorder = newBagSkin .. "SlotRim",
    coinbox = newBagSkin .. "CoinBox",
    currencybox = newBagSkin .. "CurrencyBox",
    coinGold = [[Interface\AddOns\DragonUI_QuestJournal\Assets\CoinGoldHD]],
    coinSilver = [[Interface\AddOns\DragonUI_QuestJournal\Assets\CoinSilverHD]],
    coinCopper = [[Interface\AddOns\DragonUI_QuestJournal\Assets\CoinCopperHD]],
    -- pre-masked (round alpha baked in offline, no runtime mask API exists in 3.3.5a)
    backpackIcon = assets .. "Bags\\INV_Misc_Bag_08_round",
}

-- Native layout splits CONTAINER_WIDTH's 29px slack 17/12 left-right; this recenters the grid.
local ITEM_GRID_X_NUDGE = -2.5
local ITEM_GRID_Y_NUDGE = 3

-- Same clearances the corner ornament (portrait) and close button already reserve elsewhere.
local TITLE_LEFT_CLEARANCE = 58
local TITLE_RIGHT_CLEARANCE = 24

local classicBackgrounds = {
    "BackgroundTop",
    "BackgroundMiddle1",
    "BackgroundMiddle2",
    "BackgroundBottom",
    "Background1Slot",
}

local BagSkinModule = {
    applied = false,
    initialized = false,
    hooksInstalled = false,
}

if addon.RegisterModule then
    addon:RegisterModule(
        "bags_skin",
        BagSkinModule,
        L["Bag Skin"],
        L["Retail-style skin for Blizzard bag windows"],
        { loadOnce = true }
    )
end

local function IsActive()
    return BagSkinModule.applied and addon:IsModuleEnabled("bags_skin")
end

local function IsBankBag(bagID)
    return type(bagID) == "number"
        and bagID >= NUM_BAG_SLOTS + 1
        and bagID <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
end

local function ConfigureTexture(texture, path, width, height, left, right, top, bottom)
    texture:SetTexture(path)
    texture:SetSize(width, height)
    texture:SetTexCoord(left, right, top, bottom)
end

-- Continuous generated leather/bronze frame, with all joins baked offline.
-- One shared mipmapped texture per native frame size; no per-frame polling.
local function Art(frame, layer, path)
    local t=frame:CreateTexture(nil,layer)
    if path then t:SetTexture(path)end
    return t
end
local function EnsureChrome(frame,key,portraitKind)
    if frame[key]then return frame[key]end
    local c={portraitKind=portraitKind}
    c.panel=Art(frame,"BACKGROUND")
    c.portraitRim=Art(frame,"OVERLAY",newBagSkin.."PortraitRing")
    c.portraitRim:SetTexCoord(0,1,0,1)
    frame[key]=c
    return c
end
local function ScreenPixelScale(frame)
    local _,h=string.match(GetCVar("gxResolution")or "","(%d+)[xX](%d+)")
    local root=UIParent:GetHeight()*UIParent:GetEffectiveScale()
    local ratio=tonumber(h)and root>0 and tonumber(h)/root or 1
    return math.max(.01,frame:GetEffectiveScale()*ratio)
end
local function PowerOfTwo(n)
    local p=1;while p<n do p=p*2 end;return p
end
local function LayoutChrome(frame,c,compact)
    local width,height=frame:GetWidth(),frame:GetHeight()
    local scale=ScreenPixelScale(frame)
    local x,y=frame:GetLeft()or 0,frame:GetTop()or 0
    if c.width==width and c.height==height and c.scale==scale and c.originX==x and c.originY==y then return end
    c.width,c.height,c.scale,c.originX,c.originY=width,height,scale,x,y
    local wi,hi=math.floor(width+.5),math.floor(height+.5)
    local key=wi.."_"..hi
    if c.assetKey~=key then
        c.panel:SetTexture(borderSkin.."Frame_"..key)
        c.assetKey=key
        local sourceHeight=hi
        if hi==360 or hi==382 or hi==401 or hi==423 then sourceHeight=hi+.353515625 end
        local sw=math.floor((wi+6)*1.275+.5)
        local sh=math.floor((sourceHeight+5)*1.275+.5)
        c.panel:SetTexCoord(0,sw/PowerOfTwo(sw),0,sh/PowerOfTwo(sh))
    end
    local function pixel(n)return math.floor(n*scale+.5)/scale end
    local left,top=pixel(x-3)-x,pixel(y+2)-y
    local w,h=pixel(width+6),pixel(height+5)
    c.panel:ClearAllPoints();c.panel:SetPoint("TOPLEFT",frame,"TOPLEFT",left,top)
    c.panel:SetSize(w,h)
    local p=_G[frame:GetName().."Portrait"]
    if p then
        local size=compact and 36 or 46
        c.portraitRim:SetSize(size,size);c.portraitRim:ClearAllPoints()
        c.portraitRim:SetPoint("CENTER",p,"CENTER",0,0)
    end
end

local function SkinCloseButton(button, compact)
    if not button then
        return
    end

    if button._dragonuiCloseCompact == compact then return end
    button._dragonuiCloseCompact = compact

    button:SetSize(compact and 20 or 24, compact and 20 or 24)
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", button:GetParent(), "TOPRIGHT", 1, 0)

    local normal = button:GetNormalTexture()
    if normal then
        normal:SetTexture(textures.close)
        normal:SetTexCoord(0.152344, 0.292969, 0.0078125, 0.304688)
    end

    local disabled = button:GetDisabledTexture()
    if disabled then
        disabled:SetTexture(textures.close)
        disabled:SetTexCoord(0.152344, 0.292969, 0.320312, 0.617188)
    end

    local pushed = button:GetPushedTexture()
    if pushed then
        pushed:SetTexture(textures.close)
        pushed:SetTexCoord(0.152344, 0.292969, 0.632812, 0.929688)
    end

    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetTexture(textures.close)
        highlight:SetTexCoord(0.449219, 0.589844, 0.0078125, 0.304688)
    end
    for _,t in ipairs({button:GetNormalTexture(),button:GetDisabledTexture(),
        button:GetPushedTexture(),button:GetHighlightTexture()})do
        t:ClearAllPoints();t:SetPoint("CENTER",button,"CENTER",0,0)
        t:SetSize(compact and 18 or 20,compact and 18 or 20)
    end
end

local function SkinItemButton(button, bankSlot)
    if not button then
        return
    end

    local normal = button:GetNormalTexture()
    local slotTexture = bankSlot and textures.bankSlot or textures.slot
    if button._dragonuiSlotKind == bankSlot and normal and normal:GetTexture() == slotTexture then return end
    button._dragonuiSlotKind = bankSlot
    if normal then
        normal:SetTexture(slotTexture)
        normal:SetSize(37, 37)
        normal:ClearAllPoints()
        normal:SetPoint("CENTER", button, "CENTER")
        normal:SetDrawLayer("BACKGROUND")
        normal:Show()
    end

    -- One shared transparent rim sprite per item; native icon and indicators remain independent.
    local border = button._dragonuiSlotBorder
    if not border then
        border = button:CreateTexture(nil, "ARTWORK")
        button._dragonuiSlotBorder = border
    end
    border:SetTexture(textures.slotBorder)
    border:SetTexCoord(0,1,0,1)
    border:SetSize(40, 40)
    border:ClearAllPoints()
    -- The repacked rim has a symmetric silhouette and a transparent center.
    border:SetPoint("CENTER", button, "CENTER", 0, 0)
    border:Show()

    local pushed = button:GetPushedTexture()
    if pushed then
        pushed:SetTexture(textures.pushed)
        pushed:SetSize(37, 37)
        pushed:ClearAllPoints()
        pushed:SetPoint("CENTER", button, "CENTER")
    end

    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetTexture(textures.highlight)
        highlight:SetSize(37, 37)
        highlight:ClearAllPoints()
        highlight:SetPoint("CENTER", button, "CENTER")
    end

    local name = button:GetName()
    if not name then
        return
    end

    local icon = _G[name .. "IconTexture"]
    if icon then
        -- ItemButtonTemplate ships IconTexture with no Size/Anchors; force it to fill the button.
        icon:SetDrawLayer("BORDER")
        icon:SetTexCoord(0, 1, 0, 1)
        icon:ClearAllPoints()
        icon:SetAllPoints(button)
    end

    local count = _G[name .. "Count"]
    if count then
        count:SetDrawLayer("OVERLAY")
    end

    local stock = _G[name .. "Stock"]
    if stock then
        stock:SetDrawLayer("OVERLAY")
    end
end


function addon.StyleBagUtilityButton(button)
    if not IsActive() or not button or not button.border or not button.icon then return end
    button.border:SetTexture(textures.slotBorder)
    button.border:SetTexCoord(0,1,0,1)
    button.border:ClearAllPoints();button.border:SetPoint("CENTER",button,"CENTER",0,0)
    button.border:SetSize(18,18)
    button.icon:ClearAllPoints();button.icon:SetPoint("CENTER",button,"CENTER",0,0)
    button.icon:SetSize(16,16)
end

local function HideClassicBackgrounds(frame)
    local name = frame:GetName()
    for _, suffix in pairs(classicBackgrounds) do
        local texture = _G[name .. suffix]
        if texture then
            texture:Hide()
        end
    end
end

local function RefreshContainerPortrait(frame, compact)
    local name = frame:GetName()
    local portrait = _G[name .. "Portrait"]
    local portraitButton = _G[name .. "PortraitButton"]
    local bagID = frame:GetID()
    local size = compact and 28 or 36 -- retain the native portrait click target
    local imageSize = compact and 22 or 30 -- square icon corners stay under opaque ring material
    local imageInset = (size - imageSize) / 2
    local x = compact and -2 or -4
    local y = compact and 0 or 1

    if portrait then
        if bagID == KEYRING_CONTAINER then
            SetPortraitToTexture(portrait, "Interface\\ContainerFrame\\KeyRing-Bag-Icon")
        elseif bagID == BACKPACK_CONTAINER then
            -- SetPortraitToTexture over-crops this edge-to-edge HD asset; masked offline instead.
            portrait:SetTexture(textures.backpackIcon)
            portrait:SetTexCoord(0, 1, 0, 1)
        elseif type(bagID) == "number" then
            SetBagPortraitTexture(portrait, bagID)
        end

        portrait:SetSize(imageSize, imageSize)
        portrait:ClearAllPoints()
        portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", x + imageInset, y - imageInset)
        portrait:SetDrawLayer("OVERLAY") -- Native portrait precedes our OVERLAY rim in creation order.
        portrait:Show()
    end

    if portraitButton then
        portraitButton:SetSize(size, size)
        portraitButton:ClearAllPoints()
        portraitButton:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    end
end

local function RefreshContainerTitle(frame, compact)
    local nativeTitle = _G[frame:GetName() .. "Name"]
    local title = frame._dragonuiBagChrome.title
    if nativeTitle then
        nativeTitle:Hide()
    end

    if compact then
        title:Hide()
        return
    end

    local bagID = frame:GetID()
    if bagID == KEYRING_CONTAINER then
        title:SetText(KEYRING)
    else
        title:SetText(GetBagName(bagID) or "")
    end

    title:ClearAllPoints()
    -- TOP anchor keeps text truly centered; LEFT/RIGHT clearance boxes would skew it on our narrow frames.
    title:SetPoint("TOP", frame, "TOP", 0, -7)
    title:SetJustifyH("CENTER")
    -- Width from the clearances (not a guessed number) clips overflow instead of wrapping it.
    title:SetWidth(frame:GetWidth() - TITLE_LEFT_CLEARANCE - TITLE_RIGHT_CLEARANCE)
    title:SetWordWrap(false)
    title:Show()
end

local function PrepareContainerFrame(frame)
    if frame._dragonuiBagSkinPrepared then
        return
    end

    frame._dragonuiBagSkinPrepared = true
    local chrome = EnsureChrome(frame, "_dragonuiBagChrome", "small")
    chrome.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SkinCloseButton(_G[frame:GetName() .. "CloseButton"], false)

    for i = 1, MAX_CONTAINER_ITEMS do
        SkinItemButton(_G[frame:GetName() .. "Item" .. i], false)
    end

    frame:HookScript("OnShow", function(self)
        if IsActive() then
            BagSkinModule:RefreshContainerFrame(self)
        end
    end)
end

local BOTTOM_PILL_HEIGHT = 17
local BOTTOM_PILL_GAP = 3
-- Blizzard re-anchors the coins on every update, so the frame rises and its pill sinks by the same amount.
local MONEY_LIFT = 0.5

local function ApplyPillChrome(bar, texturePath, yOffset)
    if bar._dragonuiPill then
        return
    end
    bar._dragonuiPill = true

    local left = bar:CreateTexture(nil, "BACKGROUND")
    left:SetSize(8, 17)
    left:SetPoint("LEFT", bar, "LEFT", 0, yOffset or 0)
    left:SetTexture(texturePath)
    left:SetTexCoord(0.03125, 0.53125, 0.289062, 0.554688)

    local right = bar:CreateTexture(nil, "BACKGROUND")
    right:SetSize(8, 17)
    right:SetPoint("RIGHT", bar, "RIGHT", 0, yOffset or 0)
    right:SetTexture(texturePath)
    right:SetTexCoord(0.03125, 0.53125, 0.570312, 0.835938)

    local middle = bar:CreateTexture(nil, "BACKGROUND")
    middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
    middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
    middle:SetTexture(texturePath)
    middle:SetTexCoord(0, 0.5, 0.0078125, 0.273438)
end

local function SkinMoneyFrame(frame)
    local moneyFrame = _G[frame:GetName() .. "MoneyFrame"]
    if not moneyFrame or moneyFrame._dragonuiSkinned then
        return
    end
    moneyFrame._dragonuiSkinned = true

    moneyFrame:SetHeight(BOTTOM_PILL_HEIGHT)
    ApplyPillChrome(moneyFrame, textures.coinbox, -MONEY_LIFT)
end

-- MoneyFrameTemplate rebuilds each coin's NormalTexture on every RefreshMoneyFrame, so a one-time
-- swap gets clobbered; the hook below (MoneyFrame_Update) re-applies it after every native update.
-- BLP requires power-of-two dimensions, so each 20x20 icon sits padded on a 32x32 canvas;
-- these texcoords crop back to just the icon instead of stretching the whole padded square.
local COIN_ICON_TEXCOORD = { 0, 1, 0, 1 } -- full-size accepted Coin*HD art
local COIN_ICONS = {
    { key = "GoldButton", texture = textures.coinGold },
    { key = "SilverButton", texture = textures.coinSilver },
    { key = "CopperButton", texture = textures.coinCopper },
}

local function ModernizeCoinIcons(frame)
    if not IsActive() then
        return
    end
    if GetCVar("colorblindMode") == "1" then
        return -- Blizzard blanks the coin texture and shows text instead; don't paint over it.
    end
    if type(frame) ~= "table" then
        frame = frame and _G[frame]
    end
    if not frame then
        return
    end

    local frameName = frame:GetName()
    for _, coin in ipairs(COIN_ICONS) do
        local button = _G[frameName .. coin.key]
        local tex = button and button.GetNormalTexture and button:GetNormalTexture()
        if tex then
            tex:SetTexture(coin.texture)
            tex:SetTexCoord(unpack(COIN_ICON_TEXCOORD))
        end
    end
end

-- Blizzard_TokenUI is load-on-demand; force it so tracked currencies show without opening the Character panel first.
local function EnsureTokenUILoaded()
    if ManageBackpackTokenFrame then
        return true
    end
    if not IsAddOnLoaded("Blizzard_TokenUI") then
        LoadAddOn("Blizzard_TokenUI")
    end
    return ManageBackpackTokenFrame ~= nil
end

local function SkinTokenFrame()
    local frame = BackpackTokenFrame
    if not frame or frame._dragonuiSkinned then
        return
    end
    frame._dragonuiSkinned = true

    -- Native XML ships one unnamed BACKGROUND texture (UI-Backpack-TokenFrame); strip it for our pill.
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then
            region:Hide()
            region:SetTexture(nil)
        end
    end

    frame:SetHeight(BOTTOM_PILL_HEIGHT)
    ApplyPillChrome(frame, textures.currencybox)
end

local function RepositionBackpackBottomWidgets(frame)
    local moneyFrame = _G[frame:GetName() .. "MoneyFrame"]
    if not moneyFrame or not moneyFrame._dragonuiSkinned then
        return
    end

    local tokenShown = BackpackTokenFrame_IsShown and BackpackTokenFrame_IsShown()

    moneyFrame:ClearAllPoints()
    if tokenShown then
        BackpackTokenFrame:ClearAllPoints()
        BackpackTokenFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
        BackpackTokenFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
        moneyFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8 + BOTTOM_PILL_HEIGHT + BOTTOM_PILL_GAP + MONEY_LIFT)
        moneyFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8 + BOTTOM_PILL_HEIGHT + BOTTOM_PILL_GAP + MONEY_LIFT)
    else
        moneyFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8 + MONEY_LIFT)
        moneyFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8 + MONEY_LIFT)
    end
end

local tokenHookInstalled = false
local function OnManageBackpackTokenFrame(backpack)
    if not IsActive() then
        return
    end
    backpack = backpack or (GetBackpackFrame and GetBackpackFrame())
    if not backpack or not backpack.GetID or backpack:GetID() ~= BACKPACK_CONTAINER then
        return
    end
    SkinTokenFrame()
    RepositionBackpackBottomWidgets(backpack)
end

local function InstallTokenHook()
    if tokenHookInstalled or not ManageBackpackTokenFrame then
        return
    end
    tokenHookInstalled = true
    hooksecurefunc("ManageBackpackTokenFrame", OnManageBackpackTokenFrame)
end

local function AdjustItemGridPosition(frame)
    if frame.size == 1 then
        return
    end

    local item1 = _G[frame:GetName() .. "Item1"]
    if not item1 then
        return
    end

    local point, relativeTo, relativePoint, x, y = item1:GetPoint(1)
    if not point then
        return
    end

    local yNudge = frame:GetID() ~= BACKPACK_CONTAINER and ITEM_GRID_Y_NUDGE or 0
    -- Partial top rows have less native header clearance (e.g. 6/10/22-slot bags).
    if frame:GetID() ~= BACKPACK_CONTAINER and frame.size and frame.size % 4 == 2 then yNudge = -1 end
    item1:SetPoint(point, relativeTo, relativePoint, x + ITEM_GRID_X_NUDGE, y + yNudge)
end

function BagSkinModule:RefreshContainerFrame(frame)
    if not IsActive() or not frame then
        return
    end

    PrepareContainerFrame(frame)

    local compact = frame.size == 1
    local bagID = frame:GetID()
    local chrome = frame._dragonuiBagChrome

    HideClassicBackgrounds(frame)
    LayoutChrome(frame, chrome, compact)
    SkinCloseButton(_G[frame:GetName() .. "CloseButton"], compact)
    RefreshContainerPortrait(frame, compact)
    RefreshContainerTitle(frame, compact)

    if bagID == BACKPACK_CONTAINER then
        SkinMoneyFrame(frame)
        if EnsureTokenUILoaded() then
            InstallTokenHook()
            SkinTokenFrame()
            BackpackTokenFrame_Update()
            ManageBackpackTokenFrame(frame)
        end
        RepositionBackpackBottomWidgets(frame)
    end

    for i = 1, MAX_CONTAINER_ITEMS do
        SkinItemButton(_G[frame:GetName() .. "Item" .. i], IsBankBag(bagID))
    end
end

local function ApplyContainerSpacing()
    if not IsActive() or not ContainerFrame1 or not ContainerFrame1.bags then
        return
    end

    local column = -1
    for _, frameName in ipairs(ContainerFrame1.bags) do
        local frame = _G[frameName]
        if frame then
            local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
            if point and relativeTo == frame:GetParent() then
                column = column + 1
                frame:SetPoint(
                    point,
                    relativeTo,
                    relativePoint,
                    (x or 0) - column * BAG_HORIZONTAL_GAP,
                    y or 0
                )
            elseif point and relativeTo then
                frame:SetPoint(point, relativeTo, relativePoint, x or 0, (y or 0) + BAG_VERTICAL_GAP)
            end
        end
    end
    -- Keep the requested five-bag arrangement when the right stack fits:
    -- backpack/quiver/first bag on the right, two remaining bags on the left.
    if #ContainerFrame1.bags==5 and not (BankFrame and BankFrame:IsShown())then
        local inventory={}
        for _,name in ipairs(ContainerFrame1.bags)do
            local f=_G[name];local id=f and f:GetID()
            if id and id>=0 and id<=4 and f:IsShown()then inventory[id]=f end
        end
        local a,b,c,d,e=inventory[0],inventory[1],inventory[2],inventory[3],inventory[4]
        if a and b and c and d and e then
            local available=UIParent:GetHeight()*UIParent:GetEffectiveScale()/a:GetEffectiveScale()-(CONTAINER_OFFSET_Y or 70)
            if a:GetHeight()+b:GetHeight()+c:GetHeight()+2*BAG_VERTICAL_GAP<=available then
                local gap=math.max(BAG_HORIZONTAL_GAP,a:GetLeft()-e:GetLeft()-e:GetWidth())
                e:ClearAllPoints();e:SetPoint("BOTTOMRIGHT",a,"BOTTOMLEFT",-gap,0)
                d:ClearAllPoints();d:SetPoint("BOTTOMRIGHT",e,"TOPRIGHT",0,BAG_VERTICAL_GAP)
            end
        end
    end
    -- A later bag may move an earlier bag through a relative-anchor chain.
    -- Read final coordinates only once every native spacing move is complete.
    for _,frameName in ipairs(ContainerFrame1.bags)do
        local frame=_G[frameName]
        if frame and frame._dragonuiBagChrome then
            LayoutChrome(frame,frame._dragonuiBagChrome,frame.size==1)
        end
    end
end

local function InstallHooks()
    if BagSkinModule.hooksInstalled then
        return
    end

    BagSkinModule.hooksInstalled = true

    if MoneyFrame_Update then
        hooksecurefunc("MoneyFrame_Update", ModernizeCoinIcons)
    end

    hooksecurefunc("ContainerFrame_GenerateFrame", function(frame)
        if IsActive() then
            BagSkinModule:RefreshContainerFrame(frame)
            AdjustItemGridPosition(frame)
        end
    end)

    hooksecurefunc("ContainerFrame_Update", function(frame)
        if IsActive() then
            BagSkinModule:RefreshContainerFrame(frame)
        end
    end)

    hooksecurefunc("updateContainerFrameAnchors", ApplyContainerSpacing)
end

function BagSkinModule:Apply()
    if self.applied then
        return
    end

    self.applied = true
    self.initialized = true
    InstallHooks()

    for i = 1, MAX_CONTAINER_FRAMES do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            PrepareContainerFrame(frame)
            if frame:IsShown() then
                self:RefreshContainerFrame(frame)
                AdjustItemGridPosition(frame)
            end
        end
    end

    ApplyContainerSpacing()
end

function BagSkinModule:Restore()
    self.applied = false
end

-- Unusable tint is independent of bag skin chrome (works with stock bags too).
local unusableTintHooksInstalled = false

-- Re-apply after Blizzard paths that force white (Update, UpdateCooldown, UpdateLocked).
local function TintBagButtonUnusable(itemButton, bag, slot)
    if not addon:IsUnusableItemTintEnabled() or not itemButton then
        return
    end
    local texture, _, locked = GetContainerItemInfo(bag, slot)
    if not texture or locked then
        return
    end
    local _, duration, enable = GetContainerItemCooldown(bag, slot)
    if duration and duration > 0 and enable == 0 then
        return
    end
    local link = GetContainerItemLink(bag, slot)
    if addon:IsItemUnusableForTint(link, bag, slot) then
        SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0)
    end
end

local function TintContainerFrameUnusable(frame)
    if not addon:IsUnusableItemTintEnabled() or not frame then
        return
    end
    local bag = frame:GetID()
    local frameName = frame:GetName()
    local size = frame.size or GetContainerNumSlots(bag)
    for i = 1, size do
        local itemButton = _G[frameName .. "Item" .. i]
        if itemButton then
            TintBagButtonUnusable(itemButton, bag, itemButton:GetID())
        end
    end
end

local function TintBankSlotUnusable(button)
    if not button or not BankFrame or not BankFrame:IsShown() or button.isBag then
        return
    end
    TintBagButtonUnusable(button, BANK_CONTAINER or -1, button:GetID())
end

local function InstallUnusableTintHooks()
    if unusableTintHooksInstalled then
        return
    end
    unusableTintHooksInstalled = true

    hooksecurefunc("ContainerFrame_Update", TintContainerFrameUnusable)
    if ContainerFrame_UpdateCooldown then
        hooksecurefunc("ContainerFrame_UpdateCooldown", function(container, button)
            if button then
                TintBagButtonUnusable(button, container, button:GetID())
            end
        end)
    end
    -- Unlock path: SetItemButtonDesaturated(..., nil) forces white and skips our Update hook.
    if ContainerFrame_UpdateLocked then
        hooksecurefunc("ContainerFrame_UpdateLocked", TintContainerFrameUnusable)
    end
    if ContainerFrame_UpdateLockedItem then
        hooksecurefunc("ContainerFrame_UpdateLockedItem", function(frame, slot)
            if not addon:IsUnusableItemTintEnabled() or not frame or not slot then
                return
            end
            local index = (frame.size or 0) + 1 - slot
            local itemButton = _G[frame:GetName() .. "Item" .. index]
            if itemButton then
                TintBagButtonUnusable(itemButton, frame:GetID(), itemButton:GetID())
            end
        end)
    end

    if BankFrameItemButton_Update then
        hooksecurefunc("BankFrameItemButton_Update", TintBankSlotUnusable)
    end
    if BankFrameItemButton_UpdateLocked then
        hooksecurefunc("BankFrameItemButton_UpdateLocked", TintBankSlotUnusable)
    end
    if BankFrame_UpdateCooldown then
        hooksecurefunc("BankFrame_UpdateCooldown", function(container, button)
            if button then
                TintBagButtonUnusable(button, container, button:GetID())
            end
        end)
    end

    local levelFrame = CreateFrame("Frame")
    levelFrame:RegisterEvent("PLAYER_LEVEL_UP")
    levelFrame:RegisterEvent("SPELLS_CHANGED")
    -- Profession ranks land after the first bag scan at login, so recipes cache as "red" until then.
    levelFrame:RegisterEvent("SKILL_LINES_CHANGED")
    levelFrame:SetScript("OnEvent", function(_, event)
        if event == "SPELLS_CHANGED" then
            if addon.ClearUnusableItemTintCache then
                addon:ClearUnusableItemTintCache()
            end
            return
        end
        if addon.RefreshUnusableItemTints then
            addon:RefreshUnusableItemTints()
        end
    end)
end

InstallUnusableTintHooks()
