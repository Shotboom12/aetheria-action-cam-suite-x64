-- Trainer presentation only: Blizzard retains service selection, filtering and purchases.
local addon=select(2,...)
local W,H=640,346
local built,busy=false,false
local ui={}
local elapsed,offset,bottom=0,0,36
local function place(f,p,r,rp,x,y)
    if not f then return end
    f:ClearAllPoints()
    local setter=f.MASetPoint or f.SetPoint
    setter(f,p,r,rp,x or 0,y or 0)
end
local function art(s) return "Interface\\AddOns\\DragonUI\\Textures\\"..s end
local function label(parent,font,size)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    if size then t:SetFont("Fonts\\FRIZQT__.TTF",size,"") end
    t:SetJustifyH("LEFT")
    return t
end
local FF_FRAME_TEX = "Interface\\AddOns\\DragonUI\\modules\\worldmap\\textures\\ff_chrome_frame"
local FF_SHEET_W, FF_SHEET_H = 1024, 512
local FF_CORNER = 32 * 0.4
local FF_TOP = 4.8
local FF_BOTTOM = 4.8
local FF_SIDE = 4.8

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

local function matchingBorder(parent)
    local holder = CreateFrame("Frame", nil, parent)
    -- Half-overlap the panel edge, protecting its content padding.
    local outset = 2
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", -outset, outset)
    holder:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", outset, -outset)
    holder:SetFrameLevel(parent:GetFrameLevel() + 8)
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


local function panel(parent,w,h,p,r,rp,x,y,paper)
    local f=CreateFrame("Frame",nil,parent)
    f:SetSize(w,h);place(f,p,r,rp,x,y);f:EnableMouse(false)
    f:SetFrameLevel(parent:GetFrameLevel()+1)
    local t=f:CreateTexture(nil,"BACKGROUND")
    if paper then
        t:SetAtlasTexture(paper=="left" and "spellbook-background-evergreen-left" or "spellbook-background-evergreen-right")
    else
        t:SetTexture(art("UI\\ui-background-marble"));t:SetHorizTile(true);t:SetVertTile(true)
        t:SetVertexColor(.65,.65,.65)
    end
    t:SetAllPoints(f)
    return f
end
local function strip(f)
    if not f then return end
    for _,t in ipairs({f:GetRegions()}) do
        if t:IsObjectType("Texture") then t:SetAlpha(0) end
    end
end
local function skinScrollBar(bar)
    if not bar then return end
    local thumb=bar:GetThumbTexture()
    for _,r in ipairs({bar:GetRegions()}) do
        if r:GetObjectType()=="Texture" and r~=thumb then r:SetAlpha(0) end
    end
    bar:SetWidth(12)
    local function rail(l,t,r,b)
        local tex=bar:CreateTexture(nil,"BORDER");tex:SetTexture(art("Trainer\\JournalScrollRail"))
        tex:SetTexCoord(l/32,r/32,t/32,b/32)
        tex:SetVertexColor(.42,.28,.12,.7)
        return tex
    end
    local top=rail(22,2,30,10);top:SetSize(4,4);top:SetPoint("TOP",bar,"TOP")
    local bottom=rail(22,14,30,22);bottom:SetSize(4,4);bottom:SetPoint("BOTTOM",bar,"BOTTOM")
    local middle=rail(12,14,20,22);middle:SetWidth(4)
    middle:SetPoint("TOP",top,"BOTTOM");middle:SetPoint("BOTTOM",bottom,"TOP")
    thumb:SetTexture(art("Trainer\\JournalScrollThumb"));thumb:SetTexCoord(0,1,0,1)
    thumb:SetSize(8,28);thumb:SetVertexColor(.6,.43,.23)
    local name=bar:GetName()
    for _,spec in ipairs({{"ScrollUpButton",18,29,true},{"ScrollDownButton",2,13,false}}) do
        local button=_G[name..spec[1]]
        if button then
            -- Remove the stock square slab behind the arrow.
            for _,r in ipairs({button:GetRegions()}) do
                if r:GetObjectType()=="Texture" then r:SetTexture(nil) end
            end
            button:SetSize(17,11)
            place(button,spec[4] and "BOTTOM" or "TOP",bar,spec[4] and "TOP" or "BOTTOM",0,spec[4] and 1 or -1)
            for _,state in ipairs({{"Normal",1},{"Pushed",.8},{"Disabled",.28},{"Highlight",.3}}) do
                button["Set"..state[1].."Texture"](button,art("Trainer\\JournalScrollArrows"))
                local tex=button["Get"..state[1].."Texture"](button)
                tex:SetTexCoord(2/64,19/64,spec[2]/32,spec[3]/32)
                tex:ClearAllPoints();tex:SetAllPoints(button)
                tex:SetVertexColor(.55,.37,.17);tex:SetAlpha(state[2])
                if state[1]=="Highlight" then tex:SetBlendMode("ADD") end
            end
        end
    end
