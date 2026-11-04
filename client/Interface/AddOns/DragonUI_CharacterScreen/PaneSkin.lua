-- Presentation for DragonUI's pooled lists. Native row data, callbacks and sliders stay intact.
local DragonUI = _G.DragonUI
local CP = DragonUI and DragonUI.CharacterPanel
if not CP then return end
local ASSET = "Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\"

local function ink(text)
    if not text then return end
    text:SetTextColor(0.22, 0.11, 0.035)
    text:SetShadowColor(0, 0, 0, 0)
    text:SetShadowOffset(0, 0)
end

local function light(text)
    if not text then return end
    text:SetTextColor(1, 0.94, 0.82)
    text:SetShadowColor(0, 0, 0, 0.95)
    text:SetShadowOffset(1, -1)
end

local function strip(owner, path, layer, cap, vertical)
    if not vertical and (path=="SectionBannerHD"or path=="ChromeStripHD")then
        return DragonUICharacterControlArt.Horizontal(owner,path=="SectionBannerHD"and"SectionAA"or"ChromeAA",layer)
    end
    local art = {}
    for i = 1, 3 do
        local t = owner:CreateTexture(nil, layer)
        t:SetTexture(ASSET .. path)
        if vertical then
            t:SetTexCoord(0, 1, i == 1 and 0 or (i == 2 and 0.12 or 0.88),
                i == 1 and 0.12 or (i == 2 and 0.88 or 1))
            if i == 1 then
                t:SetPoint("TOPLEFT", owner, "TOPLEFT"); t:SetPoint("TOPRIGHT", owner, "TOPRIGHT")
                t:SetHeight(cap)
            elseif i == 3 then
                t:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT"); t:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT")
                t:SetHeight(cap)
            else
                t:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, -cap)
                t:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, cap)
            end
        else
            t:SetTexCoord(i == 1 and 0 or (i == 2 and 0.07 or 0.93),
                i == 1 and 0.07 or (i == 2 and 0.93 or 1), 0, 1)
            if i == 1 then
                t:SetPoint("TOPLEFT", owner, "TOPLEFT"); t:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT")
                t:SetWidth(cap)
            elseif i == 3 then
                t:SetPoint("TOPRIGHT", owner, "TOPRIGHT"); t:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT")
                t:SetWidth(cap)
            else
                t:SetPoint("TOPLEFT", owner, "TOPLEFT", cap, 0)
                t:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", -cap, 0)
            end
        end
        art[i] = t
    end
    return art
end

local function section(frame)
    if frame.Chevron and frame.Text then
        if not frame._duiPageBanner then
            for _, r in ipairs({frame:GetRegions()}) do
                if r:GetObjectType() == "Texture" then r:SetAlpha(0) end
            end
            frame._duiPageBanner = strip(frame, "SectionBannerHD", "BACKGROUND", 18)
            frame._duiPageHover = strip(frame, "SectionBannerHD", "HIGHLIGHT", 18)
            for _, t in ipairs(frame._duiPageHover) do t:SetBlendMode("ADD"); t:SetAlpha(0.16) end
            frame._duiPageGlyph = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame._duiPageGlyph:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
        end
        frame._duiPageGlyph:SetText(frame._collapsed and "+" or "-")
        light(frame._duiPageGlyph)
        frame.Text:ClearAllPoints()
        frame.Text:SetPoint("LEFT", frame, "LEFT", 16, 0)
        frame.Text:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
        frame.Text:SetJustifyH("LEFT"); frame.Text:SetJustifyV("MIDDLE")
        light(frame.Text)
    elseif frame.Bg and frame.Hl then
        -- The stats pane uses a different header constructor from the pooled lists.
        frame.Bg:SetAlpha(0);frame.Hl:SetAlpha(0)
        if not frame._duiPageBanner then
            frame._duiPageBanner=DragonUICharacterControlArt.Horizontal(frame,"SectionAA","BACKGROUND")
            frame._duiPageHover=DragonUICharacterControlArt.Horizontal(frame,"SectionAA","HIGHLIGHT")
            for _,t in ipairs(frame._duiPageHover)do t:SetBlendMode("ADD");t:SetAlpha(.35)end
        end
        DragonUICharacterControlArt.Refresh(frame._duiPageBanner)
        DragonUICharacterControlArt.Refresh(frame._duiPageHover)
        for _, r in ipairs({frame:GetRegions()}) do
            if r:GetObjectType() == "FontString" then
                r:ClearAllPoints(); r:SetPoint("CENTER", frame.Bg, "CENTER", 0, -1)
                r:SetJustifyH("CENTER"); r:SetJustifyV("MIDDLE"); light(r)
            end
        end
    end
