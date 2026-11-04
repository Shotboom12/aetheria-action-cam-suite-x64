-- Local journal companion. Native quest selection, controls and rewards remain authoritative.
if _G.DragonUIQuestJournal then return end
local J = { version = "1.3.1" }
_G.DragonUIQuestJournal = J
local ART = "Interface\\AddOns\\DragonUI_QuestJournal\\Assets\\"
local W, H, PAGE_SCALE = 1180, 700, 1.52
local BOOK_INSET = 60
-- Measured paper safe areas, independent of the padded native quest-log template.
local PAGE = { left = {76,566}, right = {614,1104}, top = 122, bottom = 532 }
local busy, built = false, false
local frame = QuestLogFrame
local stockTextures = {}

local function place(object, point, relative, relativePoint, x, y)
    object:ClearAllPoints()
    local setter = object == frame and object.MASetPoint or object.SetPoint
    setter(object, point, relative, relativePoint, x or 0, y or 0)
end

local function texture(parent, file, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(ART .. file)
    return t
end

local function hideTextures(parent)
    if not parent then return end
    for _, region in ipairs({parent:GetRegions()}) do
        if region:GetObjectType() == "Texture" then
            stockTextures[region] = true
            region:SetAlpha(0)
        end
    end
end

local slices = {
    top={550,294,790,306}, bottom={550,306,790,294},
    left={490,330,502,400}, right={502,330,490,400},
    tl={490,294,522,326}, tr={522,294,490,326},
    bl={490,326,522,294}, br={522,326,490,294},
}
local function rim(parent, thickness, corner)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetAllPoints(parent)
    holder:SetFrameLevel(parent:GetFrameLevel()+5)
    holder:EnableMouse(false)
    local parts = {}
    for name, uv in pairs(slices) do
        local t = texture(holder, "chrome-frame", "OVERLAY")
        t:SetTexCoord(uv[1]/1024,uv[3]/1024,uv[2]/512,uv[4]/512)
        parts[name] = t
    end
    for _, spec in ipairs({{"tl","TOPLEFT"},{"tr","TOPRIGHT"},{"bl","BOTTOMLEFT"},{"br","BOTTOMRIGHT"}}) do
        local key,anchor=spec[1],spec[2]
        local uv=slices[key]
        -- The atlas corner cell includes an opaque square interior. Render only
        -- two non-overlapping arms of its L, as on the fullscreen world map.
        parts[key]:Hide()
        local top=key=="tl" or key=="tr"
        local left=key=="tl" or key=="bl"
        local f=12/32
        local function cut(u0,v0,u1,v1)
            local t=texture(holder,"chrome-frame","OVERLAY")
            t:SetTexCoord((uv[1]+(uv[3]-uv[1])*u0)/1024,
                (uv[1]+(uv[3]-uv[1])*u1)/1024,
                (uv[2]+(uv[4]-uv[2])*v0)/512,
                (uv[2]+(uv[4]-uv[2])*v1)/512)
            return t
        end
        local horizontal=cut(0,top and 0 or 1-f,1,top and f or 1)
        horizontal:SetSize(corner,thickness)
        horizontal:SetPoint(anchor,holder,anchor)
        local vertical=cut(left and 0 or 1-f,top and f or 0,
            left and f or 1,top and 1 or 1-f)
        vertical:SetSize(thickness,corner-thickness)
        vertical:SetPoint(anchor,holder,anchor,0,top and -thickness or thickness)
        -- Hidden full cells still supply stable endpoint anchors for the rails.
        parts[key]:SetSize(corner,corner);parts[key]:SetPoint(anchor,holder,anchor)
    end
    parts.top:SetHeight(thickness); parts.top:SetPoint("TOPLEFT",parts.tl,"TOPRIGHT"); parts.top:SetPoint("TOPRIGHT",parts.tr,"TOPLEFT")
    parts.bottom:SetHeight(thickness); parts.bottom:SetPoint("BOTTOMLEFT",parts.bl,"BOTTOMRIGHT"); parts.bottom:SetPoint("BOTTOMRIGHT",parts.br,"BOTTOMLEFT")
    parts.left:SetWidth(thickness); parts.left:SetPoint("TOPLEFT",parts.tl,"BOTTOMLEFT"); parts.left:SetPoint("BOTTOMLEFT",parts.bl,"TOPLEFT")
    parts.right:SetWidth(thickness); parts.right:SetPoint("TOPRIGHT",parts.tr,"BOTTOMRIGHT"); parts.right:SetPoint("BOTTOMRIGHT",parts.br,"TOPRIGHT")
    return holder
end

local function ink(fs, size, title)
    if not fs then return end
    fs:SetFont(title and "Fonts\\MORPHEUS.TTF" or "Fonts\\FRIZQT__.TTF", size, "")
    fs:SetTextColor(title and .25 or .19, title and .17 or .13, .08)
    fs:SetShadowColor(0,0,0,0)
    fs:SetShadowOffset(0,0)
end

local function heading(parent, text, bounds)
    local fs=parent:CreateFontString(nil,"OVERLAY")
    ink(fs,28,true); fs:SetText(text)
    fs:SetSize(bounds[2]-bounds[1],40)
    fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
    fs:SetPoint("TOPLEFT",parent,"TOPLEFT",bounds[1],-46)
    local line=texture(parent,"Divider-H","ARTWORK")
    line:SetSize(bounds[2]-bounds[1]-26,12); line:SetPoint("TOP",fs,"BOTTOM",0,-6)
    return fs
end

local function strip(parent, file, layer, cap, vertical)
    local pieces = {}
    for i=1,3 do
        local t=texture(parent,file,layer)
        local low = i==1 and 0 or (i==2 and (vertical and .12 or .07) or (vertical and .88 or .93))
        local high = i==1 and (vertical and .12 or .07) or (i==2 and (vertical and .88 or .93) or 1)
        if vertical then
            t:SetTexCoord(0,1,low,high)
            if i==1 then t:SetPoint("TOPLEFT",parent,"TOPLEFT");t:SetPoint("TOPRIGHT",parent,"TOPRIGHT");t:SetHeight(cap)
            elseif i==3 then t:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT");t:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT");t:SetHeight(cap)
            else t:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-cap);t:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",0,cap) end
        else
            t:SetTexCoord(low,high,0,1)
            if i==1 then t:SetPoint("TOPLEFT",parent,"TOPLEFT");t:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT");t:SetWidth(cap)
            elseif i==3 then t:SetPoint("TOPRIGHT",parent,"TOPRIGHT");t:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT");t:SetWidth(cap)
            else t:SetPoint("TOPLEFT",parent,"TOPLEFT",cap,0);t:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-cap,0) end
        end
        pieces[i]=t
    end
    return pieces
