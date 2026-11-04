-- New generated Bagster artwork. Native backdrop tiling preserves material scale
-- and native corner/edge joins while the inventory is resized.
local addon=select(2,...)
local mod=addon.BagsterModule
mod.LegacyBagsterAddNineSlice=mod.BagsterAddNineSlice
local P=addon._dir.."BagsterLeatherBronze\\"
local C="Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\"
mod.ArtPath=P
local function tex(owner,layer,path)
    local t=owner:CreateTexture(nil,layer);t:SetTexture(path);return t
end
local function plate(owner,edge)
    owner:SetBackdrop({bgFile=P.."LeatherTile",edgeFile=P.."FrameBorder",tile=true,tileSize=256,
        edgeSize=edge or 10,insets={left=3,right=3,top=3,bottom=3}})
    owner:SetBackdropColor(1,1,1,1);owner:SetBackdropBorderColor(1,1,1,1)
end
-- Tab/search endcaps stay square; center material is cropped and repeated.
function mod.RefreshTab(owner)
    local c=owner._newBagsterTab;if not c then return end
    if c.flap then return end
    local h,w=owner:GetHeight(),owner:GetWidth();local cap=h;local mid=math.max(0,w-cap*2+8);local pitch=h*8
    for _,pair in ipairs({{c.left,"TOPLEFT"},{c.right,"TOPRIGHT"}})do
        local t=pair[1];t:ClearAllPoints();t:SetPoint(pair[2],owner,pair[2]);t:SetSize(cap,h)
    end
    local n=math.ceil(mid/pitch)
    for i=1,n do
        local width=math.min(pitch,mid-(i-1)*pitch)
        local t=c.middle[i]
        if not t then t=tex(owner,"BACKGROUND",P.."HeaderTile");c.middle[i]=t end
        t:ClearAllPoints();t:SetPoint("TOPLEFT",owner,"TOPLEFT",cap-4+(i-1)*pitch,0);t:SetSize(width,h)
        t:SetTexCoord(0,width/pitch,0,1);t:Show()
    end
    for i=n+1,#c.middle do c.middle[i]:Hide()end
end
function mod.StylePlate(owner,active)
    if owner._BagsterFlap then
        if not owner._newBagsterTab then
            local base=tex(owner,"BACKGROUND",P.."FlapTab");base:SetAllPoints(owner);base:SetTexCoord(0,1,8/34,1)
            local hl=tex(owner,"HIGHLIGHT",P.."FlapTab");hl:SetAllPoints(owner);hl:SetTexCoord(0,1,8/34,1);hl:SetBlendMode("ADD");hl:SetAlpha(.14)
            owner._newBagsterTab={flap=true,base=base,highlight=hl}
        end
        return
    end
    if not owner._newBagsterTab then
        local c={middle={}};owner._newBagsterTab=c
        c.left=tex(owner,"ARTWORK",P.."HeaderCaps");c.left:SetTexCoord(0,.5,0,1)
        c.right=tex(owner,"ARTWORK",P.."HeaderCaps");c.right:SetTexCoord(.5,1,0,1)
        owner:HookScript("OnSizeChanged",mod.RefreshTab)
    end
    mod.RefreshTab(owner)
end
function mod.SyncChromeLayers(frame)
    local c=frame._BagSkin_NineSlice;if not c then return end
    local level=frame:GetFrameLevel()
    c.background:SetFrameLevel(math.max(0,level-1));c.banner:SetFrameLevel(level+1)
    c.border:SetFrameLevel(level+8)
    for _,suffix in ipairs({"Title","IconButton","CloseButton"})do
        local f=_G[frame:GetName()..suffix];if f then f:SetFrameLevel(level+10)end
    end
    if frame.sideFilter then
        frame.sideFilter:SetFrameLevel(level)
        for _,tab in pairs(frame.sideFilter.buttons or {})do tab:SetFrameLevel(level+1)end
    end
