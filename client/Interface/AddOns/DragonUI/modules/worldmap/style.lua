-- Presentation only. Native map coordinates, quest data and input handlers stay authoritative.
local addon = select(2, ...)
local S = {}
addon.WorldMap.Style = S
S.ART = "Interface\\AddOns\\DragonUI\\modules\\worldmap\\textures\\parchment\\"
S.BODY = {0.31,0.235,0.16}
S.HEADING = {0.408,0.251,0.094}
S.FOCUS = {0.13,0.27,0.31}

function S.Ink(text, color)
    if not text then return end
    text:SetTextColor(unpack(color or S.BODY))
    text:SetShadowColor(0,0,0,0);text:SetShadowOffset(0,0)
    local face,size,flags=text:GetFont()
    if face then text:SetFont(face,size,(flags or ""):gsub("THICKOUTLINE",""):gsub("OUTLINE",""):gsub(",", "")) end
end

function S.Difficulty(color)
    -- Keep difficulty distinctions with ink dark enough for a light paper surface.
    if color.r > .8 and color.g < .25 then return {r=.61,g=.12,b=.08} end
    if color.r > .8 and color.g < .7 then return {r=.52,g=.24,b=.07} end
    if color.g > .7 and color.r < .5 then return {r=.15,g=.34,b=.19} end
    if color.r < .7 and color.g < .7 then return {r=.35,g=.32,b=.28} end
    return {r=.40,g=.29,b=.08}
end

local function tex(host,file,layer)
    local t=host:CreateTexture(nil,layer or "BACKGROUND")
    t:SetTexture(S.ART..file)
    return t
end

