-- Short presentation fades. Native Show/Hide and Escape handling remain synchronous.
local function restoreParents(state)
    for _, item in ipairs(state.floating or {}) do
        item.frame:SetScale(item.scale)
        item.frame:SetParent(item.parent)
    end
    if state.hiddenContent and not state.character:IsShown() then state.hiddenContent:Hide() end
end

function DragonUICharacterScreen_StopMotion(root)
    local state = root and root._duiMotion
    if not state then return end
    root:SetScript("OnUpdate",nil)
    restoreParents(state)
    state.character:SetAlpha(state.characterAlpha)
    root:SetAlpha(1)
    root._duiMotion = nil
end

function DragonUICharacterScreen_Animate(root, character, opening, complete)
    local startAlpha = root:GetAlpha()
    DragonUICharacterScreen_StopMotion(root)
    local state = {elapsed=0, duration=opening and 0.22 or 0.16,
        character=character, characterAlpha=character:GetAlpha(), floating={}}
    root._duiMotion = state
    if opening then
        root:SetAlpha(0); character:SetAlpha(0)
    else
        -- The stock window has already closed. Retain only its visible information inset for
        -- the final fraction of a second; no native Hide, click or panel-manager call is delayed.
        for _, pane in ipairs({character.Inset, character.InsetRight}) do
            if pane and pane:IsShown() then
                local effectiveScale = pane:GetEffectiveScale()
                state.floating[#state.floating+1] = {frame=pane,parent=pane:GetParent(),scale=pane:GetScale()}
                pane:SetParent(root)
                pane:SetScale(effectiveScale/root:GetEffectiveScale())
            end
        end
        local CP = _G.DragonUI and DragonUI.CharacterPanel
        local scroll = _G.DragonUIHonorScroll
        local active = CP and CP.ActiveTabName and CP.ActiveTabName()
        if active == "DragonUIHonorFrame" and scroll then
            state.closingContent = scroll:GetParent()
        else
            state.closingContent = active == "SkillFrame" and _G.DragonUISkillsPane or
                active == "ReputationFrame" and _G.DragonUIReputationPane or
                active == "TokenFrame" and _G.DragonUICurrencyPane
        end
        root:SetAlpha(startAlpha)
    end
    root:SetScript("OnUpdate",function(self, elapsed)
        -- Stock subframe OnHide callbacks finish after CharacterFrame's OnHide. Retain their
        -- already-populated content for the visual fade only, once that propagation is done.
        if not opening and not state.contentRetained then
            state.contentRetained = true
            if state.closingContent and not state.closingContent:IsShown() then
                state.hiddenContent = state.closingContent
                state.hiddenContent:Show()
            end
        end
        state.elapsed = state.elapsed + elapsed
        local t = math.min(1,state.elapsed/state.duration)
        if opening then
            local alpha = 1 - (1-t)^3
            self:SetAlpha(alpha); character:SetAlpha(state.characterAlpha*alpha)
        else
            self:SetAlpha(startAlpha*(1-t)^2)
        end
        if t == 1 then
            DragonUICharacterScreen_StopMotion(self)
            if not opening then self:Hide() end
            if complete then complete() end
        end
    end)
end
