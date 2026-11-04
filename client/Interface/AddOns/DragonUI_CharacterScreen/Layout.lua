-- Pure responsive geometry for DragonUI_CharacterScreen.
-- Kept free of WoW APIs so the layout contract can be audited independently.

local LAYOUT = {
    margin = 12,
    headerHeight = 58,
    footerHeight = 36,
    railRatio = 0.25,
    railMin = 420,
    railMax = 500,
    bagReserve = 240,
    slotSize = 50,
    slotGap = 16,
    equipmentHalfWidth = 340,
    compactEquipmentHalfWidth = 205,
    weaponGap = 16,
    weaponSideGap = 52,
    tabGap = 3,
    columnCount = 8,
    weaponCount = 3,
}

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

function DragonUICharacterScreen_ComputeLayout(width, height)
    width = math.max(1, tonumber(width) or 1)
    height = math.max(1, tonumber(height) or 1)

    local margin = LAYOUT.margin
    local railWidth = clamp(width * LAYOUT.railRatio, LAYOUT.railMin, LAYOUT.railMax)
    -- On very narrow logical canvases, preserving a usable center takes precedence over railMin.
    railWidth = math.min(railWidth, math.max(300, width - LAYOUT.bagReserve - 390))

    -- The world camera centres the player on the screen. Keep the equipment symmetric around that
    -- same axis; centring it in the leftover rail-to-bags space visibly shifted the right column.
    local centerX = width * 0.5
    local wideComposition = width >= 1600
    local requestedHalfWidth = wideComposition and LAYOUT.equipmentHalfWidth
        or LAYOUT.compactEquipmentHalfWidth
    local equipmentHalfWidth = math.min(requestedHalfWidth,
        centerX - LAYOUT.bagReserve - LAYOUT.slotSize - margin)
    equipmentHalfWidth = math.max(150, equipmentHalfWidth)
    local tabWidth = (railWidth - margin * 2 - LAYOUT.tabGap * 3) / 4
    local horizontalWeaponWidth = LAYOUT.slotSize * LAYOUT.weaponCount
        + LAYOUT.weaponGap * (LAYOUT.weaponCount - 1)
    local columnHeight = LAYOUT.slotSize * LAYOUT.columnCount
        + LAYOUT.slotGap * (LAYOUT.columnCount - 1)
    local usableTop = LAYOUT.headerHeight + margin * 2
    local usableBottom = height - LAYOUT.footerHeight - margin
    local columnTop = (usableTop + usableBottom - columnHeight) * 0.5
    local verticalWeaponHeight = LAYOUT.slotSize * LAYOUT.weaponCount
        + LAYOUT.weaponGap * (LAYOUT.weaponCount - 1)
    local leftColumnX = centerX - equipmentHalfWidth
    local weapons
    -- Leave room for the widened feather as well as the paper binding. On an intermediate
    -- canvas the right side has more free space, so keep the vertical tray there instead.
    local weaponFitsBesideSheet = leftColumnX - LAYOUT.slotSize - LAYOUT.weaponSideGap - 22
        >= margin + railWidth
    if wideComposition then
        weapons = {
            x = weaponFitsBesideSheet and (leftColumnX - LAYOUT.slotSize - LAYOUT.weaponSideGap)
                or (centerX + equipmentHalfWidth + LAYOUT.weaponSideGap + 12),
            side = weaponFitsBesideSheet and "left" or "right",
            top = columnTop + (columnHeight - verticalWeaponHeight) * 0.5,
            width = LAYOUT.slotSize,
            height = verticalWeaponHeight,
            vertical = true,
        }
    else
        weapons = {
            x = centerX - horizontalWeaponWidth * 0.5,
            bottom = LAYOUT.footerHeight + margin,
            width = horizontalWeaponWidth,
            height = LAYOUT.slotSize,
            vertical = false,
        }
    end

    return {
        width = width,
        height = height,
        margin = margin,
        header = { x = margin, top = margin, width = width - margin * 2,
                   height = LAYOUT.headerHeight },
        rail = { x = margin, top = LAYOUT.headerHeight + margin * 2,
                 width = railWidth,
                 height = height - LAYOUT.headerHeight - LAYOUT.footerHeight - margin * 3 },
        tabs = { x = margin * 2, bottom = margin, width = tabWidth,
                 height = LAYOUT.footerHeight, gap = LAYOUT.tabGap },
        centerX = centerX,
        leftColumn = { x = leftColumnX, top = columnTop },
        rightColumn = { x = centerX + equipmentHalfWidth - LAYOUT.slotSize,
                        top = columnTop },
        weapons = weapons,
        slotSize = LAYOUT.slotSize,
        slotStep = LAYOUT.slotSize + LAYOUT.slotGap,
        weaponGap = LAYOUT.weaponGap,
        bagReserve = LAYOUT.bagReserve,
        columnCount = LAYOUT.columnCount,
        weaponCount = LAYOUT.weaponCount,
    }
end