end

local function buttonState(button)
    local enabled=button:IsEnabled()
    for _,t in ipairs(button.journalBacking or {}) do t:SetAlpha(enabled and 1 or .42) end
    local label=button.journalLabel
    if label then
        label:SetTextColor(enabled and 1 or .58,enabled and .94 or .52,enabled and .82 or .42)
    end
end

local function skinButton(button, width)
    if not button then return end
    hideTextures(button)
    for _, name in ipairs({"Left","Middle","Right"}) do
        local part=_G[button:GetName()..name]
        if part then part:SetAlpha(0) end
    end
    button:SetFrameLevel(frame:GetFrameLevel()+12)
    button:SetSize(width,34)
    button.journalBacking=strip(button,"ChromeStripHD","BACKGROUND",12)
    local hover=strip(button,"ChromeStripHD","HIGHLIGHT",12)
    for _,t in ipairs(hover) do t:SetBlendMode("ADD");t:SetAlpha(.16) end
    local font=button:GetFontString()
    if font then
        font:SetFont("Fonts\\FRIZQT__.TTF",14,"")
        place(font,"CENTER",button,"CENTER",0,0)
        font:SetJustifyH("CENTER");font:SetJustifyV("MIDDLE");font:SetShadowOffset(1,-1)
        button.journalLabel=font
    end
    if button.SetPushedTextOffset then button:SetPushedTextOffset(0,0) end
    hooksecurefunc(button,"Enable",buttonState)
    hooksecurefunc(button,"Disable",buttonState)
    buttonState(button)
end

