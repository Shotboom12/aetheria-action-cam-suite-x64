-- WXL Reticle Tooltip Position 0.1.0 (experimental)
-- UI-only addon; NEVER hooks a client function or changes WarcraftXL binaries.
-- Only applies at native tooltip's OnTooltipSetDefaultAnchor while mouselooking.
local addonName = ...
local DB
local addon = CreateFrame("Frame")
local hooked = false
local repositioning = false
local errors = 0
local xSlider, ySlider, enableCheck
local clamp = function(v,lo,hi)
    v = tonumber(v) or 0
    if v < lo then return lo end
    if v > hi then return hi end
    return math.floor(v + 0.5)
end
local function log(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff70bbffReticle Tooltip|r: " .. message) end
end
local function active()
    -- This is WoW 3.3.5a's actual native look state; UI menus auto-release camera.
    return DB and DB.enabled and type(IsMouselooking)=="function" and IsMouselooking()
end
local function AnchorTooltip(tip)
    if not active() or repositioning or tip ~= GameTooltip or not UIParent then return end
    -- DragonUI may have installed a secure post-hook on GameTooltip_SetDefaultAnchor,
    -- and follows the cursor in its OnUpdate when configured to do so. We let its
    -- original anchor routine finish, then take ownership via WoW's normal Lua API.
    -- DragonUI's own secure SetOwner hook stops its cursor follower automatically.
    -- No CLayoutFrame/CGTooltip native calls, new WXL DLLs, or cursor warps.
    repositioning = true
    local ok = pcall(function()
        tip:SetOwner(UIParent, "ANCHOR_NONE")
        tip:ClearAllPoints()
        tip:SetPoint("TOPLEFT", UIParent, "CENTER", DB.offsetX, DB.offsetY)
    end)
    repositioning = false
    if not ok then
        errors = errors + 1
        if errors == 1 then
            log("Unable to reposition this tooltip. Original WXL extensions remain unchanged; /rtip off disables the addon.")
        end
    end
end
local function slider(parent,name,label,x,y,lo,hi,initial,callback)
    local s=CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    s:SetWidth(250)
    s:SetHeight(18)
    s:SetMinMaxValues(lo,hi)
    s:SetValueStep(1)
    getglobal(name.."Text"):SetText(label)
    getglobal(name.."Low"):SetText(tostring(lo))
    getglobal(name.."High"):SetText(tostring(hi))
    s:SetValue(initial)
    s:SetScript("OnValueChanged", function(self,v)
        if not DB then return end
        callback(clamp(v,lo,hi))
        getglobal(name.."Text"):SetText(label.." ("..tostring(clamp(v,lo,hi))..")")
    end)
    getglobal(name.."Text"):SetText(label.." ("..tostring(initial)..")")
    return s
end
local function MakeOptions()
    if not InterfaceOptions_AddCategory then return end
    local frame=CreateFrame("Frame","WXLReticleTooltipPositionPanel",UIParent)
    frame.name="WXL Reticle Tooltip"
    local title=frame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-18)
    title:SetText("WXL Reticle World-Object Tooltip Position")
    local expl=frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    expl:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-10)
    expl:SetWidth(560)
    expl:SetJustifyH("LEFT")
    expl:SetText("Positions native world-object tooltips beside the center reticle while mouselooking. No WXL DLLs are replaced. Changing settings takes effect on the next object hover.")
    enableCheck=CreateFrame("CheckButton","WXLReticleTipEnabledCheck",frame,"UICheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-103)
    getglobal(enableCheck:GetName().."Text"):SetText("Enable center-reticle tooltip positioning")
    enableCheck:SetChecked(DB.enabled)
    enableCheck:SetScript("OnClick",function(self)DB.enabled=not not self:GetChecked() end)
    xSlider=slider(frame,"WXLReticleTipXSlider","Horizontal offset (right +)",35,-182,-350,350,DB.offsetX,function(v)DB.offsetX=v end)
    ySlider=slider(frame,"WXLReticleTipYSlider","Vertical offset (up +)",35,-263,-260,260,DB.offsetY,function(v)DB.offsetY=v end)
    local note=frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    note:SetPoint("TOPLEFT",frame,"TOPLEFT",34,-335)
    note:SetWidth(560);note:SetJustifyH("LEFT")
    note:SetText("Alternative: /rtip on | off | x 56 | y -28 | reset | status. Reticle interaction and hover detection are unchanged.")
    frame:SetScript("OnShow",function()
        if enableCheck then enableCheck:SetChecked(DB.enabled) end
        if xSlider then xSlider:SetValue(DB.offsetX) end
        if ySlider then ySlider:SetValue(DB.offsetY) end
    end)
    InterfaceOptions_AddCategory(frame)
end
local function Cmd(msg)
    local verb,rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    verb=string.lower(verb or "")
    if verb=="on" then DB.enabled=true;log("Positioning enabled. Test one stationary road sign.")
    elseif verb=="off" then DB.enabled=false;log("Positioning disabled; stock hover anchor restored on next tooltip.")
    elseif verb=="x" then DB.offsetX=clamp(rest,-350,350);log("Horizontal offset = "..DB.offsetX)
    elseif verb=="y" then DB.offsetY=clamp(rest,-260,260);log("Vertical offset = "..DB.offsetY)
    elseif verb=="reset" then DB.enabled=false;DB.offsetX=56;DB.offsetY=-28;log("Defaults restored (feature OFF).")
    else
        log("Enabled="..tostring(DB.enabled).." Hook="..tostring(hooked).." X="..DB.offsetX.." Y="..DB.offsetY.." Errors="..errors.."; /rtip on|off|x NUM|y NUM|reset|status")
    end
end
addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent",function(self,event,name)
    if name ~= addonName then return end
    if type(WXLReticleTooltipPositionDB) ~= "table" then WXLReticleTooltipPositionDB={} end
    DB=WXLReticleTooltipPositionDB
    -- New installs default OFF: never change the restored, known-working hover behavior automatically.
    if DB.enabled == nil then DB.enabled=false end
    DB.enabled=not not DB.enabled
    DB.offsetX=clamp(DB.offsetX or 56,-350,350)
    DB.offsetY=clamp(DB.offsetY or -28,-260,260)
    SLASH_WXLRETICLETIP1="/rtip"
    SLASH_WXLRETICLETIP2="/reticletooltip"
    SlashCmdList["WXLRETICLETIP"]=Cmd
    if GameTooltip and type(GameTooltip.HookScript)=="function" then
        -- Native WXL World Hover 0.1.0 invokes CGTooltip::SetDefaultAnchor
        -- before SetObject, which fires OnTooltipSetDefaultAnchor. This hook
        -- runs after the native/Blizzard default-anchor handler and any DragonUI
        -- cursor hook. UI-only, and only during native mouselook.
        local ok = pcall(function()
            GameTooltip:HookScript("OnTooltipSetDefaultAnchor",AnchorTooltip)
        end)
        hooked=ok
        if not ok then log("Tooltip hook unavailable; addon is inert. Original tooltip remains untouched.") end
    else
        log("Tooltip API unavailable; addon is inert. Original tooltip remains untouched.")
    end
    MakeOptions()
    self:UnregisterEvent("ADDON_LOADED")
end)