end
local function framePiece(c,index,owner,x,y,w,h,sx,sy,sw,sh)
    local t=c.pieces[index]
    if not t then t=tex(c.border,"ARTWORK",P.."InventoryFrameRect");t:SetBlendMode("BLEND");t:SetDrawLayer(index<=4 and "OVERLAY"or"BORDER");c.pieces[index]=t end
    t:ClearAllPoints();t:SetPoint("TOPLEFT",owner,"TOPLEFT",x,-y);t:SetSize(w,h)
    t:SetTexCoord(sx/1024,(sx+sw)/1024,sy/2048,(sy+sh)/2048);t:Show()
end
function mod.RefreshChrome(frame)
    local c=frame._BagSkin_NineSlice;if not c then return end
    mod.SyncChromeLayers(frame)
    local width,height=frame:GetWidth(),frame:GetHeight()
    if c.width==width and c.height==height then return end;c.width=width;c.height=height
    -- One large rectangular leather image, uniformly scaled and cropped to the panel.
    -- Source X and Y always use the same scale; no repeated texture joins or distortion.
    local tw,th=math.max(1,width-24),math.max(1,height-24)
    local t=c.body[1];if not t then t=tex(c.background,"BACKGROUND",P.."InventoryBodyRect");c.body[1]=t end
    local scale=math.max(tw/768,th/1280);local sw,sh=tw/scale,th/scale
    t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-12);t:SetSize(tw,th)
    t:SetTexCoord((768-sw)/2/1024,(768+sw)/2/1024,(1280-sh)/2/2048,(1280+sh)/2/2048);t:Show()
    for i=2,#c.body do c.body[i]:Hide()end
    -- Fixed guards; rails repeat at the identical uniform .4 scale as the corners.
    local k,src,fw,fh=38.4,96,960,1475;local index=0
    local function put(x,y,w,h,sx,sy,sw,sh)index=index+1;framePiece(c,index,frame,x,y,w,h,sx,sy,sw,sh)end
    put(0,0,k,k,0,0,src,src);put(width-k,0,k,k,fw-src,0,src,src)
    put(0,height-k,k,k,0,fh-src,src,src);put(width-k,height-k,k,k,fw-src,fh-src,src,src)
    local pitch=256*.4
    for j=0,math.ceil(math.max(0,width-k*2+12.8)/pitch)-1 do
        local w=math.min(pitch,width-k*2+12.8-j*pitch)
        put(k-6.4+j*pitch,0,w,k,4,1540,w/.4,src);put(k-6.4+j*pitch,height-k,w,k,272,1540,w/.4,src)
    end
    for j=0,math.ceil(math.max(0,height-k*2+12.8)/pitch)-1 do
        local h=math.min(pitch,height-k*2+12.8-j*pitch)
        put(0,k-6.4+j*pitch,k,h,540,1540,src,h/.4);put(width-k,k-6.4+j*pitch,k,h,644,1540,src,h/.4)
    end
    for j=index+1,#c.pieces do c.pieces[j]:Hide()end
    local h=30;local length=math.max(1,width-48);local cap=h;local pitch=h*8
    local middle=math.max(0,length-cap*2+8);local count=math.ceil(middle/pitch)
    for j=1,count do
        local t=c.header[j]
        if not t then t=tex(c.banner,"BACKGROUND",P.."HeaderTile");c.header[j]=t end
        local w=math.min(pitch,middle-(j-1)*pitch)
        t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",24+cap-4+(j-1)*pitch,-22)
        t:SetSize(w,h);t:SetTexCoord(0,w/pitch,0,1);t:Show()
    end
    for j=count+1,#c.header do c.header[j]:Hide()end
    for _,spec in ipairs({{c.left,"TOPLEFT",24,0,.5},{c.right,"TOPRIGHT",-24,.5,1}})do
        local t=spec[1];t:ClearAllPoints();t:SetPoint(spec[2],frame,spec[2],spec[3],-22);t:SetSize(cap,h);t:SetTexCoord(spec[4],spec[5],0,1)
    end