-- Reskin native sliders and buttons; retain their click/wheel/drag and disabled-state logic.
local function skinScrollBar(bar, scrollOwner)
    if not bar then return end
    local thumb=bar:GetThumbTexture()
    for _,r in ipairs({bar:GetRegions()}) do
        if r:GetObjectType()=="Texture" and r~=thumb then r:SetAlpha(0) end
    end
    bar:SetWidth(10)
    bar.journalTrack=strip(bar,"ScrollTrackHD","BORDER",5,true)
    -- Keep the native thumb and its hit geometry; a fitted overlay follows it through drag/scroll.
    thumb:SetAlpha(0);thumb:SetWidth(10)
    local grip=CreateFrame("Frame",nil,bar)
    grip:SetPoint("TOP",thumb,"TOP");grip:SetPoint("BOTTOM",thumb,"BOTTOM");grip:SetWidth(10)
    grip:EnableMouse(false)
    bar.journalGrip=strip(grip,"ScrollThumbHD","ARTWORK",5,true)
    bar.journalGrip[2]:SetTexCoord(0,1,.22,.30)
    local ridges=texture(grip,"ScrollThumbHD","OVERLAY")
    ridges:SetTexCoord(0,1,.4,.6);ridges:SetSize(10,14);ridges:SetPoint("CENTER",grip,"CENTER")
    local function syncThumb()
        local low,high=bar:GetMinMaxValues()
        local scrollable=high > low+.1
        -- HybridScrollFrame retains its last positive slider limits when it disables the bar.
        -- Its explicit range (or the detail viewport's actual range) describes overflow instead.
        if scrollOwner and type(scrollOwner.range)=="number" then
            scrollable=scrollOwner.range>.1
        elseif scrollOwner and scrollOwner.GetVerticalScrollRange then
            scrollable=scrollOwner:GetVerticalScrollRange()>.5
        end
        for _,t in ipairs(bar.journalTrack) do t:SetAlpha(scrollable and .82 or 0) end
        if thumb:IsShown() and scrollable then grip:Show() else grip:Hide() end
        for _,suffix in ipairs({"ScrollUpButton","ScrollDownButton"}) do
            local arrow=_G[bar:GetName()..suffix]
            if arrow then arrow:SetAlpha(scrollable and 1 or 0) end
        end
    end
    bar:HookScript("OnValueChanged",syncThumb)
    bar:HookScript("OnShow",syncThumb)
    if scrollOwner then scrollOwner:HookScript("OnScrollRangeChanged",syncThumb) end
    hooksecurefunc(bar,"SetMinMaxValues",syncThumb)
    hooksecurefunc(thumb,"Show",syncThumb)
    hooksecurefunc(thumb,"Hide",syncThumb)
    bar.journalSync=syncThumb
    syncThumb()
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
                button["Set"..state[1].."Texture"](button,ART.."JournalScrollArrows")
                local tex=button["Get"..state[1].."Texture"](button)
                tex:SetTexCoord(2/64,19/64,spec[2]/32,spec[3]/32)
                tex:ClearAllPoints();tex:SetAllPoints(button)
                tex:SetVertexColor(1,.87,.65);tex:SetAlpha(state[2])
                if state[1]=="Highlight" then tex:SetBlendMode("ADD") end
            end
        end
    end
end

local function rows()
    if not built or not frame:IsShown() then return end
    for _, row in ipairs(QuestLogScrollFrame.buttons or {}) do
        row:SetWidth(math.max(100,QuestLogScrollFrame:GetWidth()-6))
        if not row.journalLine then
            local line=row:CreateTexture(nil,"BACKGROUND")
            line:SetTexture(.34,.23,.12,.16); line:SetHeight(.6)
            line:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",2,0)
            line:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-2,0)
            row.journalLine=line
        end
        ink(row.normalText, row.isHeader and 12 or 11)
        ink(row.tag,9); ink(row.groupMates,9)
        local c = row.isHeader and {.36,.20,.09} or {.19,.15,.09}
        local index=row:GetID()
        if not row.journalToggle then
            local toggle=CreateFrame("Frame",nil,row)
            toggle:SetSize(16,16);toggle:SetPoint("LEFT",row,"LEFT",0,0);toggle:EnableMouse(false)
            strip(toggle,"ChromeStripHD","BACKGROUND",4)
            local glyph=toggle:CreateFontString(nil,"OVERLAY")
            glyph:SetFont("Fonts\\FRIZQT__.TTF",12,"");glyph:SetTextColor(1,.94,.82)
            glyph:SetPoint("CENTER",toggle,"CENTER",0,0)
            row.journalToggle=toggle;row.journalGlyph=glyph
        end
        if row.isHeader then
            local _,_,_,_,_,collapsed=GetQuestLogTitle(index)
            row.journalGlyph:SetText(collapsed and "+" or "-")
            row.journalToggle:Show()
        else row.journalToggle:Hide() end
        for _,t in ipairs({row:GetNormalTexture(),row:GetHighlightTexture()}) do t:SetAlpha(0) end
        if index and not row.isHeader then
            local _,level=GetQuestLogTitle(index)
            if level then
                local native=GetQuestDifficultyColor(level)
                if native.r>.8 and native.g<.4 then c={.57,.12,.07}
                elseif native.r>.8 and native.g<.8 then c={.52,.27,.07}
                elseif native.g>.7 and native.r<.6 then c={.15,.32,.14} end
            end
        end
        row.r,row.g,row.b=c[1],c[2],c[3]
        if index==frame.selectedIndex and not row.isHeader then c={.14,.27,.38} end
        row.normalText:SetTextColor(unpack(c));row.tag:SetTextColor(unpack(c));row.groupMates:SetTextColor(unpack(c))
        if row.isHeader then row.journalLine:Hide() else row.journalLine:Show() end
        if row.check then row.check:SetVertexColor(.40,.29,.10) end
        QuestLogTitleButton_Resize(row)
    end
    local bar=QuestLogScrollFrame.scrollBar or QuestLogScrollFrameScrollBar
    if bar and bar.journalSync then bar.journalSync() end
    if QuestLogSkillHighlight then
        QuestLogSkillHighlight:SetTexture(.45,.31,.10,.16)
        QuestLogSkillHighlight:SetBlendMode("BLEND")
    end
