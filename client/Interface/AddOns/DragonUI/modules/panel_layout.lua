-- Local screen-fitted presentation. Native panel contents and input handlers stay intact.
local addon = select(2, ...)
local Layout = {}
addon.PanelLayout = Layout
local managed = {}
local busy = false
local specs = {
    CharacterFrame = {kind="character", width=.84, height=.86, tabs=34},
    DragonUICollectionsFrame = {kind="collections", width=.75, height=.90, tabs=34},
    AchievementFrame = {kind="achievements", width=.80, height=.80, tabs=34},
}

local function bagLeftEdge()
    local left
    local rootScale = UIParent:GetEffectiveScale()
    for i=1, (NUM_CONTAINER_FRAMES or 13) do
        local bag = _G["ContainerFrame"..i]
        if bag and bag:IsShown() and bag:GetID() >= 0 and bag:GetID() <= 4 then
            local x = bag:GetLeft()
            if x then
                -- The portrait ring extends beyond the native bag rectangle.
                x = (x-18)*bag:GetEffectiveScale()/rootScale
                left = left and math.min(left,x) or x
            end
        end
    end
    return left
end

function Layout:Apply(frame, spec)
    if busy or not frame or not frame:IsShown() then return end
    if InCombatLockdown() and frame:IsProtected() then return end
    busy = true
    if MovAny then
        if MovAny.UnlockPoint then MovAny:UnlockPoint(frame) end
        if MovAny.UnlockScale then MovAny:UnlockScale(frame) end
    end
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    local width,height=frame:GetWidth(),frame:GetHeight()
    if width<=0 or height<=0 then busy=false;return end
    local right = spec.kind=="character" and ((bagLeftEdge() or sw*.84)-20) or nil
    local available = right and math.max(200,right-28) or sw*spec.width
    local scale=math.min(spec.kind=="character" and 1.6 or 3, available/width, sh*spec.height/(height+spec.tabs))
    if spec.kind=="character" and math.abs((Layout.modelScale or 0)-scale)>.001 then
        Layout.modelScale=scale
        Layout.refitModel=true
    end
    if spec.kind=="collections" and math.abs((frame._duiLayoutScale or 0)-scale)>.001 then
        Layout.refitCollections=frame
    end
    frame._duiLayoutScale=scale
    frame:SetScale(scale)
    frame:ClearAllPoints()
    local setter=frame.MASetPoint or frame.SetPoint
    local x=spec.kind=="character" and (28+width*scale/2) or sw/2
    -- Center the entire visible silhouette, including the tabs below the frame.
    setter(frame,"CENTER",UIParent,"BOTTOMLEFT",x/scale,sh/(2*scale)+spec.tabs/2)
    busy=false
end

-- The patched client can bypass the bag-skin anchor callback. Pack the actual
-- visible inventory frames, preserving each bag's scale and native item widgets.
function Layout:SpaceBags()
    if InCombatLockdown() then return end
    local bags={}
    local rootScale=UIParent:GetEffectiveScale()
    for i=1,(NUM_CONTAINER_FRAMES or 13) do
        local bag=_G["ContainerFrame"..i]
        if bag and bag:IsShown() and bag:GetID()>=0 and bag:GetID()<=4 then bags[#bags+1]=bag end
    end
    table.sort(bags,function(a,b)return a:GetID()<b:GetID()end)
    local right,bottom=UIParent:GetWidth()-8,80
    local columnLeft=right
    for _,bag in ipairs(bags) do
        local ratio=bag:GetEffectiveScale()/rootScale
        local width,height=bag:GetWidth()*ratio,bag:GetHeight()*ratio
        if bottom>80 and bottom+height+18>UIParent:GetHeight()-28 then
            right=columnLeft-14;bottom=80;columnLeft=right
        end
        local x,y=bag:GetRight(),bag:GetBottom()
        if not x or math.abs(x*ratio-right)>.2 or not y or math.abs(y*ratio-bottom)>.2 then
            bag:ClearAllPoints()
            local setter=bag.MASetPoint or bag.SetPoint
            setter(bag,"BOTTOMRIGHT",UIParent,"BOTTOMLEFT",right/ratio,bottom/ratio)
        end
        columnLeft=math.min(columnLeft,right-width)
        bottom=bottom+height+10
    end
end

function Layout:Refresh()
    for frame,spec in pairs(managed) do self:Apply(frame,spec) end
end

local function discover()
    for name,spec in pairs(specs) do
        local frame=_G[name]
        if frame and not managed[frame] then
            managed[frame]=spec
            frame:HookScript("OnShow",function() Layout:Apply(frame,spec) end)
            frame:HookScript("OnSizeChanged",function() Layout:Apply(frame,spec) end)
            -- UIPanel and MoveAnything may place/scale after OnShow has fired.
            hooksecurefunc(frame,"SetPoint",function() Layout:Apply(frame,spec) end)
            hooksecurefunc(frame,"SetScale",function() Layout:Apply(frame,spec) end)
            Layout:Apply(frame,spec)
        end
    end
end

local driver=CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("DISPLAY_SIZE_CHANGED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:SetScript("OnEvent",function() discover();Layout:Refresh() end)
local elapsed=0
driver:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt
    if elapsed<.3 then return end
    elapsed=0
    -- Collections can be constructed by the client patch without ADDON_LOADED.
    discover()
    Layout:SpaceBags()
    if Layout.refitCollections and Layout.refitCollections:IsShown() then
        local collections=Layout.refitCollections
        Layout.refitCollections=nil
        -- The client's native refresh preserves the selected display and its skin,
        -- and refits the preview at the now-final viewport size.
        collections:Hide()
        collections:Show()
    end
    if Layout.refitModel and CharacterModelFrame and CharacterModelFrame:IsShown() then
        Layout.refitModel=nil
        local model=CharacterModelFrame
        if addon.ResetModelView then addon:ResetModelView(model) end
        if model.RefreshUnit then model:RefreshUnit() else model:SetUnit("player") end
    end
    local character=_G.CharacterFrame
    if character and character:IsShown() then
        local edge=bagLeftEdge()
        if edge~=Layout.lastBagEdge then
            Layout.lastBagEdge=edge
            Layout:Apply(character,specs.CharacterFrame)
        end
    end
end)
