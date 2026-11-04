-- Merchant-only artwork and layout. Native controls and transaction handlers remain authoritative.
local addon=select(2,...)
local S={};addon.MerchantStyle=S
S.ART=addon._dir.."MerchantWoodBronze\\"
local I=addon.MerchantArtInfo
local function place(o,p,r,rp,x,y)o:ClearAllPoints();o:SetPoint(p,r,rp,x or 0,y or 0)end
local function tex(o,key,layer)
    local t=o:CreateTexture(nil,layer or "BACKGROUND");t:SetTexture(S.ART..key);t:SetBlendMode("BLEND");return t
end
function S.Geometry(buying)
    return {windowWidth=768,windowHeight=436,left=42,column=buying and 336 or 352,width=buying and 316 or 332,top=116,
        rows=buying and 4 or 6,rowHeight=buying and 44 or 32,stride=buying and 52 or 35,icon=buying and 40 or 32,
        gutter=710,gutterHeight=200,trackHeight=164}
end
local function image(t,key,o,w,h)
    local d=I[key];local scale=math.min(w/d.cw,h/d.ch)
    place(t,"CENTER",o,"CENTER");t:SetSize(d.cw*scale,d.ch*scale)
    t:SetTexCoord(0,d.cw/d.w,0,d.ch/d.h)
end
local function hideTextures(o)
    for _,r in ipairs({o:GetRegions()})do if r:GetObjectType()=="Texture"then r:Hide()end end
end
local function strip(o,height)
    local c=o._merchantStrip
    if not c then
        c={center={}};o._merchantStrip=c
        c.left=tex(o,"ButtonCaps","ARTWORK");c.right=tex(o,"ButtonCaps","ARTWORK")
    end
    local w,h=o:GetWidth(),height or o:GetHeight();local cap=h/2;local pitch=h*4
    for _,v in ipairs({{c.left,"TOPLEFT",0,.5},{c.right,"TOPRIGHT",.5,1}})do
        local t=v[1];place(t,v[2],o,v[2]);t:SetSize(cap,h);t:SetTexCoord(v[3],v[4],0,1)
    end
    local middle=math.max(0,w-2*cap+2)
    local n=math.ceil(middle/pitch)
    for j=1,n do
        local t=c.center[j];if not t then t=tex(o,"ButtonCenter");c.center[j]=t end
        local width=math.min(pitch,middle-(j-1)*pitch)
        place(t,"TOPLEFT",o,"TOPLEFT",cap-1+(j-1)*pitch,0);t:SetSize(width,h);t:SetTexCoord(0,width/pitch,0,1);t:Show()
    end
    for j=n+1,#c.center do c.center[j]:Hide()end
end
function S.Button(button,selected)
    if not button then return end
    if not button._merchantStrip then
        hideTextures(button);if button.SetBackdrop then button:SetBackdrop(nil)end
        button:HookScript("OnSizeChanged",function(self)strip(self)end)
        button:HookScript("OnEnter",function(self)for _,t in ipairs(self._merchantStrip.center)do t:SetVertexColor(1,.97,.88)end end)
        button:HookScript("OnLeave",function(self)for _,t in ipairs(self._merchantStrip.center)do t:SetVertexColor(1,1,1)end end)
    end
    strip(button)
    local label=button.GetFontString and button:GetFontString()or(button:GetName()and _G[button:GetName().."Text"])
    if label then label:SetTextColor(selected and 1 or .94,selected and .83 or .88,selected and .48 or .74);label:SetShadowColor(0,0,0,.85);label:SetShadowOffset(1,-1)end