end

local questTextStyles={}
local questInkPreimages={}
local HEADING_INK={.408,.251,.094}
local BODY_INK={.31,.235,.16}
local function setQuestInk(names,color)
    for _,name in ipairs(names) do
        local text=_G[name]
        if text then
            if not questInkPreimages[text] then questInkPreimages[text]={before={text:GetTextColor()},ink=color} end
            text:SetTextColor(unpack(color))
        end
    end
end
local function softenQuestText(parent)
    for _,r in ipairs({parent:GetRegions()}) do
        if r:GetObjectType()=="FontString" then
            local face,size,flags=r:GetFont()
            if face then
                if not questTextStyles[r] then
                    questTextStyles[r]={font={face,size,flags or ""},shadow={r:GetShadowColor()},offset={r:GetShadowOffset()}}
                end
                local red,green,blue=r:GetTextColor()
                -- Dark parchment ink needs no black outline. White coin counts retain a thin
                -- native outline for contrast, but lose the displaced shadow as well.
                if red+green+blue < 2.2 then
                    local clean=(flags or ""):gsub("THICKOUTLINE",""):gsub("OUTLINE","")
                    clean=clean:gsub(",+",","):gsub("^,",""):gsub(",$","")
                    r:SetFont(face,size,clean)
                end
                r:SetShadowColor(0,0,0,0);r:SetShadowOffset(0,0)
            end
        end
    end
    for _,child in ipairs({parent:GetChildren()}) do softenQuestText(child) end
end

local moneyPreimage
local function restoreMoney()
    if J.moneyLine then J.moneyLine:Hide() end
    if moneyPreimage then
        if moneyPreimage.frame:GetAlpha()==0 then moneyPreimage.frame:SetAlpha(moneyPreimage.alpha) end
        moneyPreimage=nil
    end
end

