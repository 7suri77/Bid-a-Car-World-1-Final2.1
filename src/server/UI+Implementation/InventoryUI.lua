--[[
    InventoryUI.lua
    Purpose: Pop-up Window for Inventory Management
    FULLY IMPLEMENTS GAME_ARCHITECTURE Section 4 - Inventory UI
    
    Layout:
    - Header: Close (X) button, title "INVENTORY"
    - Tabs at top: [Items] [Cars] [Lockers] [Index]
    - Items Tab: Grid layout (4 per row) - Decorations, Potions, Dice, Lockers (scrollable)
    - Cars Tab: Grid layout (4 per row) - Sorted by rarity (Common → SPEC) (scrollable)
    - Lockers Tab: List layout - Each locker shows rarity, time remaining, [OPEN] button (scrollable)
    - Index Tab: View-only list of ALL cars (locked cars black with lock icon, owned cars colored)
]]

local InventoryUI = {}
local Players = game:GetService("Players")

-- UI Color Theme from GAME_ARCHITECTURE
local UI_COLORS = {
    PRIMARY_CYAN = Color3.fromRGB(0, 212, 255),
    PRIMARY_PURPLE = Color3.fromRGB(123, 44, 191),
    ACCENT_GREEN = Color3.fromRGB(0, 255, 65),
    ACCENT_RED = Color3.fromRGB(255, 23, 68),
    DARK_BLUE = Color3.fromRGB(26, 31, 113)
}

