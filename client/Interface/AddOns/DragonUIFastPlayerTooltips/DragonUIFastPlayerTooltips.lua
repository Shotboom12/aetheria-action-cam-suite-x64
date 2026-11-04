-- All unit tooltips: retain DragonUI appearance and native item/spell tips.
-- Native fade duration is not exposed by the installed 3.3.5a Lua UI.
-- This fast preset is 0.15 seconds, not a measured native-duration multiplier.
local FADE_SECONDS = 0.15
local tip = GameTooltip
local nativeFadeOut = tip.FadeOut
local unitTip, unitGUID = false, nil
local fading, elapsedFade, initialAlpha = false, 0, 1
local lastObjectAlpha, objectFadeDrops = nil, 0

local function CancelFade(self)
    fading = false
    elapsedFade = 0
    lastObjectAlpha, objectFadeDrops = nil, 0
    self:SetAlpha(1)
end

local function BeginFade(self)
    if fading or not self:IsShown() then return end
    initialAlpha = self:GetAlpha()
    -- Show cancels the native fade; subsequent alpha is owned by this timer.
    self:Show()
    fading = true
    elapsedFade = 0
end

tip:HookScript("OnTooltipSetUnit", function(self)
    CancelFade(self)
    local _, unit = self:GetUnit()
    unitTip = unit ~= nil
    unitGUID = unitTip and UnitGUID(unit) or nil
end)

tip:HookScript("OnTooltipCleared", function(self)
    unitTip, unitGUID = false, nil
    CancelFade(self)
end)

tip:HookScript("OnHide", function(self)
    unitTip, unitGUID = false, nil
    CancelFade(self)
end)

-- Only opt world tooltip candidates into the fast fade. In the 3.3.5a client,
-- native world object/corpse tracking uses WorldFrame focus and UIParent (or
-- WorldFrame) as the tooltip owner, but does not fire OnTooltipSetUnit.
-- Do not change inventory item, spell, UI-button, or addon-created tooltips.
local function IsWorldObjectTip(self)
    if unitTip then return false end
    local owner = self:GetOwner()
    if owner ~= WorldFrame and owner ~= UIParent then return false end
    if not GetMouseFocus or GetMouseFocus() ~= WorldFrame then return false end
    local _, unit = self:GetUnit()
    if unit then return false end
    if self.GetItem then
        local itemName, itemLink = self:GetItem()
        if itemName or itemLink then return false end
    end
    if self.GetSpell then
        local spellName, spellId = self:GetSpell()
        if spellName or spellId then return false end
    end
    return self:NumLines() > 0
end

tip.FadeOut = function(self, ...)
    if unitTip or IsWorldObjectTip(self) then
        BeginFade(self)
    else
        return nativeFadeOut(self, ...)
    end
end

tip:HookScript("OnUpdate", function(self, elapsed)
    -- World hover removal may start fading internally, bypassing Lua FadeOut.
    -- Compare GUIDs rather than just UnitExists so moving to another unit works.
    -- DragonUI world tooltips are owned by UIParent in this client; their
    -- unit can be party1/party2 rather than mouseover. Dedicated UI-frame
    -- owners still use their normal OnLeave -> FadeOut path.
    local owner = self:GetOwner()
    if unitTip and not fading and unitGUID
        and (owner == WorldFrame or owner == UIParent)
        and UnitGUID("mouseover") ~= unitGUID then
        BeginFade(self)
    end
    -- WoW calls CGTooltip::FadeOut directly when a world object loses hover,
    -- bypassing the Lua FadeOut override. Detect the native alpha decrease and
    -- finish that fade using the existing 0.15s timer. Never hide a tooltip
    -- just because the pointer moved; that would flicker on large objects.
    -- Native WoW holds full alpha for ~1s before decreasing it; Lua cannot
    -- remove that initial hold without a native hook, so this is fail-safe.
    -- Sample *consecutive* decreases, not absolute alpha: another addon may
    -- select a steady opacity below 100%, or change it once while hovered.
    if not fading and not unitTip and self:IsShown() and IsWorldObjectTip(self) then
        local alpha = self:GetAlpha()
        if lastObjectAlpha and alpha and alpha < lastObjectAlpha - 0.002 then
            objectFadeDrops = objectFadeDrops + 1
            if objectFadeDrops >= 2 then BeginFade(self) end
        else
            objectFadeDrops = 0
        end
        lastObjectAlpha = alpha
    else
        lastObjectAlpha, objectFadeDrops = nil, 0
    end
    if not fading then return end
    elapsedFade = elapsedFade + elapsed
    if elapsedFade >= FADE_SECONDS then
        self:Hide()
    else
        self:SetAlpha(initialAlpha * (1 - elapsedFade / FADE_SECONDS))
    end
end)