local function rewardMoney()
    local native,label=QuestInfoMoneyFrame,QuestInfoItemReceiveText
    if not native or not label or not GetQuestLogRewardMoney then return end
    local amount=GetQuestLogRewardMoney() or 0
    if amount<=0 or not native:IsShown() or not label:IsShown() then restoreMoney();return end
    if not J.moneyLine then
        local line=CreateFrame("Frame",nil,native:GetParent())
        line:EnableMouse(false)
        line.parts={}
        for i,name in ipairs({"Gold","Silver","Copper"}) do
            local count=line:CreateFontString(nil,"OVERLAY")
            local coin=texture(line,"Coin"..name.."HD.tga","OVERLAY")
            line.parts[i]={count=count,coin=coin}
        end
        J.moneyLine=line
    end
    if not moneyPreimage then moneyPreimage={frame=native,alpha=native:GetAlpha()} end
    native:SetAlpha(0)
    local line=J.moneyLine
    local face,size=label:GetFont()
    size=size or 12
    local iconSize=math.floor(size*.9+.5)
    local values={math.floor(amount/10000),math.floor(amount/100)%100,amount%100}
    local x=0
    for i,part in ipairs(line.parts) do
        local value=values[i]
        if value>0 then
            part.count:SetFont(face or "Fonts\\FRIZQT__.TTF",size,"")
            part.count:SetTextColor(unpack(BODY_INK))
            part.count:SetShadowColor(0,0,0,0);part.count:SetShadowOffset(0,0)
            part.count:SetText(tostring(value))
            place(part.count,"LEFT",line,"LEFT",x,0)
            x=x+part.count:GetStringWidth()+2
            part.coin:SetSize(iconSize,iconSize)
            place(part.coin,"LEFT",line,"LEFT",x,0)
            x=x+iconSize+5
            part.count:Show();part.coin:Show()
        else
            part.count:Hide();part.coin:Hide()
        end
    end
    line:SetSize(math.max(1,x-5),size+2)
    place(line,"LEFT",label,"LEFT",label:GetStringWidth()+8,0)
    line:Show()
end

local function rewardSkin()
    -- QuestInfo widgets are shared with quest-givers. Never style them outside the log.
    if not frame:IsShown() or not QuestInfoFrame or not QuestInfoFrame.questLog then return end
    softenQuestText(QuestLogDetailScrollChildFrame)
    setQuestInk({"QuestInfoTitleHeader","QuestInfoDescriptionHeader","QuestInfoObjectivesHeader","QuestInfoRewardsHeader"},HEADING_INK)
    setQuestInk({"QuestInfoDescriptionText","QuestInfoObjectivesText","QuestInfoGroupSize","QuestInfoRewardText",
        "QuestInfoItemChooseText","QuestInfoItemReceiveText","QuestInfoSpellLearnText","QuestInfoHonorFrameReceiveText",
        "QuestInfoArenaPointsFrameReceiveText","QuestInfoTalentFrameReceiveText","QuestInfoXPFrameReceiveText"},BODY_INK)
    rewardMoney()
    for i=1,20 do
        local item=_G["QuestInfoItem"..i]
        if item and not item.journalRim then
            local icon=_G[item:GetName().."IconTexture"] or item.Icon
            if icon then
                -- Hollow chrome corners, fitted to the icon rather than a padded icon atlas.
                local border=CreateFrame("Frame",nil,item)
                border:SetPoint("TOPLEFT",icon,"TOPLEFT",-0.6,0.6)
                border:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",0.6,-0.6)
                border:EnableMouse(false)
                rim(border,1.35,3.6)
                item.journalRim=border
            end
        end
        if item and item.journalRim then item.journalRim:Show() end
    end
end

local function restoreRewards()
    restoreMoney()
    for text,style in pairs(questInkPreimages) do
        local red,green,blue=text:GetTextColor()
        -- A different material may already have painted the shared header for a quest giver.
        -- Restore only our own color, preserving any newer native/theme paint.
        if math.abs(red-style.ink[1])<.001 and math.abs(green-style.ink[2])<.001
            and math.abs(blue-style.ink[3])<.001 then text:SetTextColor(unpack(style.before)) end
    end
    questInkPreimages={}
    for text,style in pairs(questTextStyles) do
        text:SetFont(unpack(style.font))
        text:SetShadowColor(unpack(style.shadow));text:SetShadowOffset(unpack(style.offset))
    end
    questTextStyles={}
    for i=1,20 do
        local item=_G["QuestInfoItem"..i]
        if item and item.journalRim then item.journalRim:Hide() end
    end