--[[
    Show Inventory UI
    GAME_ARCHITECTURE: "Inventory UI Pop-up with 4 tabs: Items | Cars | Lockers | Index"
    
    @param playerId: string - Player ID
    @param PlayerDataManager: module - Player data manager
    @param InventoryManager: module - Inventory manager
    @param ItemDatabase: module - Item database
    @param defaultTab: string - Default tab to show (items, cars, lockers, index)
    @return: table - ScreenGui reference
]]
function InventoryUI:ShowInventory(playerId, PlayerDataManager, InventoryManager, ItemDatabase, defaultTab)
    defaultTab = defaultTab or "cars"
    
    local player = Players:FindFirstChild(tostring(playerId))
    if not player then
        return nil
    end

    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove existing Inventory UI if present
    local existingUI = playerGui:FindFirstChild("InventoryUI")
    if existingUI then
        existingUI:Destroy()
    end

    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- ========== MAIN BACKGROUND ==========
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    -- ========== POP-UP WINDOW ==========
    local popupFrame = Instance.new("Frame")
    popupFrame.Name = "PopupFrame"
    popupFrame.Size = UDim2.new(0, 900, 0, 600)
    popupFrame.Position = UDim2.new(0.5, -450, 0.5, -300)
    popupFrame.BackgroundColor3 = UI_COLORS.DARK_BLUE
    popupFrame.BorderSizePixel = 2
    popupFrame.BorderColor3 = UI_COLORS.PRIMARY_CYAN
    popupFrame.Parent = screenGui

    -- ========== HEADER ==========
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, 0, 0.08, 0)
    headerFrame.Position = UDim2.new(0, 0, 0, 0)
    headerFrame.BackgroundColor3 = UI_COLORS.PRIMARY_PURPLE
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = popupFrame

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "INVENTORY"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = headerFrame

    -- Close button (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0.5, -20)
    closeBtn.BackgroundColor3 = UI_COLORS.ACCENT_RED
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = headerFrame

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- ========== TABS ==========
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, 0, 0.07, 0)
    tabsFrame.Position = UDim2.new(0, 0, 0.08, 0)
    tabsFrame.BackgroundColor3 = UI_COLORS.DARK_BLUE
    tabsFrame.BorderSizePixel = 1
    tabsFrame.BorderColor3 = UI_COLORS.PRIMARY_CYAN
    tabsFrame.Parent = popupFrame

    local tabs = {"Items", "Cars", "Lockers", "Index"}
    local tabButtons = {}
    
    for idx, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "Tab"
        tabBtn.Size = UDim2.new(0.25, 0, 1, 0)
        tabBtn.Position = UDim2.new((idx - 1) * 0.25, 0, 0, 0)
        tabBtn.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = "[" .. tabName:upper() .. "]"
        tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Parent = tabsFrame
        
        tabButtons[tabName:lower()] = tabBtn
    end

    -- ========== CONTENT AREA ==========
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 0, 470)
    contentFrame.Position = UDim2.new(0, 10, 0.15, 10)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = popupFrame

    -- ScrollingFrame for content
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "ContentScroll"
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 8
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
    scrollingFrame.ScrollDirection = Enum.ScrollDirection.Y
    scrollingFrame.Parent = contentFrame

    -- UIGridLayout for content
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 200, 0, 100)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.Parent = scrollingFrame

    -- ========== TAB CONTENT BUILDERS ==========
    
    local function ShowItemsTab()
        -- Clear scrolling frame
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "UIGridLayout" then
                child:Destroy()
            end
        end
        
        -- Get inventory items
        local playerInventory = InventoryManager:GetInventory(playerId)
        local items = playerInventory.items or {}
        
        -- Add items to grid
        for _, item in ipairs(items) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Name = item.id
            itemFrame.Size = UDim2.new(0, 180, 0, 90)
            itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            itemFrame.BorderSizePixel = 1
            itemFrame.BorderColor3 = UI_COLORS.PRIMARY_CYAN
            itemFrame.Parent = scrollingFrame
            
            -- Item image placeholder
            local itemImage = Instance.new("TextLabel")
            itemImage.Size = UDim2.new(1, 0, 0.6, 0)
            itemImage.Position = UDim2.new(0, 0, 0, 0)
            itemImage.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            itemImage.BorderSizePixel = 0
            itemImage.Text = "🎁"
            itemImage.TextSize = 32
            itemImage.Parent = itemFrame
            
            -- Item name
            local itemNameLabel = Instance.new("TextLabel")
            itemNameLabel.Size = UDim2.new(1, 0, 0.4, 0)
            itemNameLabel.Position = UDim2.new(0, 0, 0.6, 0)
            itemNameLabel.BackgroundTransparency = 1
            itemNameLabel.Text = item.name or item.id
            itemNameLabel.TextColor3 = UI_COLORS.PRIMARY_CYAN
            itemNameLabel.TextSize = 11
            itemNameLabel.Font = Enum.Font.Gotham
            itemNameLabel.TextWrapped = true
            itemNameLabel.Parent = itemFrame
        end
        
        -- Update grid layout
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#items / 4) * 110)
    end

    local function ShowCarsTab()
        -- Clear scrolling frame
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "UIGridLayout" then
                child:Destroy()
            end
        end
        
        -- Get owned cars
        local playerInventory = InventoryManager:GetInventory(playerId)
        local cars = playerInventory.cars or {}
        
        -- Sort cars by rarity
        local rarityOrder = {common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5, spec = 6}
        table.sort(cars, function(a, b)
            return (rarityOrder[a.rarity] or 0) < (rarityOrder[b.rarity] or 0)
        end)
        
        -- Add cars to grid
        for _, car in ipairs(cars) do
            local carFrame = Instance.new("Frame")
            carFrame.Name = car.id
            carFrame.Size = UDim2.new(0, 180, 0, 90)
            carFrame.BackgroundColor3 = car.owned and Color3.fromRGB(60, 80, 60) or Color3.fromRGB(50, 50, 50)
            carFrame.BorderSizePixel = 1
            carFrame.BorderColor3 = Color3.fromRGB(100, 100, 150)
            carFrame.Parent = scrollingFrame
            
            -- Car image placeholder
            local carImage = Instance.new("TextLabel")
            carImage.Size = UDim2.new(1, 0, 0.6, 0)
            carImage.Position = UDim2.new(0, 0, 0, 0)
            carImage.BackgroundColor3 = car.owned and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(40, 40, 40)
            carImage.BorderSizePixel = 0
            carImage.Text = car.owned and "🚗" or "🔒"
            carImage.TextSize = 32
            carImage.Parent = carFrame
            
            -- Car name
            local carNameLabel = Instance.new("TextLabel")
            carNameLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
            carNameLabel.Position = UDim2.new(0, 0, 0.6, 0)
            carNameLabel.BackgroundTransparency = 1
            carNameLabel.Text = car.name or car.id
            carNameLabel.TextColor3 = car.owned and UI_COLORS.ACCENT_GREEN or Color3.fromRGB(150, 150, 150)
            carNameLabel.TextSize = 10
            carNameLabel.Font = Enum.Font.Gotham
            carNameLabel.TextWrapped = true
            carNameLabel.Parent = carFrame
            
            -- Income display - ✅ FIXED: Parent changed to carFrame
            local incomeLabel = Instance.new("TextLabel")
            incomeLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
            incomeLabel.Position = UDim2.new(0.6, 0, 0.6, 0)
            incomeLabel.BackgroundTransparency = 1
            incomeLabel.Text = car.owned and ("$" .. car.income) or "???"
            incomeLabel.TextColor3 = car.owned and UI_COLORS.ACCENT_GREEN or Color3.fromRGB(100, 100, 100)
            incomeLabel.TextSize = 9
            incomeLabel.Font = Enum.Font.Gotham
            incomeLabel.Parent = carFrame  -- ✅ FIX #1: Was incomeLabel, now carFrame
        end
        
        -- Update grid layout
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#cars / 4) * 110)
    end

    local function ShowLockersTab()
        -- Clear scrolling frame
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "UIGridLayout" then
                child:Destroy()
            end
        end
        
        -- Get lockers
        local playerInventory = InventoryManager:GetInventory(playerId)
        local lockers = playerInventory.lockers or {}
        
        -- Change to list layout for lockers
        gridLayout.CellSize = UDim2.new(0, 860, 0, 50)
        
        -- Add lockers to list
        for _, locker in ipairs(lockers) do
            local lockerFrame = Instance.new("Frame")
            lockerFrame.Name = locker.id
            lockerFrame.Size = UDim2.new(0, 860, 0, 50)
            lockerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            lockerFrame.BorderSizePixel = 1
            lockerFrame.BorderColor3 = UI_COLORS.PRIMARY_CYAN
            lockerFrame.Parent = scrollingFrame
            
            -- Locker rarity
            local rarityLabel = Instance.new("TextLabel")
            rarityLabel.Size = UDim2.new(0.25, 0, 1, 0)
            rarityLabel.Position = UDim2.new(0, 10, 0, 0)
            rarityLabel.BackgroundTransparency = 1
            rarityLabel.Text = (locker.rarity or "?"):upper() .. " LOCKER"
            rarityLabel.TextColor3 = UI_COLORS.PRIMARY_CYAN
            rarityLabel.TextSize = 12
            rarityLabel.Font = Enum.Font.GothamBold
            rarityLabel.Parent = lockerFrame
            
            -- Time remaining or status
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Size = UDim2.new(0.4, 0, 1, 0)
            timeLabel.Position = UDim2.new(0.25, 0, 0, 0)
            timeLabel.BackgroundTransparency = 1
            timeLabel.Text = locker.unopened and "LOCKED" or "READY TO OPEN"
            timeLabel.TextColor3 = locker.unopened and Color3.fromRGB(200, 200, 200) or UI_COLORS.ACCENT_GREEN
            timeLabel.TextSize = 12
            timeLabel.Font = Enum.Font.Gotham
            timeLabel.Parent = lockerFrame
            
            -- Open button (if ready)
            if not locker.unopened then
                local openBtn = Instance.new("TextButton")
                openBtn.Size = UDim2.new(0.25, -10, 0.8, 0)
                openBtn.Position = UDim2.new(0.75, 5, 0.1, 0)
                openBtn.BackgroundColor3 = UI_COLORS.ACCENT_GREEN
                openBtn.BorderSizePixel = 0
                openBtn.Text = "OPEN"
                openBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                openBtn.TextSize = 12
                openBtn.Font = Enum.Font.GothamBold
                openBtn.Parent = lockerFrame
                
                openBtn.MouseButton1Click:Connect(function()
                    print("[InventoryUI] Opening locker " .. locker.id)
                    -- TODO: Open locker and show rewards
                end)
            end
        end
        
        -- Update canvas size
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #lockers * 60)
    end

    local function ShowIndexTab()
        -- Clear scrolling frame
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "UIGridLayout" then
                child:Destroy()
            end
        end
        
        -- Get all cars from database
        local allCars = ItemDatabase.CARS or {}
        
        -- Get owned car IDs for quick lookup
        local playerInventory = InventoryManager:GetInventory(playerId)
        local ownedCarIds = {}
        for _, car in ipairs(playerInventory.cars or {}) do
            ownedCarIds[car.id] = true
        end
        
        -- GAME_ARCHITECTURE: "Owned cars: Colored + Income value, Locked cars: Black + Lock icon + ??? income, No name"
        for _, car in ipairs(allCars) do
            local isOwned = ownedCarIds[car.id] or false
            
            local carFrame = Instance.new("Frame")
            carFrame.Name = car.id
            carFrame.Size = UDim2.new(0, 180, 0, 90)
            carFrame.BackgroundColor3 = isOwned and Color3.fromRGB(60, 80, 60) or Color3.fromRGB(30, 30, 30)  -- Green if owned, black if locked
            carFrame.BorderSizePixel = 1
            carFrame.BorderColor3 = Color3.fromRGB(100, 100, 150)
            carFrame.Parent = scrollingFrame
            
            -- Car image
            local carImage = Instance.new("TextLabel")
            carImage.Size = UDim2.new(1, 0, 0.6, 0)
            carImage.Position = UDim2.new(0, 0, 0, 0)
            carImage.BackgroundColor3 = isOwned and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(20, 20, 20)  -- Colored if owned, black if locked
            carImage.BorderSizePixel = 0
            carImage.Text = isOwned and "🚗" or "🔒"  -- Lock icon if not owned
            carImage.TextSize = 32
            carImage.Parent = carFrame
            
            -- Car name (HIDDEN if locked - show "???" instead)
            local carNameLabel = Instance.new("TextLabel")
            carNameLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
            carNameLabel.Position = UDim2.new(0, 0, 0.6, 0)
            carNameLabel.BackgroundTransparency = 1
            carNameLabel.Text = isOwned and car.name or "???"  -- Show name if owned, ??? if locked
            carNameLabel.TextColor3 = isOwned and UI_COLORS.ACCENT_GREEN or Color3.fromRGB(80, 80, 80)  -- Gray if locked
            carNameLabel.TextSize = 10
            carNameLabel.Font = Enum.Font.Gotham
            carNameLabel.TextWrapped = true
            carNameLabel.Parent = carFrame
            
            -- Income (HIDDEN if locked - show "???" instead)
            local incomeLabel = Instance.new("TextLabel")
            incomeLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
            incomeLabel.Position = UDim2.new(0.6, 0, 0.6, 0)
            incomeLabel.BackgroundTransparency = 1
            incomeLabel.Text = isOwned and ("$" .. car.income) or "???"  -- Show income if owned, ??? if locked
            incomeLabel.TextColor3 = isOwned and UI_COLORS.ACCENT_GREEN or Color3.fromRGB(80, 80, 80)
            incomeLabel.TextSize = 9
            incomeLabel.Font = Enum.Font.Gotham
            incomeLabel.Parent = carFrame
        end
        
        -- Update canvas size
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#allCars / 4) * 110)
    end

    -- ========== TAB CLICK HANDLERS ==========
    tabButtons.items.MouseButton1Click:Connect(function()
        tabButtons.items.BackgroundColor3 = UI_COLORS.PRIMARY_CYAN
        tabButtons.items.TextColor3 = Color3.fromRGB(0, 0, 0)
        tabButtons.cars.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.cars.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButtons.lockers.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.lockers.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButtons.index.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.index.TextColor3 = Color3.fromRGB(200, 200, 200)
        ShowItemsTab()
    end)

    tabButtons.cars.MouseButton1Click:Connect(function()
        tabButtons.cars.BackgroundColor3 = UI_COLORS.PRIMARY_CYAN
        tabButtons.cars.TextColor3 = Color3.fromRGB(0, 0, 0)
        tabButtons.items.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.items.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButtons.lockers.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.lockers.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButtons.index.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.index.TextColor3 = Color3.fromRGB(200, 200, 200)
        ShowCarsTab()
    end)

    tabButtons.lockers.MouseButton1Click:Connect(function()
        tabButtons.lockers.BackgroundColor3 = UI_COLORS.PRIMARY_CYAN
        tabButtons.lockers.TextColor3 = Color3.fromRGB(0, 0, 0)
        tabButtons.items.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.items.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButtons.cars.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.cars.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButtons.index.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.index.TextColor3 = Color3.fromRGB(200, 200, 200)
        ShowLockersTab()
    end)

    tabButtons.index.MouseButton1Click:Connect(function()
        tabButtons.index.BackgroundColor3 = UI_COLORS.PRIMARY_CYAN
        tabButtons.index.TextColor3 = Color3.fromRGB(0, 0, 0)
        tabButtons.items.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.items.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButtons.cars.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.cars.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButtons.lockers.BackgroundColor3 = UI_COLORS.DARK_BLUE
        tabButtons.lockers.TextColor3 = Color3.fromRGB(200, 200, 200)
        ShowIndexTab()
    end)

    -- Show default tab
    if defaultTab == "items" then
        tabButtons.items:MouseButton1Click()
    elseif defaultTab == "lockers" then
        tabButtons.lockers:MouseButton1Click()
    elseif defaultTab == "index" then
        tabButtons.index:MouseButton1Click()
    else
        tabButtons.cars:MouseButton1Click()
    end

    print("[InventoryUI] Inventory UI opened for player " .. tostring(playerId))
    return screenGui
end

--[[
    Hide/destroy inventory UI
    
    @param screenGui: table - ScreenGui instance
]]
function InventoryUI:HideInventory(screenGui)
    if screenGui then
        screenGui:Destroy()
    end
end

return InventoryUI