end
local function fitDropdown(menu)
    if menu.merchantFitting then return end;menu.merchantFitting=true
    local width=menu.merchantWidth
    if math.abs(menu:GetWidth()-width)>.01 or math.abs(menu:GetHeight()-24)>.01 then menu:SetSize(width,24)end
    local face=menu.merchantFace;face:SetSize(width,24);strip(face)
    local name=menu:GetName();local label=_G[name.."Text"]
    if label then
        place(label,"LEFT",face,"LEFT",10,0);label:SetPoint("RIGHT",face,"RIGHT",-24,0)
        label:SetJustifyH("LEFT");label:SetFont("Fonts\\FRIZQT__.TTF",11,"");label:SetTextColor(.94,.88,.74);label:SetShadowColor(0,0,0,.85);label:SetShadowOffset(1,-1)
    end
    hideTextures(menu)
    local button=_G[name.."Button"]
    if button then
        button:ClearAllPoints();button:SetAllPoints(face)
        for _,r in ipairs({button:GetRegions()})do if r:GetObjectType()=="Texture"and r~=button.merchantArrow then r:SetAlpha(0)end end
    end
    menu.merchantFitting=false
end
function S.Dropdown(menu,width)
    S.InstallPopups()
    menu.merchantWidth=width;menu:SetScale(1)
    if not menu.merchantFace then
        local face=CreateFrame("Frame",nil,menu);face:EnableMouse(false);face:SetFrameLevel(menu:GetFrameLevel());place(face,"TOPLEFT",menu,"TOPLEFT");face:SetSize(width,24)
        S.Button(face);menu.merchantFace=face
        menu:HookScript("OnSizeChanged",function()fitDropdown(menu)end);menu:HookScript("OnShow",function()fitDropdown(menu)end)
        local b=_G[menu:GetName().."Button"]
        if b then
            b:HookScript("OnClick",function()fitDropdown(menu)end);b:HookScript("OnLeave",function()fitDropdown(menu)end)
            local arrow=tex(b,"ArrowDown","OVERLAY");place(arrow,"RIGHT",face,"RIGHT",-5,0);arrow:SetSize(14,14);b.merchantArrow=arrow
        end
    end
    fitDropdown(menu)
end
-- Shared native dropdown lists are styled only while a merchant menu owns them.
-- Every patch uses .5 UI pixels per source pixel, including partial edge tiles.
function S.Popup(frame)
    local p=frame._merchantPopup
    if not p then
        p=CreateFrame("Frame",nil,frame);p:EnableMouse(false);p:SetFrameLevel(frame:GetFrameLevel());p:SetAllPoints(frame);p.tiles={};frame._merchantPopup=p
    end
    local d=I.PopupFrame;local w,h=frame:GetWidth(),frame:GetHeight();local n=0
    local function put(x,y,ww,hh,sx,sy)
        n=n+1;local t=p.tiles[n];if not t then t=tex(p,"PopupFrame");p.tiles[n]=t end
        place(t,"TOPLEFT",p,"TOPLEFT",x,-y);t:SetSize(ww,hh)
        t:SetTexCoord(sx/d.w,(sx+ww*2)/d.w,sy/d.h,(sy+hh*2)/d.h);t:Show()
    end
    local c=10
    put(0,0,c,c,0,0);put(w-c,0,c,c,d.cw-20,0)
    put(0,h-c,c,c,0,d.ch-20);put(w-c,h-c,c,c,d.cw-20,d.ch-20)
    for x=c,w-c-.01,128 do
        local ww=math.min(128,w-c-x);put(x,0,ww,c,64,0);put(x,h-c,ww,c,64,d.ch-20)
    end
    for y=c,h-c-.01,128 do
        local hh=math.min(128,h-c-y);put(0,y,c,hh,0,40);put(w-c,y,c,hh,d.cw-20,40)
        for x=c,w-c-.01,128 do put(x,y,math.min(128,w-c-x),hh,64,40)end
    end
    for i=n+1,#p.tiles do p.tiles[i]:Hide()end;p:Show()