end

local function releaseLocks()
    if MovAny then
        if MovAny.UnlockPoint then MovAny:UnlockPoint(frame) end
        if MovAny.UnlockScale then MovAny:UnlockScale(frame) end
    end
end

function J:Layout()
    if busy or not built or not frame:IsShown() then return end
    busy=true
    releaseLocks()
    frame:SetSize(W,H)
    frame:SetScale(math.min(UIParent:GetWidth()*.82/W, UIParent:GetHeight()*.86/H))
    place(frame,"CENTER",UIParent,"CENTER",0,0)
    -- Keep native coordinate systems intact; uniform page scale preserves text/reward wrapping.
    QuestLogScrollFrame:SetScale(PAGE_SCALE)
    local contentHeight=(PAGE.bottom-PAGE.top)/PAGE_SCALE
    local contentWidth=434/PAGE_SCALE
    QuestLogScrollFrame:SetSize(contentWidth,contentHeight)
    place(QuestLogScrollFrame,"TOPLEFT",frame,"TOPLEFT",92/PAGE_SCALE,-PAGE.top/PAGE_SCALE)
    QuestLogDetailScrollFrame:SetScale(PAGE_SCALE)
    QuestLogDetailScrollFrame:SetSize(contentWidth,contentHeight)
    place(QuestLogDetailScrollFrame,"TOPLEFT",frame,"TOPLEFT",628/PAGE_SCALE,-PAGE.top/PAGE_SCALE)
    QuestLogDetailScrollChildFrame:SetWidth(contentWidth)
    EmptyQuestLogFrame:SetScale(PAGE_SCALE)
    EmptyQuestLogFrame:SetSize(contentWidth,contentHeight)
    place(EmptyQuestLogFrame,"TOPLEFT",frame,"TOPLEFT",92/PAGE_SCALE,-PAGE.top/PAGE_SCALE)
    -- Native scrollbar scripts, mouse-wheel handling and arrow buttons are preserved.
    local leftBar=QuestLogScrollFrame.scrollBar or QuestLogScrollFrameScrollBar
    local function pageScroll(bar, center)
        if not bar then return end
        local ratio=bar:GetEffectiveScale()/frame:GetEffectiveScale()
        local x=center/ratio-bar:GetWidth()/2
        place(bar,"TOPLEFT",frame,"TOPLEFT",x,-(PAGE.top+14)/ratio)
        bar:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",x,-(PAGE.bottom-14)/ratio)
    end
    pageScroll(leftBar,546)
    local rightBar=QuestLogDetailScrollFrameScrollBar
    pageScroll(rightBar,1083)
    QuestLogFrameAbandonButton:SetSize(122,34)
    QuestLogFramePushQuestButton:SetSize(122,34)
    QuestLogFrameTrackButton:SetSize(122,34)
    QuestLogFrameCancelButton:SetSize(112,34)
    QuestLogFrameShowMapButton:SetSize(112,34)
    QuestLogControlPanel:SetParent(frame)
    QuestLogControlPanel:SetSize(386,34)
    place(QuestLogControlPanel,"BOTTOMLEFT",frame,"BOTTOMLEFT",92,74)
    place(QuestLogFrameAbandonButton,"LEFT",QuestLogControlPanel,"LEFT",0,0)
    place(QuestLogFramePushQuestButton,"LEFT",QuestLogFrameAbandonButton,"RIGHT",10,0)
    place(QuestLogFrameTrackButton,"LEFT",QuestLogFramePushQuestButton,"RIGHT",10,0)
    place(QuestLogFrameCancelButton,"BOTTOMRIGHT",frame,"BOTTOMRIGHT",-92,74)
    place(QuestLogFrameShowMapButton,"RIGHT",QuestLogFrameCancelButton,"LEFT",-10,0)
    QuestLogCount:SetParent(frame)
    QuestLogCount:SetSize(434,QuestLogDailyQuestCount:IsShown() and 32 or 16)
    place(QuestLogCount,"BOTTOMLEFT",frame,"BOTTOMLEFT",92,118)
    place(QuestLogQuestCount,"TOPLEFT",QuestLogCount,"TOPLEFT",0,0)
    QuestLogQuestCount:SetJustifyH("LEFT");ink(QuestLogQuestCount,13)
    place(QuestLogDailyQuestCount,"TOPLEFT",QuestLogQuestCount,"BOTTOMLEFT",0,-3)
    QuestLogDailyQuestCount:SetJustifyH("LEFT");ink(QuestLogDailyQuestCount,11)
    for _,text in ipairs({QuestLogQuestCount,QuestLogDailyQuestCount}) do
        local native=text:GetText()
        if native then
            local plain=native:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
            if plain~=native then text:SetText(plain) end
        end
    end
    place(QuestLogFrameCloseButton,"TOPRIGHT",frame,"TOPRIGHT",-60,-54)
    for t in pairs(stockTextures) do t:SetAlpha(0) end
    for _,button in ipairs({QuestLogFrameAbandonButton,QuestLogFramePushQuestButton,QuestLogFrameTrackButton,QuestLogFrameCancelButton,QuestLogFrameShowMapButton}) do
        buttonState(button)
    end
    rows(); rewardSkin()
    for _,bar in ipairs({leftBar,rightBar}) do if bar.journalSync then bar.journalSync() end end
    busy=false
