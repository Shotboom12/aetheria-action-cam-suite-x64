-- Pure geometry; no UI allocation or event polling.
local addon=select(2,...)
local Grid={};addon.BagsterModule.Grid=Grid
local floor,ceil,min,max=math.floor,math.ceil,math.min,math.max
local function clamp(v,a,b)return max(a,min(b,v))end
local function groups(n,breaks)
    local out={};local prev=0
    for _,v in ipairs(breaks or {})do
        v=clamp(floor(tonumber(v)or 0),0,n)
        if v>prev then out[#out+1]=v-prev;prev=v end
    end
    if n>prev then out[#out+1]=n-prev end
    return out
end
local function rows(gs,cols,space)
    local r=0;for _,n in ipairs(gs)do r=r+ceil(n/cols)end
    return r+max(0,#gs-1)*(space-1)
end
function Grid.Compute(width,height,n,breaks,capacity,capacityBreaks,cfg)
    cfg=cfg or {};width=max(1,width);height=max(1,height);n=max(0,n)
    local gap=clamp(tonumber(cfg.item_spacing)or 2,0,12)
    local space=clamp(tonumber(cfg.break_space)or 1.3,1,3)
    local gs=groups(n,breaks)
    local icon=37*clamp(tonumber(cfg.item_scale)or 1.5,.5,3)
    if cfg.auto_fit~=false then
        local cap=max(n,capacity or n);local cg=groups(cap,capacityBreaks)
        local best=0
        for cols=1,max(1,min(cap,floor((width+gap)/(32+gap))))do
            local r=max(1,rows(cg,cols,space))
            local fit=min((width-(cols-1)*gap)/cols,(height-(r-1)*gap)/r)
            if fit>best then best=fit end
        end
        icon=clamp(best,32,96)
    end
    icon=min(icon,width)
    local columns=max(1,floor((width+gap)/(icon+gap)+.00001))
    local pitch=icon+gap
    local left=max(0,(width-(columns*icon+(columns-1)*gap))/2)
    local positions={};local y=0;local used=0
    for _,count in ipairs(gs)do
        for i=0,count-1 do
            local py=y+floor(i/columns)*pitch
            positions[#positions+1]={x=left+(i%columns)*pitch,y=py}
            used=max(used,py+icon)
        end
        y=y+(ceil(count/columns)+space-1)*pitch
    end
    return {icon=icon,scale=icon/37,columns=columns,positions=positions,
        contentHeight=used,overflow=max(0,used-height),gap=gap}
end