function S.Frame(host,target,cap,metalOnly)
    local holder=CreateFrame("Frame",nil,host)
    holder:SetAllPoints(target);holder:SetFrameLevel(host:GetFrameLevel()+20)
    holder:EnableMouse(false)
    if metalOnly then
        -- The art's transparent outer pixels must not expose map tiles at the screen edge.
        holder.edgeBacking={}
        for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
            local t=holder:CreateTexture(nil,"BACKGROUND")
            t:SetTexture(.075,.052,.03,1)
            if side=="TOP" or side=="BOTTOM" then
                t:SetPoint(side.."LEFT",target,side.."LEFT")
                t:SetPoint(side.."RIGHT",target,side.."RIGHT");t:SetHeight(8)
            else
                t:SetPoint("TOP"..side,target,"TOP"..side)
                t:SetPoint("BOTTOM"..side,target,"BOTTOM"..side);t:SetWidth(8)
            end
            holder.edgeBacking[#holder.edgeBacking+1]=t
        end
    end
    local u,v={0,.08,.92,1},{0,.04,.96,1}
    if metalOnly then u,v={0,.25,.75,1},{0,.25,.75,1} end
    holder.pieces={};holder.repeatingEdges={}
    for y=1,3 do for x=1,3 do
        if x~=2 or y~=2 then
            local t=tex(holder,metalOnly and "MapBronzeHD.tga" or "MapBorderHD.tga","OVERLAY")
            t:SetTexCoord(u[x],u[x+1],v[y],v[y+1])
            local top,bottom,left=y==1,y==3,x==1
            if x==2 then
                local p=top and "TOP" or "BOTTOM"
                t:SetPoint(p.."LEFT",target,p.."LEFT",cap,0)
                t:SetPoint(p.."RIGHT",target,p.."RIGHT",-cap,0);t:SetHeight(cap)
            elseif y==2 then
                local p=left and "LEFT" or "RIGHT"
                t:SetPoint("TOP"..p,target,"TOP"..p,0,-cap)
                t:SetPoint("BOTTOM"..p,target,"BOTTOM"..p,0,cap);t:SetWidth(cap)
            else
                local p=(top and "TOP" or "BOTTOM")..(left and "LEFT" or "RIGHT")
                t:SetPoint(p,target,p,0,0);t:SetSize(cap,cap)
            end
            if metalOnly and (x==2 or y==2) then
                local side=x==2 and (top and "Top" or "Bottom") or (left and "Left" or "Right")
                t:SetTexture(S.ART.."Bronze"..side.."Tile.tga","REPEAT","REPEAT")
                local horizontal=x==2
                if horizontal then t:SetHorizTile(true);t:SetHeight(cap*20/64)
                else t:SetVertTile(true);t:SetWidth(cap*20/64) end
                holder.repeatingEdges[#holder.repeatingEdges+1]={texture=t,horizontal=horizontal}
            end
            holder.pieces[#holder.pieces+1]=t
        end
    end end
    if metalOnly then
        local function resize()
            for _,edge in ipairs(holder.repeatingEdges) do
                local length=math.max(1,(edge.horizontal and target:GetWidth() or target:GetHeight())-2*cap)
                local repeatCount=length/(16*cap*20/64)
                if edge.horizontal then edge.texture:SetTexCoord(0,repeatCount,0,1)
                else edge.texture:SetTexCoord(0,1,0,repeatCount) end
            end
        end
        holder:SetScript("OnSizeChanged",resize);resize()
    end
    return holder
end

function S.Header(border)
    local header=CreateFrame("Frame",nil,border)
    header:SetPoint("TOPLEFT",border,"TOPLEFT",8,-8)
    header:SetPoint("TOPRIGHT",border,"TOPRIGHT",-8,-8)
    header:SetHeight(44);header:SetFrameLevel(border:GetFrameLevel()+1)
    header:EnableMouse(false)
    local tile=header:CreateTexture(nil,"BACKGROUND")
    tile:SetTexture(S.ART.."HeaderLeatherTile.tga","REPEAT","REPEAT")
    tile:SetHorizTile(true);tile:SetAllPoints(header)
    tile:SetVertexColor(.64,.59,.52)
    local rail
    local function resize()
        tile:SetTexCoord(0,math.max(1,header:GetWidth()/176),0,1)
        if rail then rail:SetTexCoord(0,math.max(1,header:GetWidth()/64),0,1) end
    end
    header:SetScript("OnSizeChanged",resize);resize()
    rail=tex(header,"BronzeTopTile.tga","BORDER")
    rail:SetTexture(S.ART.."BronzeTopTile.tga","REPEAT","REPEAT");rail:SetHorizTile(true)
    rail:SetPoint("BOTTOMLEFT");rail:SetPoint("BOTTOMRIGHT");rail:SetHeight(4);resize()
    header.tile=tile
    header.contactShadow={}
    for i,alpha in ipairs({.38,.22,.11,.04}) do
        local shadow=header:CreateTexture(nil,"ARTWORK")
        shadow:SetTexture(0,0,0,alpha)
        shadow:SetPoint("TOPLEFT",header,"TOPLEFT",0,1-i)
        shadow:SetPoint("TOPRIGHT",header,"TOPRIGHT",0,1-i);shadow:SetHeight(1)
        header.contactShadow[i]=shadow
    end
    return header
end

function S.Tab(button,height)
    if button.paperTab then return end
    button.paperTab={}
    for i=1,3 do
        local t=tex(button,"FoldTabHD.tga")
        t:SetTexCoord(i==1 and 0 or (i==2 and .08 or .92),i==1 and .08 or (i==2 and .92 or 1),0,1)
        if i==2 then
            t:SetPoint("TOPLEFT",button,"TOPLEFT",10,3)
            t:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-10,-3)
        else
            local side=i==1 and "LEFT" or "RIGHT"
            t:SetPoint(side,button,side,0,0);t:SetSize(10,height or 30)
        end
        button.paperTab[i]=t
    end
end

function S.NavInk(text,active,hover)
    local face,_,flags=text:GetFont()
    if face then text:SetFont(face,16,flags or "") end
    if hover then text:SetTextColor(1,1,.85)
    elseif active then text:SetTextColor(1,.86,.5)
    else text:SetTextColor(.95,.90,.78) end
    text:SetShadowColor(0,0,0,.9);text:SetShadowOffset(1,-1)
end

function S.NavTab(button)
    if button.navTab then return end
    for _,t in ipairs(button.paperTab or {}) do t:SetAlpha(0) end
    button.navTab={}
    for i=1,3 do
        local t=tex(button,"ChromeStripHD.tga")
        t:SetTexCoord(i==1 and 0 or (i==2 and .07 or .93),i==1 and .07 or (i==2 and .93 or 1),0,1)
        if i==2 then
            t:SetPoint("TOPLEFT",button,"TOPLEFT",16,0)
            t:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-20,0)
        else
            local side=i==1 and "LEFT" or "RIGHT"
            local dx=i==1 and 0 or -4
            t:SetPoint("TOP"..side,button,"TOP"..side,dx,0)
            t:SetPoint("BOTTOM"..side,button,"BOTTOM"..side,dx,0);t:SetWidth(16)
        end
        button.navTab[i]=t
    end
end

function S.Button(button)
    -- Keep the original font string and all native click/enable/tooltip behavior.
    -- SkinRedButton owns separate artwork strips, not just NormalTexture.
    for _,region in ipairs({button:GetRegions()}) do
        if region:GetObjectType()=="Texture" then region:SetAlpha(0) end
    end
    for _,state in ipairs({"Normal","Pushed","Disabled"}) do
        local t=button["Get"..state.."Texture"] and button["Get"..state.."Texture"](button)
        if t then t:SetAlpha(0) end
    end
    local parts={}
    for i=1,3 do
        local t=tex(button,"ChromeStripHD.tga")
        t:SetTexCoord(i==1 and 0 or (i==2 and .07 or .93),i==1 and .07 or (i==2 and .93 or 1),0,1)
        if i==2 then
            t:SetPoint("TOPLEFT",button,"TOPLEFT",8,0);t:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-8,0)
        else
            local side=i==1 and "LEFT" or "RIGHT"
            t:SetPoint("TOP"..side,button,"TOP"..side);t:SetPoint("BOTTOM"..side,button,"BOTTOM"..side);t:SetWidth(8)
        end
        parts[i]=t
    end
    local label=button.GetFontString and button:GetFontString()
    if label then label:SetTextColor(1,.94,.82);label:SetShadowColor(0,0,0,.8);label:SetShadowOffset(1,-1) end
    hooksecurefunc(button,"Disable",function() for _,t in ipairs(parts) do t:SetAlpha(.5) end end)
    hooksecurefunc(button,"Enable",function() for _,t in ipairs(parts) do t:SetAlpha(1) end end)
end

function S.Search(search)
    for _,region in ipairs({search:GetRegions()}) do
        if region:GetObjectType()=="Texture" then region:SetAlpha(0) end
    end
    S.Tab(search,24)
    search:SetTextColor(unpack(S.BODY))
end

function S.Overflow(button)
    button:GetNormalTexture():SetAlpha(0);button:GetPushedTexture():SetAlpha(0)
    S.NavTab(button)
    local label=button:CreateFontString(nil,"OVERLAY","GameFontNormal")
    label:SetPoint("CENTER");label:SetText("...");S.NavInk(label)
end