end

local function build()
    if built then return end
    hideTextures(frame); hideTextures(EmptyQuestLogFrame); hideTextures(QuestLogCount)
    hideTextures(QuestLogDetailScrollFrame)
    if QuestLogTitleText then QuestLogTitleText:Hide() end
    frame:SetBackdrop(nil)
    local cover=CreateFrame("Frame",nil,frame)
    cover:SetFrameLevel(frame:GetFrameLevel())
    cover:SetAllPoints(frame)

    -- The journal has its own worn field-book silhouette. A dark offset copy follows the
    -- asset's alpha instead of drawing a rectangular panel behind its irregular edges.
    local bookShadow=texture(cover,"OpenJournalHD.tga","BACKGROUND")
    bookShadow:SetSize(W+30,H+26)
    bookShadow:SetPoint("CENTER",cover,"CENTER",0,-3)
    bookShadow:SetVertexColor(.055,.032,.018,1)
    bookShadow:SetAlpha(.18)

    -- Purpose-built two-page art: the paper fold and stitching meet at the actual center.
    -- Render the accepted book intact, with no independent page/spine reshaping.
    local journal=texture(cover,"OpenJournalHD.tga","BORDER")
    journal:SetTexCoord(0,1,0,1)
    journal:SetSize(W+24,H+20)
    journal:SetPoint("CENTER",cover,"CENTER",0,0)
    journal:SetAlpha(0.98)
    J.book=journal
    J.cover=cover
    J.leftHeading=heading(cover,QUEST_LOG or "Quest Log",PAGE.left)
    J.rightHeading=heading(cover,QUEST_DETAILS or "Quest Details",PAGE.right)
    skinButton(QuestLogFrameAbandonButton,120)
    skinButton(QuestLogFramePushQuestButton,110)
    skinButton(QuestLogFrameTrackButton,120)
    skinButton(QuestLogFrameCancelButton,104)
    skinButton(QuestLogFrameShowMapButton,104)
    QuestLogFrameShowMapButton.text:Hide()
    local mapLabel=QuestLogFrameShowMapButton:CreateFontString(nil,"OVERLAY")
    mapLabel:SetFont("Fonts\\FRIZQT__.TTF",14,"")
    mapLabel:SetTextColor(.95,.86,.65);mapLabel:SetShadowOffset(1,-1)
    mapLabel:SetPoint("CENTER",QuestLogFrameShowMapButton,"CENTER")
    mapLabel:SetText(MAP or "Map")
    QuestLogFrameShowMapButton.journalLabel=mapLabel
    buttonState(QuestLogFrameShowMapButton)
    skinScrollBar(QuestLogScrollFrame.scrollBar or QuestLogScrollFrameScrollBar,QuestLogScrollFrame)
    skinScrollBar(QuestLogDetailScrollFrameScrollBar,QuestLogDetailScrollFrame)
    ink(QuestLogQuestCount,12);ink(QuestLogDailyQuestCount,11)
    ink(QuestLogNoQuestsText,14)
    local close=QuestLogFrameCloseButton
    close:SetSize(26,26)
    close:SetFrameLevel(frame:GetFrameLevel()+25)
    -- Crop the supplied atlas rather than its padded stock close-button textures.
    close:SetNormalTexture(ART.."chrome-buttons")
    close:SetPushedTexture(ART.."chrome-buttons")
    close:SetHighlightTexture(ART.."chrome-buttons")
    for _,t in ipairs({close:GetNormalTexture(),close:GetPushedTexture(),close:GetHighlightTexture()}) do
        t:SetTexCoord(315/512,374/512,80/512,138/512)
        t:SetAllPoints(close)
    end
    close:GetHighlightTexture():SetBlendMode("ADD");close:GetHighlightTexture():SetAlpha(.25)
    built=true