end
function mod.BagsterAddNineSlice(frame)
    if frame._BagSkin_NineSlice then return end
    frame:SetBackdrop(nil)
    local c={header={},body={},pieces={}};frame._BagSkin_NineSlice=c
    c.border=CreateFrame("Frame",nil,frame);c.border:SetAllPoints(frame)
    c.background=CreateFrame("Frame",nil,frame);c.background:SetFrameLevel(frame:GetFrameLevel()-1)
    c.background:SetAllPoints(frame)
    c.banner=CreateFrame("Frame",nil,frame);c.banner:SetFrameLevel(frame:GetFrameLevel())
    c.left=tex(c.banner,"ARTWORK",P.."HeaderCaps");c.right=tex(c.banner,"ARTWORK",P.."HeaderCaps")
    mod.RefreshChrome(frame)
    frame:HookScript("OnShow",mod.SyncChromeLayers)
    frame:HookScript("OnSizeChanged",function(self)
        mod.RefreshChrome(self)
        if self.title then self.title:SetWidth(math.max(1,self:GetWidth()-100))end
    end)
end
function mod.SetupInventoryBadge(btn,frame)
    local old=_G[frame:GetName().."Icon"];if old then old:Hide()end
    btn:SetSize(72,72);btn:SetPoint("TOPLEFT",frame,"TOPLEFT",-10,12)
    btn.icon=tex(btn,"OVERLAY",P.."InventoryBadgeSmooth");btn.icon:SetAllPoints(btn);btn.icon:SetBlendMode("BLEND")
    btn._BagsterDecorative=true;btn:EnableMouse(false)
end
function mod.StyleRingButton(button,icon)
    local rim=tex(button,"OVERLAY",P.."BagRingSmooth");rim:SetBlendMode("BLEND");rim:SetSize(36,36);rim:SetPoint("CENTER",button,"CENTER",0,0)
    -- The native icon's baked square frame must extend under the opaque bronze band.
    -- A smaller portrait exposes that frame inside the ring's transparent opening.
    if icon then icon:ClearAllPoints();icon:SetPoint("CENTER",button,"CENTER",0,0);icon:SetSize(34,34);icon:SetBlendMode("BLEND");button._ringIcon=icon;button._ringPath=icon:GetTexture();mod.MaskRingIcon(button)end
    local hl=tex(button,"HIGHLIGHT",P.."BagRingSmooth");hl:SetSize(36,36);hl:SetPoint("CENTER",button,"CENTER",0,0)
    hl:SetBlendMode("ADD");hl:SetAlpha(.2);button:SetHighlightTexture(hl)
end
function mod.MaskRingIcon(button)
    local icon,path=button._ringIcon,button._ringPath
    if icon and path and path~=""then
        SetPortraitToTexture(icon,path)
        -- Cropping a completed circular portrait clips its alpha silhouette into flat edges.
        icon:SetTexCoord(0,1,0,1);icon:SetBlendMode("BLEND")
    end
end
function mod.SetRingTexture(button,path)
    SetItemButtonTexture(button,path);button._ringPath=path
    mod.MaskRingIcon(button)
end
-- Header controls share the computed grid bounds; sort integration must not reanchor the bag column.
function mod.LayoutControls(frame)
    local name=frame:GetName();local g=frame._BagsterGrid
    if name=="DragonUI_BagsterFrame3"then return end
    local left=24+(g and g.positions[1]and g.positions[1].x or 0)
    local right=math.min(g and left+g.columns*g.icon+(g.columns-1)*g.gap or frame:GetWidth()-76,frame:GetWidth()-76)
    local bag=_G[name.."BagToggle"]
    if bag then
        bag:ClearAllPoints();bag:SetPoint("CENTER",frame,"TOPLEFT",frame:GetWidth()-52,-74)
    end
    local u=frame._BagsterUtilities
    if u then
        u.sort:ClearAllPoints();u.sort:SetPoint("RIGHT",frame,"TOPLEFT",right,-74)
        u.clear:ClearAllPoints();u.clear:SetPoint("RIGHT",u.sort,"LEFT",-4,0)
        if u.sell then u.sell:ClearAllPoints();u.sell:SetPoint("RIGHT",u.clear,"LEFT",-4,0)end
    end
    local search=_G[name.."Search"]
    if search then
        local controls=u and(u.sell and 74 or 48)or 0
        search:ClearAllPoints();search:SetPoint("TOPLEFT",frame,"TOPLEFT",left,-62)
        search:SetWidth(math.max(80,math.min(200,right-left-controls-12)))
    end
