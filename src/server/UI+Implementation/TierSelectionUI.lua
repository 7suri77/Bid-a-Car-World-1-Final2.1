--[[
    TierSelectionUI.lua
    Purpose: Pop-up Window for Tier Selection (Horizontal Scrollable)
    Opened when player clicks [Garage/BID] button in Lobby
    FULLY IMPLEMENTS GAME_ARCHITECTURE Section 2 - Tier Selection UI
    
    Flow:
    1. Player clicks [Garage] button
    2. TierSelectionUI pop-up opens with 5 tier cards
    3. Player clicks [SELECT] on a tier
    4. Money deducted from wallet
    5. Teleport to RNG Garage
    6. BidEngine starts
]]

local TierSelectionUI = {}
local Players = game:GetService("Players")

-- UI Color Theme from GAME_ARCHITECTURE
local UI_COLORS = {
    PRIMARY_CYAN = Color3.fromRGB(0, 212, 255),
    PRIMARY_PURPLE = Color3.fromRGB(123, 44, 191),
    ACCENT_GREEN = Color3.fromRGB(0, 255, 65),
    ACCENT_RED = Color3.fromRGB(255, 23, 68),
    DARK_BLUE = Color3.fromRGB(26, 31, 113)
}

-- Tier specifications from GAME_ARCHITECTURE
local TIER_DATA = {
    {
        name = "BEGINNER",
        price = 200,
        decoRange = "4-7",
        color = Color3.fromRGB(100, 200, 255)
    },
    {
        name = "ADVANCED",
        price = 500,
        decoRange = "7-13",
        color = Color3.fromRGB(150, 150, 255)
    },
    {
        name = "EXPERT",
        price = 1200,
        decoRange = "13-21",
        color = Color3.fromRGB(200, 100, 255)
    },
    {
        name = "CHOSEN",
        price = 2500,
        decoRange = "21-50",
        color = Color3.fromRGB(255, 100, 200)
    },
    {
        name = "TIER 5",
        price = 5000,
        decoRange = "50-80",
        color = Color3.fromRGB(255, 200, 100)
    }
}