end

local function refresh() J:Layout() end
local function initialize()
    build()
    -- Centered UIPanel ownership keeps stock bindings, Escape and other panel transitions intact.
    if UIPanelWindows and UIPanelWindows.QuestLogFrame then
        UIPanelWindows.QuestLogFrame.area="center"
        UIPanelWindows.QuestLogFrame.width=W
    end
    frame:SetAttribute("UIPanelLayout-area","center")
    frame:SetAttribute("UIPanelLayout-width",W)
    hooksecurefunc("QuestLogDetailFrame_AttachToQuestLog",refresh)
    hooksecurefunc("QuestLogDetailFrame_DetachFromQuestLog",function()
        if frame:IsShown() then return end
        QuestLogDetailScrollFrame:SetScale(1)
        QuestLogDetailScrollFrame:SetSize(298,334)
        QuestLogDetailScrollChildFrame:SetWidth(298)
        local bar=QuestLogDetailScrollFrameScrollBar
        place(bar,"TOPLEFT",QuestLogDetailScrollFrame,"TOPRIGHT",6,-16)
        bar:SetPoint("BOTTOMLEFT",QuestLogDetailScrollFrame,"BOTTOMRIGHT",6,14)
        QuestLogFrameAbandonButton:SetSize(110,21)
        QuestLogFramePushQuestButton:SetSize(69,21)
        QuestLogFrameTrackButton:SetSize(100,21)
        place(QuestLogFrameAbandonButton,"LEFT",QuestLogControlPanel,"LEFT",0,1)
        place(QuestLogFrameTrackButton,"RIGHT",QuestLogControlPanel,"RIGHT",-3,1)
        place(QuestLogFramePushQuestButton,"LEFT",QuestLogFrameAbandonButton,"RIGHT",4,0)
    end)
    hooksecurefunc("QuestLogControlPanel_UpdatePosition",refresh)
    hooksecurefunc("QuestLogShowMapPOI_UpdatePosition",function()
        if frame:IsShown() then refresh()
        elseif QuestLogDetailFrame:IsShown() then
            -- Native code adds TOPRIGHT without clearing the journal footer's
            -- BOTTOMRIGHT anchor; restore a single stock anchor for standalone.
            place(QuestLogFrameShowMapButton,"TOPRIGHT",QuestLogDetailFrame,"TOPRIGHT",-25,-38)
        end
    end)
    hooksecurefunc("QuestLog_UpdateQuestCount",refresh)
    hooksecurefunc("QuestLog_Update",rows)
    hooksecurefunc("QuestLog_SetSelection",rows)
    hooksecurefunc("QuestLog_UpdateQuestDetails",rewardSkin)
    hooksecurefunc("QuestInfo_Display",function(template)
        if template and not template.questLog then restoreRewards() end
    end)
    frame:HookScript("OnShow",refresh)
    frame:HookScript("OnHide",restoreRewards)
    -- Other panel managers can reposition frames after OnShow; re-center only on actual changes.
    hooksecurefunc(frame,"SetPoint",function()
        if not busy and frame:IsShown() then J:Layout() end
    end)
    J:Layout()
end

local driver=CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("DISPLAY_SIZE_CHANGED")
driver:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then initialize() else J:Layout() end
end)
