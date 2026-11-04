-- Merchant catalog controls. Transaction APIs and native button handlers are untouched.
local addon=select(2,...)
local V=addon.MerchantCatalog
local F={filter={},sort="stock",descending=false,items={},lastIDs={},rowOffset=0,maxRows=0}
addon.MerchantFilters=F
local built,busy=false,false
local controls,filterMenu,sortMenu,counter,empty,scrollbar,upButton,downButton
local syncingScroll=false
local lastMode
local pending,retries,tick=false,0,0
local function place(f,p,r,rp,x,y)
    f:ClearAllPoints();f:SetPoint(p,r,rp,x or 0,y or 0)
end
local function closeSplit()
    if StackSplitFrame and StackSplitFrame:IsShown() then
        local owner=StackSplitFrame.owner
        local name=owner and owner.GetName and owner:GetName()
        if name and name:match("^MerchantItem%d+ItemButton$") then StackSplitFrame:Hide() end
    end
end
local function scan()
    local items={};pending=false
    for i=1,GetMerchantNumItems() do
        local name,_,price,quantity,stock,usable,extended=GetMerchantItemInfo(i)
        local link=GetMerchantItemLink(i)
        local cached,_,quality,level,required,category,subtype=GetItemInfo(link or name or "")
        if not cached then pending=true end
        items[#items+1]={index=i,name=name or cached or (UNKNOWN or "Unknown"),link=link,
            price=price or 0,quantity=quantity,stock=stock,usable=usable==true or usable==1,
            extended=extended,cached=cached~=nil,quality=quality,level=level,required=required,
            category=category,subtype=subtype}
    end
    F.items=items
    return items
end
-- Same native row fields, stock coloring and alternate-currency rendering;
-- only the vendor index is selected by the catalog rather than page arithmetic.
function F.RenderRow(i,entry)
    local name,texture,price,quantity,numAvailable,isUsable,extendedCost
		local index = entry and entry.index or 0;
		local itemButton = _G["MerchantItem"..i.."ItemButton"];
		local merchantButton = _G["MerchantItem"..i];
		local merchantMoney = _G["MerchantItem"..i.."MoneyFrame"];
		local merchantAltCurrency = _G["MerchantItem"..i.."AltCurrencyFrame"];
		if ( entry ) then
			name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(index);
			_G["MerchantItem"..i.."Name"]:SetText(name);
			SetItemButtonCount(itemButton, quantity);
			SetItemButtonStock(itemButton, numAvailable);
			SetItemButtonTexture(itemButton, texture);
			
			if ( extendedCost and (price <= 0) ) then
				itemButton.price = nil;
				itemButton.extendedCost = true;
				itemButton.link = GetMerchantItemLink(index);
				itemButton.texture = texture;
				MerchantFrame_UpdateAltCurrency(index, i);
				merchantAltCurrency:ClearAllPoints();
				merchantAltCurrency:SetPoint("BOTTOMLEFT", "MerchantItem"..i.."NameFrame", "BOTTOMLEFT", 0, 31);
				merchantMoney:Hide();
				merchantAltCurrency:Show();
			elseif ( extendedCost and (price > 0) ) then
				itemButton.price = price;
				itemButton.extendedCost = true;
				itemButton.link = GetMerchantItemLink(index);
				itemButton.texture = texture;
				MerchantFrame_UpdateAltCurrency(index, i);
				MoneyFrame_Update(merchantMoney:GetName(), price);
				merchantAltCurrency:ClearAllPoints();
				merchantAltCurrency:SetPoint("LEFT", merchantMoney:GetName(), "RIGHT", -14, 0);
				merchantAltCurrency:Show();
				merchantMoney:Show();
			else
				itemButton.price = price;
				itemButton.extendedCost = nil;
				itemButton.link = GetMerchantItemLink(index);
				itemButton.texture = texture;
				MoneyFrame_Update(merchantMoney:GetName(), price);
				merchantAltCurrency:Hide();
				merchantMoney:Show();
			end

			itemButton.hasItem = true;
			itemButton:SetID(index);
			itemButton:Show();
			if ( numAvailable == 0 ) then
				-- If not available and not usable
				if ( not isUsable ) then
					SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0, 0);
					SetItemButtonSlotVertexColor(merchantButton, 0.5, 0, 0);
					SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0);
					SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0);
				else
					SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
					SetItemButtonSlotVertexColor(merchantButton, 0.5, 0.5, 0.5);
					SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5);
					SetItemButtonNormalTextureVertexColor(itemButton,0.5, 0.5, 0.5);
				end
				
			elseif ( not isUsable ) then
				SetItemButtonNameFrameVertexColor(merchantButton, 1.0, 0, 0);
				SetItemButtonSlotVertexColor(merchantButton, 1.0, 0, 0);
				SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0);
				SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0);
			else
				SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
				SetItemButtonSlotVertexColor(merchantButton, 1.0, 1.0, 1.0);
				SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
				SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
			end
		else
			itemButton.price = nil;
			itemButton.hasItem = nil;
			itemButton:Hide();
			SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
			SetItemButtonSlotVertexColor(merchantButton,0.4, 0.4, 0.4);
			_G["MerchantItem"..i.."Name"]:SetText("");
			_G["MerchantItem"..i.."MoneyFrame"]:Hide();
			_G["MerchantItem"..i.."AltCurrencyFrame"]:Hide();
		end
    if entry then
        merchantButton:Show()
        if addon.merchantParts and addon.merchantParts.decorateVendorRow then
            addon.merchantParts.decorateVendorRow(i,entry.index)
        end
    else
        itemButton:SetID(0)
        merchantButton:Hide()
    end