end
function S.InstallPopups()
    if S.popupHooks then return end;S.popupHooks=true
    hooksecurefunc("ToggleDropDownMenu",function()
        local root=UIDROPDOWNMENU_OPEN_MENU
        local merchant=root and(root==_G.DragonUIMerchantFilterMenu or root==_G.DragonUIMerchantSortMenu or root=="DragonUIMerchantFilterMenu"or root=="DragonUIMerchantSortMenu")
        for i=1,3 do
            local f=_G["DropDownList"..i]
            if f then
                f._merchantOriginalAlpha=f._merchantOriginalAlpha or {}
                for _,suffix in ipairs({"Backdrop","MenuBackdrop"})do
                    local b=_G[f:GetName()..suffix]
                    if b then
                        if merchant then
                            if f._merchantOriginalAlpha[b]==nil then f._merchantOriginalAlpha[b]=b:GetAlpha()end
                            b:SetAlpha(0)
                        elseif f._merchantOriginalAlpha[b]~=nil then b:SetAlpha(f._merchantOriginalAlpha[b]);f._merchantOriginalAlpha[b]=nil end
                    end
                end
                if merchant and f:IsShown()then S.Popup(f)
                elseif f._merchantPopup then f._merchantPopup:Hide()end
            end
        end
    end)
end
function S.Frame(host,target)
    local f=CreateFrame("Frame",nil,host);f:SetAllPoints(target);f:EnableMouse(false);f:SetFrameLevel(host:GetFrameLevel()+1)
    local t=tex(f,"SlotRim","OVERLAY");t:SetAllPoints(f);return f
end
function S.Row(index,g)
    local prefix="MerchantItem"..index;local row=_G[prefix];if not row then return end
    row:SetSize(g.width,g.rowHeight)
    local button=_G[prefix.."ItemButton"]
    if button then
        button:SetSize(g.icon,g.icon);place(button,"TOPLEFT",row,"TOPLEFT",0,-(g.rowHeight-g.icon)/2)
        local icon=_G[prefix.."ItemButtonIconTexture"]
        if icon then icon:ClearAllPoints();icon:SetAllPoints(button);icon:SetTexCoord(0,1,0,1);icon:SetDrawLayer("BORDER")end
        local n=button:GetNormalTexture()
        if n then n:SetTexture(S.ART.."SlotWell");n:SetTexCoord(0,1,0,1);n:ClearAllPoints();n:SetAllPoints(button);n:SetDrawLayer("BACKGROUND")end
        if not button._merchantRim then button._merchantRim=tex(button,"SlotRim","ARTWORK");button._merchantRim:SetAllPoints(button)end
        for _,suffix in ipairs({"Count","Stock"})do local fs=_G[prefix.."ItemButton"..suffix];if fs then fs:SetDrawLayer("OVERLAY")end end
    end
    local slot=_G[prefix.."SlotTexture"];if slot then slot:Hide()end
    local pane=_G[prefix.."NameFrame"]
    if pane then
        local sourceHeight=g.rowHeight*512/(g.width-46)
        pane:SetTexture(S.ART.."RowWell");pane:SetTexCoord(0,1,(128-sourceHeight)/256,(128+sourceHeight)/256);place(pane,"TOPLEFT",row,"TOPLEFT",46,0);pane:SetSize(g.width-46,g.rowHeight);pane:Show()
    end
    local label=_G[prefix.."Name"]
    if label then place(label,"TOPLEFT",row,"TOPLEFT",52,g.rowHeight==32 and -1 or -4);label:SetSize(g.width-60,g.rowHeight==32 and 14 or 16);label:SetFont("Fonts\\FRIZQT__.TTF",12,"");label:SetShadowColor(0,0,0,.9);label:SetShadowOffset(1,-1)end
    local money=_G[prefix.."MoneyFrame"];if money then place(money,"TOPLEFT",row,"TOPLEFT",52,g.rowHeight==32 and -18 or -24)end
    local currency=_G[prefix.."AltCurrencyFrame"]
    if currency and currency:IsShown()then
        if money and money:IsShown()then place(currency,"LEFT",money,"RIGHT",-14,0)
        else place(currency,"BOTTOMLEFT",pane,"BOTTOMLEFT",6,4)end
    end
end
function S.Money(money,size)
    if not money or not money:GetName()then return end
    for _,coin in ipairs({"Gold","Silver","Copper"})do
        local b=_G[money:GetName()..coin.."Button"];local n=b and b:GetNormalTexture()
        if n then n:SetTexture(S.ART.."Coin"..coin.."Smooth");n:SetTexCoord(0,1,0,1);n:SetBlendMode("BLEND");place(n,"RIGHT",b,"RIGHT");n:SetSize(size,size)end
    end
