-- Size-matched coverage-filtered art. Every quad keeps one source-pixel scale
-- on both axes; only quiet material repeats/crops as controls resize.
local A={};DragonUICharacterControlArt=A
local ROOT="Interface\\AddOns\\DragonUI_CharacterScreen\\Assets\\ControlsAA\\"
A.Info={SectionAA={512,64},ChromeAA={512,64},TrackAA={32,512},ThumbAA={32,128},ThumbBodyAA={32,128},GripAA={32,32}}
local function place(t,p,o,x,y)t:ClearAllPoints();t:SetPoint(p,o,p,x or 0,y or 0)end
local function piece(p,key,x,y,w,h,sx,sy,sw,sh)
    p.used=p.used+1;local t=p[p.used]
    if not t then
        t=p.owner:CreateTexture(nil,p.layer);p[p.used]=t;t:SetBlendMode("BLEND")
        local first=p[1]
        if first~=t then
            t:SetAlpha(first:GetAlpha());t:SetVertexColor(first:GetVertexColor());t:SetBlendMode(first:GetBlendMode())
        end
    end
    local d=A.Info[key];t.key=key;t:SetTexture(ROOT..key)
    place(t,"TOPLEFT",p.target,x,-y);t:SetSize(w,h);t:SetTexCoord(sx/d[1],(sx+sw)/d[1],sy/d[2],(sy+sh)/d[2]);t:Show()
end
function A.Refresh(p)
    local w,h=p.target:GetWidth(),p.target:GetHeight()
    if w<=0 or h<=0 then return end
    p.used=0
    if p.vertical then
        local d=A.Info[p.key];local scale=w/d[1];local cap=math.min(16*scale,h/2)
        piece(p,p.key,0,0,w,cap,0,0,d[1],cap/scale)
        piece(p,p.key,0,h-cap,w,cap,0,d[2]-cap/scale,d[1],cap/scale)
        local key=p.key=="ThumbAA"and"ThumbBodyAA"or p.key
        local start=key=="TrackAA"and 64 or 0;local length=key=="TrackAA"and 256 or 128
        local overlap=math.min(1,cap/4)
        local pitch=length*scale;local y=cap-overlap
        while y<h-cap+overlap-.001 do
            local height=math.min(pitch,h-cap+overlap-y)
            piece(p,key,0,y,w,height,0,start,d[1],height/scale);y=y+height
        end
        if p.grip then p.grip:SetSize(w,w);place(p.grip,"CENTER",p.target)end
    else
        local scale=h/64;local cap=math.min(36*scale,w/2)
        piece(p,p.key,0,0,cap,h,0,0,cap/scale,64)
        piece(p,p.key,w-cap,0,cap,h,512-cap/scale,0,cap/scale,64)
        local overlap=math.min(1,cap/4)
        local pitch=440*scale;local x=cap-overlap
        while x<w-cap+overlap-.001 do
            local width=math.min(pitch,w-cap+overlap-x)
            piece(p,p.key,x,0,width,h,36-overlap/scale,0,width/scale,64);x=x+width
        end
    end
    for i=p.used+1,#p do p[i]:Hide()end
end
local function create(owner,key,layer,target,vertical)
    local p={owner=owner,target=target or owner,key=key,layer=layer,vertical=vertical}
    if vertical and key=="ThumbAA"then
        local t=owner:CreateTexture(nil,"OVERLAY");t:SetTexture(ROOT.."GripAA");t:SetBlendMode("BLEND");p.grip=t
    end
    A.Refresh(p);owner:HookScript("OnSizeChanged",function()A.Refresh(p)end)
    return p
end
function A.Horizontal(owner,key,layer,target)return create(owner,key,layer,target,false)end
function A.Vertical(owner,key,layer)return create(owner,key,layer,nil,true)end