end
function mod.BagsterRetailItemSlot(button)
    if button._BagSkin_Applied then return end;button._BagSkin_Applied=true
    local n=button:GetNormalTexture()
    if n then n:SetTexture(P.."SlotWell");n:ClearAllPoints();n:SetAllPoints(button);n:SetDrawLayer("BACKGROUND");n:SetAlpha(1);n:Show()end
    local rim=button._dragonuiSlotBorder or tex(button,"ARTWORK",P.."SlotRim")
    button._dragonuiSlotBorder=rim;rim:SetTexture(P.."SlotRim");rim:ClearAllPoints();rim:SetAllPoints(button);rim:Show()
    if button.border then
        addon.StyleItemQualityGlow(button,button.border,nil)
    end
    local highlight=button:GetHighlightTexture()
    if highlight then highlight:SetTexture(P.."SlotRim");highlight:ClearAllPoints();highlight:SetAllPoints(button);highlight:SetBlendMode("ADD")end
    local name=button:GetName()
    local icon=name and _G[name.."IconTexture"]
    if icon then icon:SetDrawLayer("BORDER");icon:SetTexCoord(0,1,0,1);icon:ClearAllPoints();icon:SetAllPoints(button)end
    for _,suffix in ipairs({"Count","Stock"})do local f=name and _G[name..suffix];if f then f:SetDrawLayer("OVERLAY")end end
    if button.UpdateBorder then button:UpdateBorder()end
end
function mod.StyleUtility(button)
    if not button then return end
    if button.border then button.border:SetTexture(P.."SlotRim");button.border:SetTexCoord(0,1,0,1);button.border:ClearAllPoints();button.border:SetAllPoints(button)end
    if button.icon then button.icon:ClearAllPoints();button.icon:SetPoint("CENTER",button,"CENTER",0,0);button.icon:SetSize(button:GetWidth()-4,button:GetHeight()-4)end
end
function mod.StyleFrame(frame)
    if not frame or frame._BagSkin_Bagster then return end;frame._BagSkin_Bagster=true
    mod.BagsterAddNineSlice(frame)
    mod.SyncChromeLayers(frame)
    local name=frame:GetName();local badge=_G[name.."IconButton"]
    if badge and badge._BagsterDecorative then badge:EnableMouse(false);badge:SetScript("OnClick",nil);badge:SetScript("OnMouseDown",nil);badge:SetScript("OnMouseUp",nil)end
    local close=_G[name.."CloseButton"]
    if close then
        close:ClearAllPoints();close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-4,-4);close:SetSize(22,22)
        for _,m in ipairs({"Normal","Pushed","Disabled","Highlight"})do
            local t=close["Get"..m.."Texture"](close)
            if t then t:SetTexture(P.."Close");t:SetTexCoord(0,1,0,1);t:ClearAllPoints();t:SetPoint("CENTER",close,"CENTER",0,0);t:SetSize(20,20)end
        end
    end
    local title=_G[name.."Title"]
    if title then title:ClearAllPoints();title:SetPoint("TOP",frame,"TOP",0,-28);title:SetWidth(frame:GetWidth()-100);title:SetHeight(18)end
    local search=_G[name.."Search"];if search then search:SetBackdrop(nil);mod.StylePlate(search,false)end
end
-- Same leather track, thumb and fixed ridges as the character screen.
local function verticalStrip(owner,path,layer)
    local out={}
    for i=1,3 do
        local t=tex(owner,layer,C..path);out[i]=t
        t:SetTexCoord(0,1,i==1 and 0 or(i==2 and .12 or .88),i==1 and .12 or(i==2 and .88 or 1))
        if i==1 then t:SetPoint("TOPLEFT",owner,"TOPLEFT");t:SetPoint("TOPRIGHT",owner,"TOPRIGHT");t:SetHeight(7)
        elseif i==3 then t:SetPoint("BOTTOMLEFT",owner,"BOTTOMLEFT");t:SetPoint("BOTTOMRIGHT",owner,"BOTTOMRIGHT");t:SetHeight(7)
        else t:SetPoint("TOPLEFT",owner,"TOPLEFT",0,-7);t:SetPoint("BOTTOMRIGHT",owner,"BOTTOMRIGHT",0,7)end
    end
    return out