end


local function moneyCenter()
    local f=ClassTrainerMoneyFrame
    if not f then return end
    local first,last
    for _,coin in ipairs({"Gold","Silver","Copper"}) do
        local b=_G["ClassTrainerMoneyFrame"..coin.."Button"]
        if b and b:IsShown() then
            local l,r=b:GetLeft(),b:GetRight()
            if l and r then first=first and math.min(first,l) or l;last=last and math.max(last,r) or r end
        end
    end
    if first and last and f:GetLeft() then
        local c=(first+last)/2-f:GetLeft()
        place(f,"LEFT",ui.footer,"CENTER",-c,14)
    end
end
local function details()
    if not built or not ClassTrainerFrame:IsShown() then return end
    local c=ClassTrainerDetailScrollChildFrame
    c:SetWidth(274)
    place(ClassTrainerSkillIcon,"TOPLEFT",c,"TOPLEFT",12,-5)
    ClassTrainerSkillIcon:SetSize(48,48)
    local tex=ClassTrainerSkillIcon:GetNormalTexture()
    if tex then tex:SetTexCoord(.06,.94,.06,.94);tex:ClearAllPoints();tex:SetSize(41,41);tex:SetPoint("CENTER",ClassTrainerSkillIcon,"CENTER",0,0) end
    place(ClassTrainerSkillName,"TOPLEFT",c,"TOPLEFT",72,-5)
    ClassTrainerSkillName:SetWidth(190);ClassTrainerSkillName:SetTextColor(.22,.13,.06)
    place(ClassTrainerSubSkillName,"TOPLEFT",ClassTrainerSkillName,"BOTTOMLEFT",0,-3)
    ClassTrainerSubSkillName:SetTextColor(.35,.24,.13)
    local id=ClassTrainerFrame.selectedService
    if id then
        local _,rank=GetTrainerServiceInfo(id)
        ClassTrainerSubSkillName:SetText(rank and rank~="" and "("..rank..")" or "")
    end
    place(ClassTrainerSkillRequirements,"TOPLEFT",c,"TOPLEFT",0,-68)
    ClassTrainerSkillRequirements:SetWidth(262);ClassTrainerSkillRequirements:SetTextColor(.27,.18,.10)
    local reqH=math.max(16,ClassTrainerSkillRequirements:GetStringHeight())
    place(ClassTrainerCostLabel,"TOPLEFT",ClassTrainerSkillRequirements,"BOTTOMLEFT",0,-12)
    ClassTrainerCostLabel:SetTextColor(.27,.16,.07)
    place(ClassTrainerSkillDescription,"TOPLEFT",ClassTrainerCostLabel,"BOTTOMLEFT",0,-14)
    if not ClassTrainerCostLabel:IsShown() then
        place(ClassTrainerSkillDescription,"TOPLEFT",ClassTrainerSkillRequirements,"BOTTOMLEFT",0,-14)
    end
    ClassTrainerSkillDescription:SetWidth(262);ClassTrainerSkillDescription:SetTextColor(.22,.13,.07)
    ClassTrainerSkillDescription:SetFont("Fonts\\FRIZQT__.TTF",12,"")
    for _,text in ipairs({ClassTrainerSkillName,ClassTrainerSubSkillName,ClassTrainerSkillRequirements,ClassTrainerCostLabel,ClassTrainerSkillDescription}) do
        text:SetFont("Fonts\\FRIZQT__.TTF",text==ClassTrainerSkillName and 14 or 12,"")
        text:SetTextColor(.25,.16,.08);text:SetShadowOffset(0,0)
    end
    -- Center the complete title/rank block beside the well, including wrapped names.
    local title,rank=ClassTrainerSkillName,ClassTrainerSubSkillName
    title:SetWordWrap(true);title:SetHeight(0)
    rank:SetWidth(190);rank:SetWordWrap(true);rank:SetHeight(0)
    local titleHeight=math.max(14,title:GetStringHeight())
    local rankHeight=(rank:GetText() or "")~="" and math.max(12,rank:GetStringHeight()) or 0
    local blockHeight=titleHeight+(rankHeight>0 and rankHeight+3 or 0)
    place(title,"TOPLEFT",ClassTrainerSkillIcon,"RIGHT",12,blockHeight/2)
    place(rank,"TOPLEFT",title,"BOTTOMLEFT",0,-3)
    -- Leave room below a multiline title before the prerequisite block begins.
    local requirementsTop=math.max(68,29+blockHeight/2+12)
    place(ClassTrainerSkillRequirements,"TOPLEFT",c,"TOPLEFT",0,-requirementsTop)
    reqH=math.max(16,ClassTrainerSkillRequirements:GetStringHeight())
    c:SetHeight(math.max(194,requirementsTop+reqH+50+ClassTrainerSkillDescription:GetStringHeight()))
    -- Native requirement templates mark met prerequisites white and unmet ones red.
    -- Recolor only the white runs, preserving each prerequisite's native result.
    local requirements=ClassTrainerSkillRequirements:GetText()
    if requirements then
        requirements=requirements:gsub("|c(%x%x%x%x%x%x%x%x)",function(color)
            return "|c"..(color:lower()=="ffffffff" and "ff21571f" or color)
        end)
        ClassTrainerSkillRequirements:SetText(requirements)
    end
    ClassTrainerSkillName:SetShadowColor(0,0,0,.65)
    ClassTrainerSkillName:SetShadowOffset(1,-1)
    local count=CLASS_TRAINER_SKILLS_DISPLAYED or 11
    for i=1,11 do
        local b=_G["ClassTrainerSkill"..i]
        if b then
            place(b,"TOPLEFT",ui.main,"TOPLEFT",12,-38-(i-1)*20)
            b:SetSize(280,20)
            local t=_G["ClassTrainerSkill"..i.."Text"]
            if t then
                local sub=_G["ClassTrainerSkill"..i.."SubText"]
                t:SetWidth(sub and sub:IsShown() and 175 or 230)
                t:SetFont("Fonts\\FRIZQT__.TTF",12,"")
                local _,_,kind=GetTrainerServiceInfo(b:GetID())
                local r,g,bl=.25,.16,.08
                if kind=="available" then r,g,bl=.13,.34,.12
                elseif kind=="unavailable" then r,g,bl=.58,.12,.08
                elseif kind=="used" then r,g,bl=.42,.36,.28 end
                t:SetTextColor(r,g,bl);t:SetShadowOffset(0,0)
                if sub then sub:SetTextColor(r,g,bl);sub:SetShadowOffset(0,0) end
            end
        end
    end
    ClassTrainerSkillHighlightFrame:SetSize(280,20)
    ClassTrainerSkillHighlight:SetAlpha(.22)
    if ClassTrainerCollapseAllButton:GetFontString() then ClassTrainerCollapseAllButton:GetFontString():SetTextColor(.3,.18,.08) end
    local lb=ClassTrainerListScrollFrameScrollBar
    place(lb,"TOP",ui.main,"TOPLEFT",300,-52)
    lb:SetPoint("BOTTOM",ui.main,"BOTTOMLEFT",300,23)
    local db=ClassTrainerDetailScrollFrameScrollBar
    place(db,"TOP",ui.main,"TOPRIGHT",-12,-70)
    db:SetPoint("BOTTOM",ui.main,"BOTTOMRIGHT",-12,23)
    ClassTrainerListScrollFrame:SetHeight(count*20)
    ClassTrainerDetailScrollFrame:SetSize(266,194)
    ui.title:SetText(ClassTrainerNameText:GetText() or UnitName("npc") or "")
    ui.greeting:SetText(ClassTrainerGreetingText:GetText() or "")