end

local function fitCaption(bar)
    local text = bar.Caption
    local face = text:GetFont()
    if not face then return end
    local width = math.max(20,bar:GetWidth()-12)
    local size = 10
    text:ClearAllPoints(); text:SetPoint("CENTER",bar,"CENTER",0,0)
    text:SetWidth(0)
    text:SetFont(face,size,"")
    while text:GetStringWidth() > width and size > 7 do
        size = size - 0.5; text:SetFont(face,size,"")
    end
    text:SetWidth(width); text:SetHeight(bar:GetHeight()-6)
end

local function meter(bar)
    bar:SetHeight(18)
    if not bar._duiPageFrame then
        local fill = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
        for _, r in ipairs({bar:GetRegions()}) do
            if r:GetObjectType() == "Texture" and r ~= fill then r:SetAlpha(0) end
        end
        -- Nine-sliced from the approved equipment frame, so corners stay sharp on narrow bars.
        local edges = {}
        local uv = {0, 0.18, 0.82, 1}
        for y = 1,3 do for x = 1,3 do
            if x ~= 2 or y ~= 2 then
                local t = bar:CreateTexture(nil, "OVERLAY", nil, 1)
                t:SetTexture(ASSET .. "EquipmentBorderHD")
                t:SetTexCoord(uv[x],uv[x+1],uv[y],uv[y+1])
                local left, right = x == 1, x == 3
                local top, bottom = y == 1, y == 3
                if x == 2 then
                    t:SetPoint(top and "TOPLEFT" or "BOTTOMLEFT",bar,top and "TOPLEFT" or "BOTTOMLEFT",3,0)
                    t:SetPoint(top and "TOPRIGHT" or "BOTTOMRIGHT",bar,top and "TOPRIGHT" or "BOTTOMRIGHT",-3,0)
                    t:SetHeight(3)
                elseif y == 2 then
                    t:SetPoint(left and "TOPLEFT" or "TOPRIGHT",bar,left and "TOPLEFT" or "TOPRIGHT",0,-3)
                    t:SetPoint(left and "BOTTOMLEFT" or "BOTTOMRIGHT",bar,left and "BOTTOMLEFT" or "BOTTOMRIGHT",0,3)
                    t:SetWidth(3)
                else
                    local p = (top and "TOP" or "BOTTOM") .. (left and "LEFT" or "RIGHT")
                    t:SetPoint(p,bar,p,0,0); t:SetSize(3,3)
                end
                edges[#edges+1] = t
            end
        end end
        local backing = bar:CreateTexture(nil,"BACKGROUND")
        backing:SetTexture(0.07,0.055,0.04,0.94); backing:SetAllPoints(bar)
        bar._duiPageFrame = edges
    end
    -- Reapply after every data repaint; neither standing colors nor the progress range change.
    if bar.Caption then
        bar.Caption:SetDrawLayer("OVERLAY",7)
        bar.Caption:SetJustifyH("CENTER"); bar.Caption:SetJustifyV("MIDDLE")
        light(bar.Caption)
        if not bar._duiCaptionHooked then
            bar._duiCaptionHooked = true
            hooksecurefunc(bar.Caption,"SetText",function() fitCaption(bar) end)
        end
        fitCaption(bar)
    end
end

local function fitRowLabel(row)
    if not (row.Title and row.Meter) then return end
    local title,bar = row.Title,row.Meter
    -- Recycled skill and faction rows share a trailing meter. Give the name roughly two
    -- thirds of the usable line, keeping the existing meter anchor and native interactions.
    local trailing = row.Unlearn and 26 or 4
    local barWidth = math.max(70,math.min(99,row:GetWidth()*0.30))
    bar:SetWidth(barWidth)
    local available = math.max(40,row:GetWidth()-12-8-trailing-barWidth)
    local face = title:GetFont()
    local size = 11
    title:ClearAllPoints()
    title:SetPoint("LEFT",row,"LEFT",12,0)
    title:SetWidth(0)
    title:SetFont(face,size,"")
    while title:GetStringWidth() > available and size > 10 do
        size = size-0.5; title:SetFont(face,size,"")
    end
    title:SetWidth(available)
    title:SetHeight(math.max(20,row:GetHeight()-2))
    title:SetJustifyH("LEFT"); title:SetJustifyV("MIDDLE")
    if title.SetWordWrap then title:SetWordWrap(true) end
    if title.SetNonSpaceWrap then title:SetNonSpaceWrap(false) end
    if bar.Caption then fitCaption(bar) end
end

function DragonUICharacterScreen_AlignScroll(scroll, rail)
    if not (scroll and rail and scroll:GetName()) then return end
    local bar = _G[scroll:GetName() .. "ScrollBar"]
    local host = scroll:GetParent()
    if not (bar and host) then return end
    local contentRight, pageRight, hostRight = scroll:GetRight(), rail:GetRight(), host:GetRight()
    if not (bar and contentRight and pageRight and hostRight) then return end
    -- Inner binding is 14 logical pixels from the rail's outer edge. Center the entire thumb
    -- between that line and the banners; retain DragonUI's vertical range and drag geometry.
    local hostScale = host:GetEffectiveScale()
    local railRatio = rail:GetEffectiveScale()/hostScale
    contentRight = contentRight*scroll:GetEffectiveScale()/hostScale
    pageRight = pageRight*railRatio
    local center = (contentRight + pageRight-14*railRatio)/2
    if not bar._duiVerticalAnchors then
        bar._duiVerticalAnchors = {{bar:GetPoint(1)},{bar:GetPoint(2)}}
    end
    bar:ClearAllPoints()
    for _, p in ipairs(bar._duiVerticalAnchors) do
        if p[1] then bar:SetPoint(p[1],p[2],p[3],center-hostRight+bar:GetWidth()/2,p[5]) end
    end
end

local pendingAlignment = {}
local function scheduleAlignment(scroll,rail)
    local name = scroll:GetName()
    if not (name and _G[name .. "ScrollBar"]) then return end
    if not scroll._duiAlignmentHook then
        scroll._duiAlignmentHook = true
        scroll:HookScript("OnSizeChanged",function() scheduleAlignment(scroll,rail) end)
    end
    if pendingAlignment[scroll] then return end
    pendingAlignment[scroll] = true
    -- On a tab switch WoW can return the previous viewport bounds until the next layout tick.
    DragonUI:After(0.02,function()
        pendingAlignment[scroll] = nil
        if _G.CharacterFrame and CharacterFrame:IsShown() then
            DragonUICharacterScreen_AlignScroll(scroll,rail)
        end
    end)
end

local function skinScroll(scroll)
    if not scroll or not scroll.GetName then return end
    local name = scroll:GetName()
    local bar = name and _G[name .. "ScrollBar"]
    if not bar or not bar._duiGrip or bar._duiPageTrack then return end
    -- Alpha, rather than Hide, also suppresses old pieces re-shown by DragonUI's drag sync.
    for _, r in ipairs({bar:GetRegions()}) do
        if r:GetObjectType() == "Texture" then r:SetAlpha(0) end
    end
    bar:SetWidth(14)
    local track = CreateFrame("Frame",nil,bar)
    local gap = bar._duiSteppers and 19 or 0
    track:SetPoint("TOPLEFT",bar,"TOPLEFT",0,-gap)
    track:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",0,gap)
    bar._duiPageTrack = DragonUICharacterControlArt.Vertical(track,"TrackAA","BACKGROUND")
    local grip = CreateFrame("Frame",nil,bar)
    grip:SetPoint("TOP",bar._duiGrip,"TOP",0,0)
    grip:SetPoint("BOTTOM",bar._duiGrip,"BOTTOM",0,0)
    grip:SetWidth(14)
    bar._duiPageGrip = DragonUICharacterControlArt.Vertical(grip,"ThumbAA","ARTWORK")
    local function syncVisibility()
        if bar._duiGrip:IsShown() then grip:Show() else grip:Hide() end
    end
    scroll:HookScript("OnScrollRangeChanged",syncVisibility)
    scroll:HookScript("OnVerticalScroll",syncVisibility)
    scroll:HookScript("OnShow",syncVisibility)
    bar:HookScript("OnMinMaxChanged",syncVisibility)
    syncVisibility()
    for _, pair in ipairs({{"ScrollUpButton","^"},{"ScrollDownButton","v"}}) do
        local button = _G[name .. "ScrollBar" .. pair[1]]
        if button and bar._duiSteppers then
            if button._duiArt then button._duiArt:SetAlpha(0) end
            button._duiPageArrow = button:CreateFontString(nil,"OVERLAY","GameFontNormal")
            button._duiPageArrow:SetPoint("CENTER",button,"CENTER",0,0)
            button._duiPageArrow:SetText(pair[2]); ink(button._duiPageArrow)
        end
    end
end

function DragonUICharacterScreen_SkinPane(frame)
    if not frame then return end
    if frame == _G.DragonUICharacterStatsPane then
        for _, r in ipairs({frame:GetRegions()}) do
            if r:GetObjectType() == "Texture" then r:SetAlpha(0) end
        end
    end
    local isHeader = (frame.Chevron and frame.Text) or (frame.Bg and frame.Hl)
    if isHeader then section(frame) end
    if frame.Meter then meter(frame.Meter) end
    fitRowLabel(frame)
    if frame.Label and frame.Menu then
        frame.Label._duiParchmentLight = true
        if not frame._duiMenuInkHooked then
            frame._duiMenuInkHooked = true
            frame.Menu:HookScript("OnShow",function(menu)
                for _, row in ipairs(menu.Rows or {}) do
                    if row.Text then light(row.Text) end
                end
            end)
        end
    end
    if frame.Unlearn and frame.Unlearn.Glyph then
        frame.Unlearn.Glyph:SetVertexColor(0.38,0.25,0.1)
    end
    if frame.Toggle and frame.Text then
        local toggle = frame.Toggle
        if not toggle._duiPageGlyph then
            for _, r in ipairs({toggle:GetRegions()}) do
                if r:GetObjectType() == "Texture" then r:SetAlpha(0) end
            end
            toggle._duiPagePlate = strip(toggle,"ChromeStripHD","BACKGROUND",4)
            toggle._duiPageGlyph = toggle:CreateFontString(nil,"OVERLAY","GameFontNormal")
            toggle._duiPageGlyph:SetPoint("CENTER",toggle,"CENTER",0,0)
        end
        toggle._duiPageGlyph:SetText(frame._collapsed and "+" or "-")
        light(toggle._duiPageGlyph)
    end
    for _, r in ipairs({frame:GetRegions()}) do
        if r:GetObjectType() == "FontString" and not isHeader and r ~= frame.Caption and
            r ~= frame._duiPageGlyph then
            local red,green,blue = r:GetTextColor()
            local semantic = (green > .62 and red < .48) or
                (red > .65 and green < .35) or (blue > .55 and blue > red * 1.35)
            if r._duiParchmentLight then light(r)
            elseif not semantic or frame.Title or frame.Value then ink(r) end
        end
    end
    skinScroll(frame)
    if _G.DragonUIImmersiveCharacterRail then
        scheduleAlignment(frame,_G.DragonUIImmersiveCharacterRail)
    end
    for _, child in ipairs({frame:GetChildren()}) do DragonUICharacterScreen_SkinPane(child) end
end

local pending = {}
local function afterPaint(scroll, content)
    DragonUICharacterScreen_SkinPane(content)
    skinScroll(scroll)
    -- Honor refreshes its masthead after painting the list, hence the end-of-update pass.
    if not pending[scroll] then
        pending[scroll] = true
        DragonUI:After(0, function()
            pending[scroll] = nil
            local host = scroll:GetParent()
            DragonUICharacterScreen_SkinPane(host)
            if scroll:GetName() == "DragonUIHonorScroll" then
                for _, child in ipairs({host:GetChildren()}) do
                    if child:GetHeight() == 64 then
                        local textures, fonts = {}, {}
                        for _, r in ipairs({child:GetRegions()}) do
                            if r:GetObjectType() == "Texture" then textures[#textures+1]=r
                            elseif r:GetObjectType() == "FontString" then fonts[#fonts+1]=r end
                        end
                        if #textures == 2 and #fonts == 2 then
                            textures[1]:SetTexture(ASSET .. "HonorSealHD")
                            textures[1]:SetTexCoord(0,1,0,1); textures[1]:SetDesaturated(false)
                            textures[1]:SetSize(62,62); textures[1]:Show()
                            ink(fonts[1]); ink(fonts[2])
                        end
                    end
                end
            end
        end)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function()
    if CP.PaintListRows then hooksecurefunc(CP,"PaintListRows",afterPaint) end
    if CP.UpdateListHeader then hooksecurefunc(CP,"UpdateListHeader",section) end
end)