end
function S.Leather(header)end -- Old standalone header is no longer rendered.
function S.ServiceIcon(icon,key,button)
    if not icon then return end
    icon:SetTexture(S.ART..key);icon:SetTexCoord(0,1,0,1);icon:SetBlendMode("BLEND")
    icon:ClearAllPoints();icon:SetPoint("CENTER",button,"CENTER");icon:SetSize(24,24)
end
local function vertical(owner,key,width,height,bodyKey)
    local list=owner._merchantVertical or {};owner._merchantVertical=list
    local d=I[key];local cap=width/2;local mid=math.max(0,height-2*cap);local pitch=width*2
    local index=0
    local function put(y,h,sy,sh,path,uv)
        index=index+1;local t=list[index]
        if not t then t=tex(owner,path or key,"ARTWORK");list[index]=t end
        t:SetTexture(S.ART..(path or key));place(t,"TOPLEFT",owner,"TOPLEFT",0,-y);t:SetSize(width,h)
        if uv then t:SetTexCoord(0,1,uv[1],uv[2])else t:SetTexCoord(0,d.cw/d.w,sy/d.h,(sy+sh)/d.h)end;t:Show()
    end
    put(0,cap,0,d.cw/2);put(height-cap,cap,d.ch-d.cw/2,d.cw/2)
    for n=0,math.ceil(mid/pitch)-1 do
        local h=math.min(pitch,mid-n*pitch)
        if bodyKey then put(cap+n*pitch,h,0,0,bodyKey,{0,h/pitch})
        else local sh=h/width*d.cw;put(cap+n*pitch,h,(d.ch-d.cw*2)/2,sh)end
    end
    for n=index+1,#list do list[n]:Hide()end
end
function S.Arrow(b,up)
    local t=tex(b,up and "ArrowUp"or"ArrowDown","ARTWORK");t:SetAllPoints(b);return {t}
end
function S.Scrollbar(bar)
    bar:SetBackdrop(nil)
    local thumb=bar:GetThumbTexture();thumb:SetTexture(nil);thumb:SetWidth(14)
    if not bar._merchantGrip then
        local g=CreateFrame("Frame",nil,bar);g:EnableMouse(false);g:SetPoint("TOP",thumb,"TOP");g:SetPoint("BOTTOM",thumb,"BOTTOM");g:SetWidth(14)
        g.detail=tex(g,"ScrollGrip","OVERLAY");place(g.detail,"CENTER",g,"CENTER");g.detail:SetSize(14,14);bar._merchantGrip=g
    end
    S.UpdateScrollbar(bar,1)
end
function S.UpdateScrollbar(bar,maximum)
    vertical(bar,"ScrollTrack",14,bar:GetHeight())
    local grip=bar._merchantGrip
    if grip then
        vertical(grip,"ScrollThumb",14,bar:GetThumbTexture():GetHeight(),"ScrollThumbBody")
        if maximum>0 then grip:Show()else grip:Hide()end
    end