end
local function anchor()
    if busy or not built or not ClassTrainerFrame:IsShown() or InCombatLockdown() then return end
    busy=true
    local f=ClassTrainerFrame
    if MovAny then
        if MovAny.UnlockPoint then MovAny:UnlockPoint(f) end
        if MovAny.UnlockScale then MovAny:UnlockScale(f) end
    end
    f:SetSize(W,H)
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    local fit=math.min(1,(sw-40)/W,(sh-100)/H)
    f:SetScale(fit)
    local cfg=ImmersionSetup
    bottom=math.max(16,math.min(cfg and tonumber(cfg.boxoffsetY) or 36,sh-H*fit-20))
    place(f,"BOTTOM",UIParent,"BOTTOM",0,(bottom+offset)/fit)
    busy=false
end
local function start()
    if not built then return end
    local instant=ImmersionSetup and ImmersionSetup.anidivisor and ImmersionSetup.anidivisor<=1
    elapsed=instant and .28 or 0;offset=instant and 0 or -64
    ClassTrainerFrame:SetAlpha(instant and 1 or 0)
    anchor();details()
    ui.driver:Show()
    if addon.VisibilityFade then addon.VisibilityFade.RefreshAll() end
end
local function build()
    if built or not ClassTrainerFrame then return end
    local f=ClassTrainerFrame
    strip(f)
    for _,name in ipairs({"NineSlice","Inset","Bg","PortraitFrame"}) do
        local child=f[name]
        if child then child:Hide() end
    end
    ClassTrainerNameText:SetAlpha(0);ClassTrainerGreetingText:SetAlpha(0)
    strip(ClassTrainerExpandButtonFrame)
    strip(ClassTrainerListScrollFrame);strip(ClassTrainerDetailScrollFrame)
    if ClassTrainerHorizontalBarLeft then ClassTrainerHorizontalBarLeft:SetAlpha(0) end
    ui.header=panel(f,300,74,"TOP",f,"TOP",0,0)
    -- Same compact, portrait-free stone header as the merchant.
    DragonUI_NineSlice.ApplyLayout(ui.header,DragonUI_NineSlice.GetLayout("NoPortraitFrameTemplate"))
    ui.title=label(ui.header,"GameFontNormal",18)
    ui.title:SetFont("Fonts\\MORPHEUS.TTF",18,"")
    place(ui.title,"TOPLEFT",ui.header,"TOPLEFT",12,-27);ui.title:SetWidth(276)
    local sub=label(ui.header,"GameFontHighlight",12)
    place(sub,"TOPLEFT",ui.header,"TOPLEFT",12,-51);sub:SetText(TRAINER or "Trainer");sub:SetTextColor(.82,.77,.65)
    ui.header:Hide()
    ui.main=panel(f,620,270,"TOP",f,"TOP",0,0)
    matchingBorder(ui.main)
    ui.left=panel(ui.main,305,260,"TOPLEFT",ui.main,"TOPLEFT",5,-5,"left")
    ui.paper=panel(ui.main,305,260,"TOPRIGHT",ui.main,"TOPRIGHT",-5,-5,true)
    local fold=ui.main:CreateTexture(nil,"ARTWORK")
    fold:SetAtlasTexture("spellbook-background-evergreen-ribbon")
    fold:SetSize(30,260);place(fold,"TOP",ui.main,"TOP",0,-5);fold:SetAlpha(.28)
    ui.greeting=label(ui.paper,"GameFontHighlightSmall",11)
    place(ui.greeting,"TOPLEFT",ui.paper,"TOPLEFT",12,-10);ui.greeting:SetWidth(256);ui.greeting:SetHeight(36)
    ui.greeting:SetJustifyV("TOP");ui.greeting:SetTextColor(1,1,1);ui.greeting:SetShadowColor(0,0,0,0);ui.greeting:SetShadowOffset(0,0)
    local divider=ui.paper:CreateTexture(nil,"ARTWORK")
    divider:SetTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\Divider-H")
    divider:SetSize(268,8);place(divider,"TOP",ui.paper,"TOP",0,-46)
    ui.footer=panel(f,220,64,"BOTTOM",f,"BOTTOM",0,0)
    matchingBorder(ui.footer)
    place(ClassTrainerExpandButtonFrame,"TOPLEFT",ui.main,"TOPLEFT",10,-6)
    place(ClassTrainerFrameFilterDropDown,"TOPRIGHT",ui.main,"TOPLEFT",308,-4)
    UIDropDownMenu_SetWidth(ClassTrainerFrameFilterDropDown,120)
    ClassTrainerFrameFilterDropDown:SetFrameLevel(f:GetFrameLevel()+6)
    ClassTrainerExpandButtonFrame:SetFrameLevel(f:GetFrameLevel()+6)
    place(ClassTrainerListScrollFrame,"TOPLEFT",ui.main,"TOPLEFT",12,-38)
    ClassTrainerListScrollFrame:SetWidth(276)
    place(ClassTrainerDetailScrollFrame,"TOPLEFT",ui.paper,"TOPLEFT",12,-58)
    CLASS_TRAINER_SKILL_HEIGHT=20
    for _,scroll in ipairs({ClassTrainerListScrollFrame,ClassTrainerDetailScrollFrame}) do
        scroll:SetFrameLevel(f:GetFrameLevel()+5)
    end
    for i=1,11 do local b=_G["ClassTrainerSkill"..i];b:SetFrameLevel(f:GetFrameLevel()+6) end
    ClassTrainerSkillHighlightFrame:SetFrameLevel(f:GetFrameLevel()+5)
    for _,b in ipairs({ClassTrainerTrainButton,ClassTrainerCancelButton}) do
        b:SetSize(88,22);b:SetFrameLevel(f:GetFrameLevel()+12)
        b:SetNormalTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\OptionBackground-Common")
        b:SetPushedTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\OptionBackground-Common-Red")
        b:SetHighlightTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\ButtonHighlight-Front")
        b:SetDisabledTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\OptionBackground-Grey")
        for _,method in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture","GetDisabledTexture"}) do
            local t=b[method](b);if t then t:SetTexCoord(0,1,0,1);t:SetAllPoints(b) end
        end
    end
    place(ClassTrainerTrainButton,"BOTTOMRIGHT",ui.footer,"BOTTOM",-5,8)
    place(ClassTrainerCancelButton,"BOTTOMLEFT",ui.footer,"BOTTOM",5,8)
    ClassTrainerMoneyFrame:SetFrameLevel(f:GetFrameLevel()+12)
    place(ClassTrainerMoneyFrame,"CENTER",ui.footer,"CENTER",0,14)
    local close=ClassTrainerFrameCloseButton
    close:SetSize(16,16);place(close,"TOPRIGHT",ui.main,"TOPRIGHT",-2,-2)
    close:SetFrameLevel(f:GetFrameLevel()+20)
    for _,s in ipairs({{"GetNormalTexture",.0078125,.3046875},{"GetPushedTexture",.6328125,.9296875},{"GetDisabledTexture",.3203125,.6171875},{"GetHighlightTexture",.0078125,.3046875}}) do
        local t=close[s[1]](close)
        if t then t:SetTexture(art("UI\\redbutton2x"));t:SetTexCoord(s[1]=="GetHighlightTexture" and .44921875 or .15234375,s[1]=="GetHighlightTexture" and .58984375 or .29296875,s[2],s[3]);t:SetAllPoints(close) end
    end
    skinScrollBar(ClassTrainerListScrollFrameScrollBar)
    skinScrollBar(ClassTrainerDetailScrollFrameScrollBar)
    strip(ClassTrainerSkillIcon)
    -- Restore only the actual spell art; replace the oversized empty-slot backing.
    local n=ClassTrainerSkillIcon:GetNormalTexture();if n then n:SetAlpha(1) end
    local ring=CreateFrame("Frame",nil,ClassTrainerSkillIcon)
    ring:SetAllPoints(ClassTrainerSkillIcon);ring:EnableMouse(false)
    local rt=ring:CreateTexture(nil,"OVERLAY");rt:SetAtlasTexture("spellbook-item-iconframe")
    -- Match the spellbook's 48-unit well, 41-unit art and asymmetric atlas padding.
    rt:SetPoint("TOPLEFT",ring,"TOPLEFT",-13.2,1.2)
    rt:SetPoint("BOTTOMRIGHT",ring,"BOTTOMRIGHT",1.2,-8.4)
    ui.driver=CreateFrame("Frame")
    ui.driver:SetScript("OnUpdate",function(_,dt)
        if not f:IsShown() then ui.driver:Hide();return end
        elapsed=math.min(.28,elapsed+dt)
        local p=elapsed/.28
        offset=-64*(1-p)^3
        anchor();moneyCenter();f:SetAlpha(math.min(1,p*1.4))
    end)
    built=true
    hooksecurefunc("ClassTrainerFrame_Update",details)
    hooksecurefunc("ClassTrainer_SetSelection",details)
    hooksecurefunc("UpdateUIPanelPositions",anchor)
    hooksecurefunc(f,"SetPoint",anchor)
    f:HookScript("OnShow",start)
    f:HookScript("OnHide",function()
        ui.driver:Hide();offset=0;f:SetAlpha(1)
        if addon.VisibilityFade then addon.VisibilityFade.RefreshAll() end
    end)
    start()
end
local loader=CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED");loader:RegisterEvent("TRAINER_SHOW");loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent",function() if ClassTrainerFrame then build() end end)