end
local sortOptions={
    {"stock","Vendor order"},{"name","Name"},{"type","Type"},{"quality","Quality"},
    {"price","Price (gold)"},{"required","Required level"},{"level","Item level"},
}
local function sortLabel()
    for _,x in ipairs(sortOptions) do if x[1]==F.sort then return x[2] end end
end
local function updateLabels()
    local text=F.filter.subtype or F.filter.category or "All items"
    if F.filter.usable then text="Usable: "..text end
    UIDropDownMenu_SetText(filterMenu,text)
    UIDropDownMenu_SetText(sortMenu,sortLabel())
end
local function draw()
    if busy or not built or not MerchantFrame:IsShown() then return end
    busy=true
    local buying=MerchantFrame.selectedTab==1
    if buying then controls:Show() else controls:Hide() end
    if not buying then
        empty:Hide();scrollbar:GetParent():Hide();lastMode=2
        -- Native buyback updates its item buttons; restore their row containers.
        for i=1,12 do _G["MerchantItem"..i]:Show() end
        busy=false;return
    end
    if lastMode~=1 then F.rowOffset=0 end
    lastMode=1
    local view=V.Build(scan(),F.filter,F.sort,F.descending)
    local page,offset,maximum=V.Window(view,F.rowOffset,4,2)
    F.rowOffset=offset;F.maxRows=maximum
    -- Native updates may refill page one first; visible rows are rebound below.
    MerchantFrame.page=1
    local changed=false
    for i=1,10 do
        local index=page[i] and page[i].index or 0
        if F.lastIDs[i]~=index then changed=true end
        F.lastIDs[i]=index
    end
    if changed then closeSplit() end
    for i=1,10 do F.RenderRow(i,page[i]) end
    MerchantPageText:Hide()
    MerchantPrevPageButton:Hide();MerchantNextPageButton:Hide()
    scrollbar:GetParent():Show()
    syncingScroll=true
    scrollbar:SetMinMaxValues(0,maximum);scrollbar:SetValue(offset)
    scrollbar:GetThumbTexture():SetHeight(math.max(24,scrollbar:GetHeight()*4/math.max(4,math.ceil(#view/2))))
    syncingScroll=false
    if offset>0 then upButton:Enable() else upButton:Disable() end
    if offset<maximum then downButton:Enable() else downButton:Disable() end
    if maximum==0 then scrollbar:EnableMouse(false);scrollbar:GetThumbTexture():SetAlpha(0)
    else scrollbar:EnableMouse(true);scrollbar:GetThumbTexture():SetAlpha(1) end
    addon.MerchantStyle.UpdateScrollbar(scrollbar,maximum)
    if addon.MerchantStyle then
        for i=1,10 do addon.MerchantStyle.Row(i,addon.MerchantStyle.Geometry(true));addon.MerchantStyle.Money(_G["MerchantItem"..i.."MoneyFrame"],12) end
    end
    counter:SetText(string.format("%d / %d%s",#view,#F.items,pending and " ..." or ""))
    if #view==0 then empty:Show() else empty:Hide() end
    updateLabels()
    if addon.MerchantStyle then addon.MerchantStyle.Dropdown(filterMenu,168);addon.MerchantStyle.Dropdown(sortMenu,180) end
    -- An open tooltip must follow the row's current original vendor index.
    if changed and GameTooltip and GameTooltip:GetOwner() then
        local owner=GameTooltip:GetOwner()
        local name=owner.GetName and owner:GetName()
        if name and name:match("^MerchantItem%d+ItemButton$") then
            if owner.hasItem and owner:IsShown() then MerchantItemButton_OnEnter(owner) else GameTooltip:Hide() end
        end
    end
    busy=false
end
local function refresh()
    closeSplit();F.rowOffset=0;MerchantFrame.page=1;retries=0
    MerchantFrame_Update()
end
function F.ScrollBy(delta)
    if not built or not MerchantFrame:IsShown() or MerchantFrame.selectedTab~=1 then return end
    local offset=math.max(0,math.min(F.maxRows,F.rowOffset+delta))
    if offset==F.rowOffset then return end
    F.rowOffset=offset;draw()
end
function F.ResetScroll()
    F.rowOffset=0;refresh()
end
local function wheel(_,delta)
    F.ScrollBy(delta>0 and -1 or 1)
end
local function buildScroll()
    local geometry=addon.MerchantStyle.Geometry(true)
    local gutter=CreateFrame("Frame",nil,MerchantFrame)
    gutter:SetPoint("TOPLEFT",MerchantFrame,"TOPLEFT",geometry.gutter,-geometry.top);gutter:SetSize(16,geometry.gutterHeight)
    gutter:SetFrameLevel(MerchantFrame:GetFrameLevel()+17)
    scrollbar=CreateFrame("Slider","DragonUIMerchantScrollBar",gutter)
    scrollbar:SetOrientation("VERTICAL");scrollbar:SetPoint("TOPLEFT",gutter,"TOPLEFT",1,-18)
    scrollbar:SetSize(14,geometry.trackHeight);scrollbar:SetValueStep(1);scrollbar:SetMinMaxValues(0,0)
    scrollbar:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb=scrollbar:GetThumbTexture();thumb:SetSize(14,32)
    addon.MerchantStyle.Scrollbar(scrollbar)
    scrollbar:SetScript("OnValueChanged",function(_,value)
        if not syncingScroll then F.ScrollBy(math.floor(value+.5)-F.rowOffset) end
    end)
    local function arrow(top)
        local b=CreateFrame("Button",nil,gutter);b:SetSize(16,16)
        b:SetPoint(top and "TOP" or "BOTTOM",gutter,top and "TOP" or "BOTTOM",0,0)
        local pixels=addon.MerchantStyle.Arrow(b,top)
        b:SetScript("OnClick",function()F.ScrollBy(top and -1 or 1)end)
        b:SetScript("OnEnable",function()for _,t in ipairs(pixels)do t:SetAlpha(1)end end)
        b:SetScript("OnDisable",function()for _,t in ipairs(pixels)do t:SetAlpha(.45)end end)
        return b
    end
    upButton=arrow(true);downButton=arrow(false)
    for _,owner in ipairs({MerchantFrame,gutter,scrollbar}) do
        owner:EnableMouseWheel(true);owner:HookScript("OnMouseWheel",wheel)
    end
    for i=1,10 do
        for _,owner in ipairs({_G["MerchantItem"..i],_G["MerchantItem"..i.."ItemButton"]}) do
            owner:EnableMouseWheel(true);owner:HookScript("OnMouseWheel",wheel)
        end
    end
    F.scrollBar=scrollbar
end
local function choose(category,subtype)
    F.filter.category=category;F.filter.subtype=subtype
    CloseDropDownMenus();refresh()
end
local function add(info,level)
    UIDropDownMenu_AddButton(info,level)
end
local function filterInitialize(_,level,value)
    level=level or 1
    if level==1 then
        add({text="Usable by my character",isNotRadio=true,keepShownOnClick=true,
            checked=F.filter.usable==true,func=function()F.filter.usable=not F.filter.usable;refresh()end},level)
        add({text="All item types",checked=F.filter.category==nil,func=function()choose()end},level)
        local categories={}
        for _,item in ipairs(F.items) do
            if item.category then
                categories[item.category]=categories[item.category] or {}
                if item.subtype then categories[item.category][item.subtype]=true end
            end
        end
        local names={};for name in pairs(categories) do names[#names+1]=name end;table.sort(names)
        F.categories=categories
        for _,category in ipairs(names) do
            local name=category
            add({text=name,hasArrow=true,value=name,checked=F.filter.category==name,
                func=function()choose(name)end},level)
        end
        add({text="Reset filters",notCheckable=true,func=function()F.filter={};CloseDropDownMenus();refresh()end},level)
    elseif level==2 then
        local category=value or UIDROPDOWNMENU_MENU_VALUE
        if not category then return end
        add({text="All "..category,checked=F.filter.category==category and F.filter.subtype==nil,
            func=function()choose(category)end},level)
        local subtypes={}
        for name in pairs((F.categories or {})[category] or {}) do subtypes[#subtypes+1]=name end
        table.sort(subtypes)
        for _,subtype in ipairs(subtypes) do
            local name=subtype
            add({text=name,checked=F.filter.category==category and F.filter.subtype==name,
                func=function()choose(category,name)end},level)
        end
    end
end
local function sortInitialize()
    for _,option in ipairs(sortOptions) do
        local key,text=option[1],option[2]
        add({text=text,checked=F.sort==key,func=function()
            F.sort=key;F.descending=key=="quality" or key=="level" or key=="required"
            CloseDropDownMenus();refresh()
        end},1)
    end
    add({text="Highest first",isNotRadio=true,disabled=F.sort=="stock",checked=F.descending,
        func=function()F.descending=not F.descending;CloseDropDownMenus();refresh()end},1)
end
local function build()
    if built or not MerchantFrame then return end
    controls=CreateFrame("Frame",nil,MerchantFrame)
    controls:SetFrameLevel(MerchantFrame:GetFrameLevel()+16)
    controls:SetPoint("TOPLEFT",MerchantFrame,"TOPLEFT",84,-58)
    controls:SetSize(600,24)
    filterMenu=CreateFrame("Frame","DragonUIMerchantFilterMenu",controls,"UIDropDownMenuTemplate")
    sortMenu=CreateFrame("Frame","DragonUIMerchantSortMenu",controls,"UIDropDownMenuTemplate")
    for _,menu in ipairs({filterMenu,sortMenu}) do
        menu:SetScale(.8);UIDropDownMenu_SetWidth(menu,150)
    end
    place(filterMenu,"TOPLEFT",controls,"TOPLEFT",0,0)
    place(sortMenu,"TOPLEFT",controls,"TOPLEFT",182,0)
    UIDropDownMenu_Initialize(filterMenu,filterInitialize)
    UIDropDownMenu_Initialize(sortMenu,sortInitialize)
    counter=controls:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    counter:SetPoint("RIGHT",controls,"RIGHT",-6,0)
    counter:SetTextColor(.75,.7,.58)
    empty=MerchantFrame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    empty:SetPoint("TOP",MerchantFrame,"TOP",0,-206)
    empty:SetWidth(480);empty:SetText("No items match these filters.")
    empty:Hide()
    buildScroll()
    built=true
    hooksecurefunc("MerchantFrame_UpdateMerchantInfo",draw)
    hooksecurefunc("MerchantFrame_UpdateBuybackInfo",draw)
    MerchantFrame:HookScript("OnHide",function()
        CloseDropDownMenus();controls:Hide();empty:Hide();scrollbar:GetParent():Hide();F.lastIDs={};F.rowOffset=0;lastMode=nil
    end)
    if MerchantFrame:IsShown() then MerchantFrame_Update() end
end
local driver=CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN");driver:RegisterEvent("MERCHANT_SHOW")
pcall(driver.RegisterEvent,driver,"GET_ITEM_INFO_RECEIVED")
driver:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then build()
    elseif event=="MERCHANT_SHOW" then
        F.filter={};F.sort="stock";F.descending=false;F.lastIDs={};F.rowOffset=0;lastMode=nil;retries=0
        build();MerchantFrame_Update()
    elseif pending and MerchantFrame and MerchantFrame:IsShown() then
        MerchantFrame_Update()
    end
end)
driver:SetScript("OnUpdate",function(_,dt)
    if not pending or not built or not MerchantFrame:IsShown() or MerchantFrame.selectedTab~=1 or retries>=20 then return end
    tick=tick+dt;if tick<.5 then return end;tick=0;retries=retries+1
    MerchantFrame_Update()
end)
