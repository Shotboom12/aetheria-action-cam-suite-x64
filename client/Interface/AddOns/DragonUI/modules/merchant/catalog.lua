-- Inventory view only: every entry keeps the original merchant slot identity.
local addon=select(2,...)
local V={}
addon.MerchantCatalog=V
local function key(item,mode)
    if mode=="stock" then return item.index end
    if mode=="name" then return (item.name or ""):lower() end
    if mode=="type" then
        return item.category and (item.category.."\031"..(item.subtype or "")):lower() or nil
    end
    return item[mode]
end
function V.Build(items,filter,mode,descending)
    filter=filter or {};mode=mode or "stock"
    local view={}
    for _,item in ipairs(items) do
        local match=not filter.usable or item.usable
        if filter.category and item.cached then
            match=match and item.category==filter.category
                and (not filter.subtype or item.subtype==filter.subtype)
        end
        if match then view[#view+1]=item end
    end
    table.sort(view,function(a,b)
        local x,y=key(a,mode),key(b,mode)
        -- Unknown metadata always trails known entries, in either direction.
        if x==nil and y~=nil then return false end
        if y==nil and x~=nil then return true end
        if x~=nil and y~=nil and x~=y then
            if descending then return x>y else return x<y end
        end
        local an,bn=(a.name or ""):lower(),(b.name or ""):lower()
        if an~=bn then return an<bn end
        return a.index<b.index
    end)
    return view
end
function V.Page(view,page,size)
    local pages=math.max(1,math.ceil(#view/size))
    page=math.max(1,math.min(tonumber(page) or 1,pages))
    local out={}
    for i=(page-1)*size+1,math.min(page*size,#view) do out[#out+1]=view[i] end
    return out,page,pages
end

-- A two-column row window; entries retain original vendor identity.
function V.Window(view,offset,rows,columns)
    rows=rows or 5;columns=columns or 2
    local maximum=math.max(0,math.ceil(#view/columns)-rows)
    offset=math.max(0,math.min(math.floor(tonumber(offset) or 0),maximum))
    local out={}
    for i=offset*columns+1,math.min(#view,(offset+rows)*columns) do out[#out+1]=view[i] end
    return out,offset,maximum
end
