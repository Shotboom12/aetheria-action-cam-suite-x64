-- Hide presentation only. Native unit watches and quest/minimap controllers keep updating.
local active, saved, pendingMouse = false, {}, {}
local NAMES = {
    "PlayerFrame", "PetFrame", "TargetFrame", "TargetFrameToT", "FocusFrame", "FocusFrameToT",
    "CastingBarFrame", "PetCastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar",
    "PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4",
    "Boss1TargetFrame", "Boss2TargetFrame", "Boss3TargetFrame", "Boss4TargetFrame", "Boss5TargetFrame",
    "MinimapCluster", "MinimapBackdrop", "Minimap", "MinimapZoneTextButton",
    "DragonUI_MinimapSettingsButton", "DragonUI_MinimapIconCollector",
    "WatchFrame", "QuestWatchFrame", "ObjectiveTrackerFrame",
    "DragonUI_QuestTrackerFrame", "DragonUIObjectiveTracker",
}

local function suppress(frame, visited)
    if not frame or not frame.GetAlpha or visited[frame] then return end
    visited[frame] = true
    if not saved[frame] then
        local mouse = frame.IsMouseEnabled and frame:IsMouseEnabled()
        if pendingMouse[frame] ~= nil then mouse=pendingMouse[frame]; pendingMouse[frame]=nil end
        saved[frame] = {alpha=frame:GetAlpha(),mouse=mouse}
    end
    frame:SetAlpha(0)
    if frame.EnableMouse and not InCombatLockdown() then frame:EnableMouse(false) end
    if not frame._duiCharacterHUDHook then
        frame._duiCharacterHUDHook = true
        hooksecurefunc(frame,"SetAlpha",function(self,alpha)
            if active and saved[self] and alpha ~= 0 then self:SetAlpha(0) end
        end)
        frame:HookScript("OnShow",function(self)
            if active then self:SetAlpha(0) end
        end)
    end
    for _, child in ipairs({frame:GetChildren()}) do suppress(child,visited) end
end

function DragonUICharacterScreen_HideHUD()
    active = true
    local visited = {}
    for _, name in ipairs(NAMES) do suppress(_G[name],visited) end
    local mini = _G.DragonUI and DragonUI.MinimapModule
    if mini then
        suppress(mini.minimapFrame,visited); suppress(mini.borderFrame,visited)
        for _, key in ipairs({"minimapFrame","borderFrame","settingsButton","iconCollector"}) do
            suppress(mini.frames and mini.frames[key],visited)
        end
        for button in pairs(mini.launcherButtons or {}) do suppress(button,visited) end
    end
end

function DragonUICharacterScreen_RestoreHUD()
    active = false
    for frame, state in pairs(saved) do
        frame:SetAlpha(state.alpha)
        if state.mouse ~= nil and frame.EnableMouse then
            if InCombatLockdown() then pendingMouse[frame]=state.mouse
            else frame:EnableMouse(state.mouse) end
        end
    end
    saved = {}
end

local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_REGEN_ENABLED","PLAYER_TARGET_CHANGED","UNIT_PET",
    "PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE","ADDON_LOADED","PLAYER_ENTERING_WORLD"}) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent",function(_,event)
    if event == "PLAYER_REGEN_ENABLED" then
        for frame,mouse in pairs(pendingMouse) do frame:EnableMouse(mouse) end
        pendingMouse = {}
    end
    if active then DragonUICharacterScreen_HideHUD() end
end)