end
function S.Apply(chrome)
    local window=MerchantFrame;if not chrome.grid or not chrome.band then return end
    if not chrome.newMerchantPanel then
        chrome.gridRim:Hide();chrome.bandRim:Hide();hideTextures(chrome.grid);hideTextures(chrome.band);chrome.wash:Hide()
        local panel=CreateFrame("Frame",nil,window);panel:EnableMouse(false);panel:SetFrameLevel(window:GetFrameLevel()+1);panel:SetAllPoints(window)
        -- Shorten only the quiet lower middle. Both quads retain the same .6
        -- pixel scale, preserving all corners, bronze rails and stone details.
        local d=I.PanelRect;local scale=768/d.cw;local split=512
        panel.art=tex(panel,"PanelRect");place(panel.art,"TOPLEFT",panel,"TOPLEFT")
        panel.art:SetSize(768,split*scale);panel.art:SetTexCoord(0,d.cw/d.w,0,split/d.h)
        panel.lower=tex(panel,"PanelRect");place(panel.lower,"BOTTOMLEFT",panel,"BOTTOMLEFT")
        local h=436-split*scale;panel.lower:SetSize(768,h);panel.lower:SetTexCoord(0,d.cw/d.w,(d.ch-h/scale)/d.h,d.ch/d.h)
        chrome.newMerchantPanel=panel
        local head=CreateFrame("Frame",nil,window);head:EnableMouse(false);head:SetFrameLevel(window:GetFrameLevel()+2);place(head,"TOPLEFT",window,"TOPLEFT",42,-38);head:SetSize(684,64)
        head.art=tex(head,"Banner");image(head.art,"Banner",head,684,64)
        head.mode=head:CreateFontString(nil,"OVERLAY","GameFontNormal");head.mode:SetPoint("CENTER");head.mode:SetText(BUYBACK or "Buyback")
        chrome.newMerchantHeader=head
        local bottom=CreateFrame("Frame",nil,window);bottom:EnableMouse(false);bottom:SetFrameLevel(window:GetFrameLevel()+2);bottom:SetAllPoints(chrome.band)
        bottom.art=tex(bottom,"Banner");image(bottom.art,"Banner",bottom,684,64);chrome.newMerchantFooter=bottom
    end
    chrome.header:Hide();chrome.wash:Hide()
    if window.Title then window.Title:Hide()end
    if chrome.merchantHeader then chrome.merchantHeader:Hide()end
    if window.selectedTab==1 then chrome.newMerchantHeader.mode:Hide()else chrome.newMerchantHeader.mode:Show()end
    local close=window.CloseButton
    if close then
        close:SetSize(26,26);place(close,"TOPRIGHT",window,"TOPRIGHT",-7,-7);close:SetFrameLevel(window:GetFrameLevel()+24)
        for _,kind in ipairs({"Normal","Pushed","Disabled","Highlight"})do
            local t=close["Get"..kind.."Texture"](close)
            if t then t:SetTexture(S.ART.."Close");t:SetTexCoord(0,1,0,1);t:ClearAllPoints();t:SetAllPoints(close);t:SetBlendMode(kind=="Highlight"and"ADD"or"BLEND");t:SetAlpha(kind=="Highlight"and .2 or 1)end
        end
    end
    for i=1,2 do S.Button(_G["MerchantFrameTab"..i],window.selectedTab==i)end
    for i=1,12 do S.Money(_G["MerchantItem"..i.."MoneyFrame"],12)end
    S.Money(MerchantMoneyFrame,14);S.Money(MerchantBuyBackItemMoneyFrame,12)
    for _,name in ipairs({"MerchantRepairItemButton","MerchantRepairAllButton","MerchantGuildBankRepairButton","DragonUI_MerchantSellAllJunkButton","MerchantBuyBackItemItemButton"})do
        local b=_G[name]
        if b and not b.merchantServiceRim then b.merchantServiceRim=S.Frame(b,b)end
    end
    local junk=_G.DragonUI_MerchantSellAllJunkButton;if junk and junk.Icon then S.ServiceIcon(junk.Icon,"SellJunk",junk)end
    local recent=_G.MerchantBuyBackItemItemButton
    if recent then
        local normal=recent:GetNormalTexture()
        if normal then normal:SetTexture(S.ART.."SlotWell");normal:SetTexCoord(0,1,0,1);normal:ClearAllPoints();normal:SetAllPoints(recent);normal:SetDrawLayer("BACKGROUND")end
        if recent.UndoFrame then
            for _,t in ipairs({recent.UndoFrame:GetRegions()})do
                if t:GetObjectType()=="Texture"then t:SetTexture(S.ART.."Undo");t:SetTexCoord(0,1,0,1);t:SetBlendMode("BLEND");t:SetSize(20,20)end
            end
        end
        local old=_G.MerchantBuyBackItemSlotTexture;if old then old:Hide()end
    end
end