end
function mod.CreateItemViewport(owner)
    local v=CreateFrame("ScrollFrame",owner:GetName().."ItemsViewport",owner)
    v:SetPoint("TOPLEFT",owner,"TOPLEFT",24,-96);v:EnableMouseWheel(true)
    local b=CreateFrame("Slider",owner:GetName().."ItemsScrollBar",owner)
    b:SetOrientation("VERTICAL");b:SetWidth(14);b:SetMinMaxValues(0,0);b:SetValueStep(1)
    b:SetPoint("TOPLEFT",v,"TOPRIGHT",5,-17);b:SetPoint("BOTTOMLEFT",v,"BOTTOMRIGHT",5,17)
    b:SetFrameLevel(v:GetFrameLevel()+4)
    local thumb=tex(b,"ARTWORK",C.."ScrollThumbHD");thumb:SetSize(14,36);thumb:SetAlpha(0);b:SetThumbTexture(thumb);b.thumb=thumb
    verticalStrip(b,"ScrollTrackHD","BACKGROUND")
    local grip=CreateFrame("Frame",nil,b);grip:SetPoint("TOP",thumb,"TOP");grip:SetPoint("BOTTOM",thumb,"BOTTOM");grip:SetWidth(14)
    local art=verticalStrip(grip,"ScrollThumbHD","ARTWORK");art[2]:SetTexCoord(0,1,.22,.3)
    local ridge=tex(grip,"OVERLAY",C.."ScrollThumbHD");ridge:SetTexCoord(0,1,.4,.6);ridge:SetPoint("CENTER",grip,"CENTER");ridge:SetSize(14,20)
    local function move(delta)b:SetValue(math.max(0,math.min(b.range or 0,b:GetValue()+delta)))end
    v:SetScript("OnMouseWheel",function(_,delta)move(-delta*(owner.itemFrame and owner.itemFrame.rowStep or 40)*3)end)
    b:SetScript("OnValueChanged",function(_,value)v:SetVerticalScroll(value)end)
    for _,spec in ipairs({{"TOP",1,"^"},{"BOTTOM",-1,"v"}})do
        local arrow=CreateFrame("Button",nil,owner);arrow:SetSize(14,16)
        arrow:SetPoint(spec[1],b,spec[1],0,spec[2]*17);plate(arrow,5)
        arrow:SetNormalFontObject(GameFontNormalSmall);arrow:SetText(spec[3])
        local step=spec[2]==1 and -1 or 1
        arrow:SetScript("OnClick",function()move(step*(owner.itemFrame and owner.itemFrame.rowStep or 40))end)
        if spec[1]=="TOP"then b.up=arrow else b.down=arrow end
    end
    owner.itemViewport=v;owner.itemScrollBar=b
    return v
end
function mod.UpdateScroll(owner,overflow)
    local b,v=owner.itemScrollBar,owner.itemViewport;if not b or not v then return end
    b.range=math.max(0,overflow);b:SetMinMaxValues(0,b.range)
    local height=v:GetHeight();local track=math.max(20,height-34)
    b.thumb:SetHeight(math.max(20,math.min(track-12,track*height/math.max(1,height+b.range))))
    b:SetValue(math.min(b:GetValue(),b.range));v:SetVerticalScroll(b:GetValue())
    if b.range>.01 then b:Show();b.up:Show();b.down:Show()else b:Hide();b.up:Hide();b.down:Hide()end
end
function mod.ScrollToTop(owner)
    if owner.itemScrollBar then owner.itemScrollBar:SetValue(0)end
    if owner.itemViewport then owner.itemViewport:SetVerticalScroll(0)end
end
