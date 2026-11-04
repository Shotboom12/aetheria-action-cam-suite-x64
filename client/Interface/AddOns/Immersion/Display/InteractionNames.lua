-- Temporarily suppress overhead NPC names while an interaction is open.
-- Persist the original values only as a recovery record for reload/crash exits.
local names = {'UnitNameNPC', 'UnitNameNonCombatCreatureName'}
local windows = {'DGossipFrame', 'DQuestFrame', 'DBookFrame', 'GossipFrame',
    'QuestFrame', 'MerchantFrame', 'ClassTrainerFrame', 'TrainerFrame',
    'ItemTextFrame', 'MailFrame', 'BankFrame', 'TaxiFrame', 'PetStableFrame',
    'GuildRegistrarFrame', 'TabardFrame', 'AuctionFrame'}
local saved, dialogue, ready
local watcher = CreateFrame('Frame')
WXLInteractionVisualsActive = false

local function Restore()
    WXLInteractionVisualsActive = false
    if not saved then return end
    for key, value in pairs(saved) do
        -- Do not overwrite a setting another addon/user changed during dialogue.
        if GetCVar(key) == '0' then SetCVar(key, value) end
    end
    saved = nil
    if ImmersionSetup then ImmersionSetup._interactionNameRecovery = nil end
end

local function Active()
    if dialogue and ImmersionFrame:IsVisible() then return true end
    for _, key in ipairs(windows) do
        local window = _G[key]
        if window and window:IsVisible() then return true end
    end
    return false
end

local function Update()
    if not ready then return end
    if Active() then
        WXLInteractionVisualsActive = true
        if not saved then
            saved = {}
            for _, key in ipairs(names) do
                local value = GetCVar(key)
                if value ~= nil then saved[key] = value end
            end
            ImmersionSetup._interactionNameRecovery = saved
            for key in pairs(saved) do SetCVar(key, '0') end
        end
    else Restore() end
end

hooksecurefunc(ImmersionFrame, 'PlayIntro', function(_, _, freeFloating)
    if not freeFloating then dialogue = true; Update() end
end)
hooksecurefunc(ImmersionFrame, 'PlayOutro', function()
    dialogue = false
    -- The poll lets overlapping gossip/quest/shop windows finish their handoff.
end)

watcher:RegisterEvent('PLAYER_LOGIN')
watcher:RegisterEvent('PLAYER_LOGOUT')
watcher:RegisterEvent('PLAYER_LEAVING_WORLD')
watcher:RegisterEvent('PLAYER_ENTERING_WORLD')
watcher:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_LOGIN' then
        ImmersionSetup = ImmersionSetup or {}
        saved = ImmersionSetup._interactionNameRecovery
        Restore()
        ready = true
    elseif event == 'PLAYER_ENTERING_WORLD' then
        ready = true
    else
        ready = false
        dialogue = false
        Restore()
    end
end)
local elapsed = 0
watcher:SetScript('OnUpdate', function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.1 then elapsed = 0; Update() end
end)
