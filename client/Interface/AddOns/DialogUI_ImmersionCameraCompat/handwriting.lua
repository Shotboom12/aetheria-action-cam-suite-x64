-- Optional WriteQuest handwriting audio during Immersion's quest/gossip dialogue.
-- This deliberately does NOT modify the camera compatibility bridge, DialogUI,
-- Immersion, their event registrations, native audio, or any interaction frame.
-- WoW 3.3.5a: uses the same PlaySound("WriteQuest") call as the original
-- DialogUI/src/frames/questFrame/quest.frame.lua DetailPanel_OnUpdate.

local PREFIX = "|cff74c7ecDialogUI-Immersion Compat|r: "
local function Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. message) end
end

local function GetConfig()
    if type(_G.DUIImmersionHandwriting) ~= "table" then
        _G.DUIImmersionHandwriting = {}
    end
    return _G.DUIImmersionHandwriting
end

local function SoundEnabled()
    return GetConfig().enabled ~= false
end

local function IsDialogueEvent(e)
    return e == "GOSSIP_SHOW" or e == "QUEST_GREETING" or
           e == "QUEST_DETAIL" or e == "QUEST_PROGRESS" or
           e == "QUEST_COMPLETE" or e == "QUEST_ITEM_UPDATE"
end

local function GetDialogue()
    local frame = _G.ImmersionFrame
    if not frame or type(frame.IsVisible) ~= "function" or not frame:IsVisible() then
        return nil
    end
    -- Toast playback is not an active NPC conversation. Book reading remains
    -- entirely owned by DialogUI, not this companion.
    if frame.playbackEvent == "IMMERSION_TOAST" then return nil end
    if not IsDialogueEvent(frame.lastEvent) then return nil end
    local box = frame.TalkBox
    local t = box and box.TextFrame and box.TextFrame.Text
    if not t or type(t.IsVisible) ~= "function" or not t:IsVisible() or
       type(t.GetText) ~= "function" then
        return nil
    end
    return t
end

local ticker = CreateFrame("Frame")
local elapsedAccum = 0
local activeText = nil
local priorLine = nil
local priorStarted = nil
local soundUntil = 0
local nextSoundAt = 0

local function ResetTracking()
    activeText = nil
    priorLine = nil
    priorStarted = nil
    soundUntil = 0
    nextSoundAt = 0
end

-- DialogUI's native quest fader plays WriteQuest once per animation update.
-- The companion instead follows the line actually presented by Immersion.
-- A bounded burst per *new line* prevents sound continuing indefinitely while
-- the player reads an unchanged page or Immersion pauses automatic progression.
-- The native DialogUI speed is 40 gradient units per second; cap long lines.
local function BurstSeconds(line)
    local seconds = string.len(line) / 40
    if seconds < 0.35 then seconds = 0.35 end
    if seconds > 8 then seconds = 8 end
    return seconds
end

local function Tick()
    if not SoundEnabled() then ResetTracking(); return end
    local t = GetDialogue()
    if not t then ResetTracking(); return end

    local line = t:GetText()
    local stamp = t.timeStarted -- Immersion Text:SetText marks each new dialogue.
    if type(line) ~= "string" or line == "" then
        priorLine = nil
        priorStarted = stamp
        soundUntil = 0
        return
    end

    -- A newly displayed text line or re-played dialogue starts a fresh,
    -- time-bounded handwriting burst; no hooks on Immersion methods required.
    if t ~= activeText or line ~= priorLine or stamp ~= priorStarted then
        activeText = t
        priorLine = line
        priorStarted = stamp
        local now = GetTime()
        soundUntil = now + BurstSeconds(line)
        nextSoundAt = now
    end

    local now = GetTime()
    if now >= soundUntil or now < nextSoundAt then return end

    -- Preserve DialogUI's own sound when its quest gradient is truly active;
    -- never double-trigger that existing native behavior.
    local panel = _G.DQuestFrameDetailPanel
    local immersion = _G.ImmersionFrame
    if immersion and immersion.lastEvent == "QUEST_DETAIL" and panel and
       type(panel.IsVisible) == "function" and panel:IsVisible() and
       panel.fading then
        return
    end

    PlaySound("WriteQuest")
    nextSoundAt = now + 0.18 -- a gentle cadence, not every rendered frame
end

ticker:SetScript("OnUpdate", function(_, elapsed)
    elapsedAccum = elapsedAccum + (tonumber(elapsed) or 0)
    if elapsedAccum < 0.06 then return end
    elapsedAccum = 0
    Tick()
end)

SLASH_DUI_HANDWRITING1 = "/duisound"
SlashCmdList["DUI_HANDWRITING"] = function(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    local config = GetConfig()
    if message == "on" then
        config.enabled = true
        ResetTracking()
        Print("Handwriting sound ON (Immersion NPC dialogues).")
    elseif message == "off" then
        config.enabled = false
        ResetTracking()
        Print("Handwriting sound OFF.")
    else
        Print("Handwriting sound " .. (SoundEnabled() and "ON" or "OFF") ..
              ". Use /duisound on or /duisound off.")
    end
end