--[[
    Show Tier Selection UI
    GAME_ARCHITECTURE: "Player clicks [Garage] button → TierSelectionUI opens"
    
    @param playerId: string - Player ID
    @param PlayerDataManager: module - Player data manager
    @return: table - ScreenGui reference
]]
function TierSelectionUI:ShowTierSelection(playerId, PlayerDataManager)
    local player = Players:FindFirstChild(tostring(playerId))
    if not player then
        return nil
    end

    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove existing Tier Selection UI if present
    local existingUI = playerGui:FindFirstChild("TierSelectionUI")
    if existingUI then
        existingUI:Destroy()
    end

    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TierSelectionUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- ========== MAIN BACKGROUND ==========
    -- Dark semi-transparent overlay
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
    popupFrame.Size = UDim2.new(0, 1000, 0, 300)
    popupFrame.Position = UDim2.new(0.5, -500, 0.5, -150)
    popupFrame.BackgroundColor3 = UI_COLORS.DARK_BLUE
    popupFrame.BorderSizePixel = 2
    popupFrame.BorderColor3 = UI_COLORS.PRIMARY_CYAN
    popupFrame.Parent = screenGui

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -60, 0, 50)
    titleLabel.Position = UDim2.new(0, 20, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SELECT YOUR BID TIER"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 28
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = popupFrame

    -- ========== CLOSE BUTTON (X) ==========
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.BackgroundColor3 = UI_COLORS.ACCENT_RED
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = popupFrame

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- ========== SCROLL CONTAINER ==========
    local scrollContainer = Instance.new("Frame")
    scrollContainer.Name = "ScrollContainer"
    scrollContainer.Size = UDim2.new(1, -40, 0, 180)
    scrollContainer.Position = UDim2.new(0, 20, 0, 70)
    scrollContainer.BackgroundTransparency = 1
    scrollContainer.BorderSizePixel = 0
    scrollContainer.ClipsDescendants = true
    scrollContainer.Parent = popupFrame

    -- ScrollingFrame for horizontal scroll
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "ScrollingFrame"
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 0
    scrollingFrame.CanvasSize = UDim2.new(0, #TIER_DATA * 180, 0, 0)
    scrollingFrame.ScrollDirection = Enum.ScrollDirection.X
    scrollingFrame.Parent = scrollContainer

    -- UIListLayout for horizontal arrangement
    local listLayout = Instance.new("UIListLayout")
    listLayout.Orientation = Enum.Orientation.Horizontal
    listLayout.Padding = UDim.new(0, 20)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Parent = scrollingFrame

    -- ========== CREATE TIER CARDS ==========
    for tierIndex, tierData in ipairs(TIER_DATA) do
        local tierCard = self:CreateTierCard(
            tierData,
            tierIndex,
            playerId,
            PlayerDataManager,
            screenGui
        )
        tierCard.Parent = scrollingFrame
    end

    -- ========== LEFT/RIGHT ARROW BUTTONS ==========
    
    -- Left Arrow Button
    local leftArrowBtn = Instance.new("TextButton")
    leftArrowBtn.Name = "LeftArrow"
    leftArrowBtn.Size = UDim2.new(0, 40, 0, 40)
    leftArrowBtn.Position = UDim2.new(0, 5, 0.5, -20)
    leftArrowBtn.BackgroundColor3 = UI_COLORS.PRIMARY_CYAN
    leftArrowBtn.BorderSizePixel = 0
    leftArrowBtn.Text = "<"
    leftArrowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    leftArrowBtn.TextSize = 24
    leftArrowBtn.Font = Enum.Font.GothamBold
    leftArrowBtn.Parent = popupFrame
    
    leftArrowBtn.MouseButton1Click:Connect(function()
        scrollingFrame.CanvasPosition = Vector2.new(
            math.max(0, scrollingFrame.CanvasPosition.X - 180),
            0
        )
    end)

    -- Right Arrow Button
    local rightArrowBtn = Instance.new("TextButton")
    rightArrowBtn.Name = "RightArrow"
    rightArrowBtn.Size = UDim2.new(0, 40, 0, 40)
    rightArrowBtn.Position = UDim2.new(1, -45, 0.5, -20)
    rightArrowBtn.BackgroundColor3 = UI_COLORS.PRIMARY_CYAN
    rightArrowBtn.BorderSizePixel = 0
    rightArrowBtn.Text = ">"
    rightArrowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rightArrowBtn.TextSize = 24
    rightArrowBtn.Font = Enum.Font.GothamBold
    rightArrowBtn.Parent = popupFrame
    
    rightArrowBtn.MouseButton1Click:Connect(function()
        scrollingFrame.CanvasPosition = Vector2.new(
            math.min(scrollingFrame.CanvasSize.X.Offset - scrollingFrame.AbsoluteSize.X, 
                     scrollingFrame.CanvasPosition.X + 180),
            0
        )
    end)

    print("[TierSelectionUI] Tier selection UI opened for player " .. tostring(playerId))
    return screenGui
end

--[[
    Create a single tier card
    GAME_ARCHITECTURE: Tier Cards Show:
    - Tier name (large text)
    - Entry price (large cyan text)
    - Estimated decorations range (small text)
    - [SELECT] button on each tier
    
    @param tierData: table - Tier information
    @param tierIndex: number - Index in tier list
    @param playerId: string - Player ID
    @param PlayerDataManager: module - Player data manager
    @param screenGui: table - Parent ScreenGui
    @return: table - Frame instance
]]
function TierSelectionUI:CreateTierCard(tierData, tierIndex, playerId, PlayerDataManager, screenGui)
    local card = Instance.new("Frame")
    card.Name = "TierCard_" .. tierData.name
    card.Size = UDim2.new(0, 160, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    card.BorderSizePixel = 2
    card.BorderColor3 = tierData.color
    card.Parent = nil  -- Will be parented to scrollingFrame

    -- Tier Name
    local tierNameLabel = Instance.new("TextLabel")
    tierNameLabel.Name = "TierName"
    tierNameLabel.Size = UDim2.new(1, 0, 0.25, 0)
    tierNameLabel.Position = UDim2.new(0, 0, 0.05, 0)
    tierNameLabel.BackgroundTransparency = 1
    tierNameLabel.Text = tierData.name
    tierNameLabel.TextColor3 = tierData.color
    tierNameLabel.TextSize = 16
    tierNameLabel.Font = Enum.Font.GothamBold
    tierNameLabel.Parent = card

    -- Entry Price (LARGE CYAN)
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "Price"
    priceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    priceLabel.Position = UDim2.new(0, 0, 0.3, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "$" .. tostring(tierData.price)
    priceLabel.TextColor3 = UI_COLORS.PRIMARY_CYAN
    priceLabel.TextSize = 18
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.Parent = card

    -- Decoration Range (small text)
    local decoLabel = Instance.new("TextLabel")
    decoLabel.Name = "DecoRange"
    decoLabel.Size = UDim2.new(1, 0, 0.15, 0)
    decoLabel.Position = UDim2.new(0, 0, 0.6, 0)
    decoLabel.BackgroundTransparency = 1
    decoLabel.Text = "Decos: " .. tierData.decoRange
    decoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    decoLabel.TextSize = 10
    decoLabel.Font = Enum.Font.Gotham
    decoLabel.Parent = card

    -- SELECT Button
    local selectBtn = Instance.new("TextButton")
    selectBtn.Name = "SelectButton"
    selectBtn.Size = UDim2.new(0.8, 0, 0.2, 0)
    selectBtn.Position = UDim2.new(0.1, 0, 0.8, 0)
    selectBtn.BackgroundColor3 = UI_COLORS.ACCENT_GREEN
    selectBtn.BorderSizePixel = 0
    selectBtn.Text = "SELECT"
    selectBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    selectBtn.TextSize = 12
    selectBtn.Font = Enum.Font.GothamBold
    selectBtn.Parent = card

    -- SELECT button hover effect
    selectBtn.MouseEnter:Connect(function()
        selectBtn.BackgroundColor3 = Color3.fromRGB(150, 255, 150)
    end)

    selectBtn.MouseLeave:Connect(function()
        selectBtn.BackgroundColor3 = UI_COLORS.ACCENT_GREEN
    end)

    -- SELECT button click handler
    selectBtn.MouseButton1Click:Connect(function()
        self:SelectTier(playerId, tierData, PlayerDataManager, screenGui)
    end)

    return card
end

--[[
    Handle tier selection
    GAME_ARCHITECTURE: "Click [SELECT] on tier → Deduct money → Teleport to RNG Garage"
    
    @param playerId: string - Player ID
    @param tierData: table - Selected tier data
    @param PlayerDataManager: module - Player data manager
    @param screenGui: table - UI to close
]]
function TierSelectionUI:SelectTier(playerId, tierData, PlayerDataManager, screenGui)
    local player = PlayerDataManager:GetPlayer(playerId)
    
    -- Check if player has enough money
    if player.money < tierData.price then
        print("[TierSelectionUI] Player " .. tostring(playerId) .. " cannot afford tier " .. tierData.name)
        return
    end

    -- Deduct money
    PlayerDataManager:UpdateMoney(playerId, -tierData.price)
    print("[TierSelectionUI] Deducted $" .. tierData.price .. " from player " .. tostring(playerId))

    -- Close UI
    screenGui:Destroy()

    -- Start bid and teleport to RNG Garage
    local BidEngine = require(script.Parent.Parent:WaitForChild("managers"):WaitForChild("BidEngine"))
    local TeleportManager = require(script.Parent.Parent:WaitForChild("managers"):WaitForChild("TeleportManager"))

    -- Start bid session
    local bidSession = BidEngine:StartBid(playerId, tierData.name, tierData.price)
    
    if bidSession then
        print("[TierSelectionUI] Started bid session for tier " .. tierData.name)
        
        -- Teleport to RNG Garage
        TeleportManager:TeleportToRNGGarage(playerId, tierData.name)
        print("[TierSelectionUI] Teleported player " .. tostring(playerId) .. " to RNG Garage")
    end
end

--[[
    Hide/destroy tier selection UI
    @param screenGui: table - ScreenGui instance
]]
function TierSelectionUI:HideTierSelection(screenGui)
    if screenGui then
        screenGui:Destroy()
    end
end

return TierSelectionUI
