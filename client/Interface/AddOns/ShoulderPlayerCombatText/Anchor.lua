-- Only the incoming Blizzard/Eclipse-styled CombatText stream is repositioned.
local targetX, targetY, stamp
local records = setmetatable({}, {__mode="k"})
local attached = false
local function same(a,b) return a and b and math.abs(a-b)<0.001 end
local function restore()
 for line,r in pairs(records) do
  local p,rel,rp,x,y=line:GetPoint(1)
  if p==r.p and rel==r.rel and rp==r.rp and same(x,r.wx) and same(y,r.wy) then
   line:SetPoint(r.p,r.rel,r.rp,r.x,r.y)
  end
  records[line]=nil
 end
end
local function live()
 return stamp and GetTime()-stamp>=0 and GetTime()-stamp<0.25
end
local function move(line)
 if not line then return end
 local p,rel,rp,x,y=line:GetPoint(1)
 if p~="TOP" or rel~=WorldFrame or rp~="BOTTOM" or not x or not y then return end
 local r=records[line]
 if r and line.scrollTime==r.time and same(x,r.wx) and same(y,r.wy) then x,y=r.x,r.y end
 local wx=x+(targetX-.5)*WorldFrame:GetWidth()
 local wy=y+(targetY-.5)*WorldFrame:GetHeight()
 records[line]={p=p,rel=rel,rp=rp,x=x,y=y,wx=wx,wy=wy,time=line.scrollTime}
 line:SetPoint(p,rel,rp,wx,wy)
end
local function postUpdate()
 if not live() then restore();return end
 for _,line in ipairs(COMBAT_TEXT_TO_ANIMATE or {}) do move(line) end
end
local function postAdd()
 if not live() then restore();return end
 local list=COMBAT_TEXT_TO_ANIMATE or {}
 move(list[#list])
end
local function attach()
 if attached or not CombatText or type(CombatText_AddMessage)~="function" then return end
 attached=true
 CombatText:HookScript("OnUpdate",postUpdate)
 hooksecurefunc("CombatText_AddMessage",postAdd)
end
function _WXLPlayerCombatTextAnchor_Update(payload)
 local x,y,on=string.match(payload or "","^([^,]+),([^,]+),([01])$")
 x,y=tonumber(x),tonumber(y)
 if on~="1" or not x or not y or x~=x or y~=y or x<0 or x>1 or y<0 or y>1 then
  stamp=nil;restore();return
 end
 targetX,targetY,stamp=x,y,GetTime()
 attach()
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:SetScript("OnEvent",function(self,event)
 if event=="PLAYER_LEAVING_WORLD" then stamp=nil;restore() else attach() end
end)
attach()
