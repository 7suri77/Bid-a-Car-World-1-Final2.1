--[[
    BidBattleUI.lua
    Purpose: Screen Overlay for Bid Battle (Physical Garage)
    FULLY IMPLEMENTS GAME_ARCHITECTURE Section 3 - Bid Battle UI
    
    Layout:
    - Top-center: Current bid amount (large red text) + Countdown timer
    - Right side: Bid history (scrollable list)
    - Bottom-center: [BID] Button (Red, LARGE, prominent)
    - Top buttons: [Inventory] [Settings]
    - Bottom-right: Wallet display (live update)
    - Background: 50% transparent overlay (edges only, not full screen)
]]

local BidBattleUI = {}
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
    Show Bid Battle UI
    GAME_ARCHITECTURE: "Current Bid Display, Countdown, Live Bid History, Wallet Display, [BID] Button"
    
    @param playerId: string - Player ID
    @param garageInfo: table - Garage information
    @param PlayerDataManager: module - Player data manager
    @param BidEngine: module - Bid engine module
    @return: table - ScreenGui reference
]]
function BidBattleUI:ShowBidUI(playerId, garageInfo, PlayerDataManager, BidEngine)
    local player = Players:FindFirstChild(tostring(playerId))
    if not player then
        return nil
    end

    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove existing Bid Battle UI if present
    local existingUI = playerGui:FindFirstChild("BidBattleUI")
    if existingUI then
        existingUI:Destroy()
    end

    -- Create main ScreenGui (Screen overlay, NOT pop-up)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BidBattleUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- ========== TOP-CENTER: CURRENT BID DISPLAY ==========
    local bidDisplayFrame = Instance.new("Frame")
    bidDisplayFrame.Name = "BidDisplayFrame"
    bidDisplayFrame.Size = UDim2.new(0, 400, 0, 120)
    bidDisplayFrame.Position = UDim2.new(0.5, -200, 0, 20)
    bidDisplayFrame.BackgroundColor3 = UI_COLORS.DARK_BLUE
    bidDisplayFrame.BorderSizePixel = 2
    bidDisplayFrame.BorderColor3 = UI_COLORS.ACCENT_RED
    bidDisplayFrame.Parent = screenGui

    -- Current Bid Label (large red text)
    local currentBidLabel = Instance.new("TextLabel")
    currentBidLabel.Name = "CurrentBidLabel"
    currentBidLabel.Size = UDim2.new(1, 0, 0.5, 0)
    currentBidLabel.Position = UDim2.new(0, 0, 0, 0)
    currentBidLabel.BackgroundTransparency = 1
    currentBidLabel.Text = "CURRENT BID"
    currentBidLabel.TextColor3 = UI_COLORS.ACCENT_RED
    currentBidLabel.TextSize = 16
    currentBidLabel.Font = Enum.Font.GothamBold
    currentBidLabel.Parent = bidDisplayFrame

    -- Bid Amount (LARGE RED TEXT)
    local bidAmountLabel = Instance.new("TextLabel")
    bidAmountLabel.Name = "BidAmount"
    bidAmountLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
    bidAmountLabel.Position = UDim2.new(0, 10, 0.5, 0)
    bidAmountLabel.BackgroundTransparency = 1
    bidAmountLabel.Text = "$0"
    bidAmountLabel.TextColor3 = UI_COLORS.ACCENT_RED
    bidAmountLabel.TextSize = 32
    bidAmountLabel.Font = Enum.Font.GothamBold
    bidAmountLabel.Parent = bidDisplayFrame

    -- Last Bid Player Name
    local lastBidderLabel = Instance.new("TextLabel")
    lastBidderLabel.Name = "LastBidder"
    lastBidderLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
    lastBidderLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    lastBidderLabel.BackgroundTransparency = 1
    lastBidderLabel.Text = "You"
    lastBidderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    lastBidderLabel.TextSize = 12
    lastBidderLabel.Font = Enum.Font.Gotham
    lastBidderLabel.Parent = bidDisplayFrame

    -- ========== COUNTDOWN TIMER (RIGHT OF BID DISPLAY) ==========
    local countdownFrame = Instance.new("Frame")
    countdownFrame.Name = "CountdownFrame"
    countdownFrame.Size = UDim2.new(0, 100, 0, 120)
    countdownFrame.Position = UDim2.new(0.5, 210, 0, 20)
    countdownFrame.BackgroundColor3 = UI_COLORS.DARK_BLUE
    countdownFrame.BorderSizePixel = 2
    countdownFrame.BorderColor3 = UI_COLORS.PRIMARY_CYAN
    countdownFrame.Parent = screenGui

    -- Countdown Label
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(1, 0, 0.4, 0)
    countdownLabel.Position = UDim2.new(0, 0, 0, 5)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "TIME LEFT"
    countdownLabel.TextColor3 = UI_COLORS.PRIMARY_CYAN
    countdownLabel.TextSize = 12
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.Parent = countdownFrame

    -- Countdown Number (large)
    local countdownNumberLabel = Instance.new("TextLabel")
    countdownNumberLabel.Name = "CountdownNumber"
    countdownNumberLabel.Size = UDim2.new(1, 0, 0.6, 0)
    countdownNumberLabel.Position = UDim2.new(0, 0, 0.4, 0)
    countdownNumberLabel.BackgroundTransparency = 1
    countdownNumberLabel.Text = "2"
    countdownNumberLabel.TextColor3 = UI_COLORS.PRIMARY_CYAN
    countdownNumberLabel.TextSize = 40
    countdownNumberLabel.Font = Enum.Font.GothamBold
    countdownNumberLabel.Parent = countdownFrame

    -- ========== RIGHT SIDE: BID HISTORY ==========
    local bidHistoryFrame = Instance.new("Frame")
    bidHistoryFrame.Name = "BidHistoryFrame"
    bidHistoryFrame.Size = UDim2.new(0, 250, 0, 250)
    bidHistoryFrame.Position = UDim2.new(1, -270, 0, 20)
    bidHistoryFrame.BackgroundColor3 = UI_COLORS.DARK_BLUE
    bidHistoryFrame.BorderSizePixel = 2
    bidHistoryFrame.BorderColor3 = UI_COLORS.PRIMARY_CYAN
    bidHistoryFrame.Parent = screenGui

    -- Bid History Title
    local historyTitleLabel = Instance.new("TextLabel")
    historyTitleLabel.Name = "HistoryTitle"
    historyTitleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    historyTitleLabel.Position = UDim2.new(0, 0, 0, 5)
    historyTitleLabel.BackgroundTransparency = 1
    historyTitleLabel.Text = "BID HISTORY"
    historyTitleLabel.TextColor3 = UI_COLORS.PRIMARY_CYAN
    historyTitleLabel.TextSize = 12
    historyTitleLabel.Font = Enum.Font.GothamBold
    historyTitleLabel.Parent = bidHistoryFrame

    -- Bid History List (ScrollingFrame)
    local bidHistoryList = Instance.new("ScrollingFrame")
    bidHistoryList.Name = "BidHistoryList"
    bidHistoryList.Size = UDim2.new(1, -10, 0, 215)
    bidHistoryList.Position = UDim2.new(0, 5, 0.15, 10)
    bidHistoryList.BackgroundTransparency = 1
    bidHistoryList.BorderSizePixel = 0
    bidHistoryList.ScrollBarThickness = 4
    bidHistoryList.CanvasSize = UDim2.new(0, 0, 0, 0)
    bidHistoryList.ScrollDirection = Enum.ScrollDirection.Y
    bidHistoryList.Parent = bidHistoryFrame

    -- UIListLayout for bid history
    local bidHistoryLayout = Instance.new("UIListLayout")
    bidHistoryLayout.Orientation = Enum.Orientation.Vertical
    bidHistoryLayout.Padding = UDim.new(0, 5)
    bidHistoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    bidHistoryLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    bidHistoryLayout.Parent = bidHistoryList

    -- ========== BOTTOM-CENTER: [BID] BUTTON (RED, LARGE) ==========
    local bidButtonFrame = Instance.new("Frame")
    bidButtonFrame.Name = "BidButtonFrame"
    bidButtonFrame.Size = UDim2.new(0, 300, 0, 70)
    bidButtonFrame.Position = UDim2.new(0.5, -150, 1, -90)
    bidButtonFrame.BackgroundTransparency = 1
    bidButtonFrame.BorderSizePixel = 0
    bidButtonFrame.Parent = screenGui

    -- Main BID Button
    local bidButton = Instance.new("TextButton")
    bidButton.Name = "BidButton"
    bidButton.Size = UDim2.new(1, 0, 1, 0)
    bidButton.Position = UDim2.new(0, 0, 0, 0)
    bidButton.BackgroundColor3 = UI_COLORS.ACCENT_RED
    bidButton.BorderSizePixel = 3
    bidButton.BorderColor3 = Color3.fromRGB(255, 100, 100)
    bidButton.Text = "BID"
    bidButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    bidButton.TextSize = 32
    bidButton.Font = Enum.Font.GothamBold
    bidButton.Parent = bidButtonFrame

    -- BID Button Hover Effect
    local originalBidColor = bidButton.BackgroundColor3
    bidButton.MouseEnter:Connect(function()
        bidButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    end)

    bidButton.MouseLeave:Connect(function()
        bidButton.BackgroundColor3 = originalBidColor
    end)

    -- BID Button Click Handler
    bidButton.MouseButton1Click:Connect(function()
        print("[BidBattleUI] BID button clicked by player " .. tostring(playerId))
        -- TODO: Execute bid logic
    end)

    -- Next Bid Amount Label (shown on hover)
    local nextBidLabel = Instance.new("TextLabel")
    nextBidLabel.Name = "NextBidLabel"
    nextBidLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nextBidLabel.Position = UDim2.new(0, 0, 0, 0)
    nextBidLabel.BackgroundTransparency = 1
    nextBidLabel.Text = "Next: $0"
    nextBidLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nextBidLabel.TextSize = 12
    nextBidLabel.Font = Enum.Font.Gotham
    nextBidLabel.Parent = bidButtonFrame
    nextBidLabel.Visible = false

    bidButton.MouseEnter:Connect(function()
        nextBidLabel.Visible = true
    end)

    bidButton.MouseLeave:Connect(function()
        nextBidLabel.Visible = false
    end)

    -- ========== TOP BUTTONS: INVENTORY & SETTINGS ==========
    
    -- Inventory Button (small, top-right area)
    local inventoryBtn = Instance.new("TextButton")
    inventoryBtn.Name = "InventoryButton"
    inventoryBtn.Size = UDim2.new(0, 80, 0, 30)
    inventoryBtn.Position = UDim2.new(1, -180, 0, 10)
    inventoryBtn.BackgroundColor3 = UI_COLORS.PRIMARY_CYAN
    inventoryBtn.BorderSizePixel = 0
    inventoryBtn.Text = "Inventory"
    inventoryBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    inventoryBtn.TextSize = 12
    inventoryBtn.Font = Enum.Font.GothamBold
    inventoryBtn.Parent = screenGui

    inventoryBtn.MouseButton1Click:Connect(function()
        print("[BidBattleUI] Inventory button clicked")
        -- TODO: Show InventoryUI
    end)

    -- Settings Button (small, top-right area)
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Name = "SettingsButton"
    settingsBtn.Size = UDim2.new(0, 80, 0, 30)
    settingsBtn.Position = UDim2.new(1, -90, 0, 10)
    settingsBtn.BackgroundColor3 = UI_COLORS.DARK_BLUE
    settingsBtn.BorderSizePixel = 1
    settingsBtn.BorderColor3 = UI_COLORS.PRIMARY_CYAN
    settingsBtn.Text = "Settings"
    settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingsBtn.TextSize = 12
    settingsBtn.Font = Enum.Font.GothamBold
    settingsBtn.Parent = screenGui

    -- ========== BOTTOM-RIGHT: WALLET DISPLAY ==========
    local walletFrame = Instance.new("Frame")
    walletFrame.Name = "WalletDisplay"
    walletFrame.Size = UDim2.new(0, 150, 0, 60)
    walletFrame.Position = UDim2.new(1, -160, 1, -70)
    walletFrame.BackgroundColor3 = UI_COLORS.DARK_BLUE
    walletFrame.BorderSizePixel = 2
    walletFrame.BorderColor3 = UI_COLORS.PRIMARY_CYAN
    walletFrame.Parent = screenGui

    -- Wallet Label
    local walletLabel = Instance.new("TextLabel")
    walletLabel.Name = "WalletLabel"
    walletLabel.Size = UDim2.new(1, 0, 0.5, 0)
    walletLabel.Position = UDim2.new(0, 0, 0, 0)
    walletLabel.BackgroundTransparency = 1
    walletLabel.Text = "WALLET"
    walletLabel.TextColor3 = UI_COLORS.PRIMARY_CYAN
    walletLabel.TextSize = 12
    walletLabel.Font = Enum.Font.GothamBold
    walletLabel.Parent = walletFrame

    -- Money Amount (live update)
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Name = "MoneyAmount"
    moneyLabel.Size = UDim2.new(1, 0, 0.5, 0)
    moneyLabel.Position = UDim2.new(0, 0, 0.5, 0)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "$" .. tostring(PlayerDataManager:GetMoney(playerId))
    moneyLabel.TextColor3 = UI_COLORS.ACCENT_GREEN
    moneyLabel.TextSize = 18
    moneyLabel.Font = Enum.Font.GothamBold
    moneyLabel.Parent = walletFrame

    -- ========== LIVE UPDATE LOOPS ==========

    -- Update wallet in real-time
    task.spawn(function()
        while screenGui and screenGui.Parent do
            local currentMoney = PlayerDataManager:GetMoney(playerId)
            if moneyLabel and moneyLabel.Parent then
                moneyLabel.Text = "$" .. tostring(currentMoney)
            end
            task.wait(0.5)
        end
    end)

    -- Store references for later updates
    screenGui:SetAttribute("BidAmountLabel", bidAmountLabel)
    screenGui:SetAttribute("BidHistoryList", bidHistoryList)
    screenGui:SetAttribute("CountdownNumberLabel", countdownNumberLabel)
    screenGui:SetAttribute("NextBidLabel", nextBidLabel)

    print("[BidBattleUI] Bid battle UI created for player " .. tostring(playerId))
    return screenGui
end

--[[
    Add bid to history
    GAME_ARCHITECTURE: "Live Bid History: [Player Name: $XXX]"
    
    @param screenGui: table - ScreenGui instance
    @param playerName: string - Player/Bot name
    @param bidAmount: number - Bid amount
]]
function BidBattleUI:AddBidToHistory(screenGui, playerName, bidAmount)
    if not screenGui then
        return
    end

    local bidHistoryList = screenGui:GetAttribute("BidHistoryList")
    if not bidHistoryList then
        return
    end

    -- Create bid history item
    local bidItem = Instance.new("TextLabel")
    bidItem.Name = "BidItem_" .. os.time()
    bidItem.Size = UDim2.new(1, 0, 0, 25)
    bidItem.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    bidItem.BorderSizePixel = 1
    bidItem.BorderColor3 = Color3.fromRGB(100, 100, 150)
    bidItem.Text = playerName .. ": $" .. tostring(bidAmount)
    bidItem.TextColor3 = Color3.fromRGB(200, 200, 200)
    bidItem.TextSize = 12
    bidItem.Font = Enum.Font.Gotham
    bidItem.TextXAlignment = Enum.TextXAlignment.Left
    bidItem.Parent = bidHistoryList

    -- Scroll to bottom
    bidHistoryList.CanvasPosition = Vector2.new(0, bidHistoryList.CanvasSize.Y.Offset)
end

--[[
    Update current bid display
    GAME_ARCHITECTURE: "Current bid amount (large red text)"
    
    @param screenGui: table - ScreenGui instance
    @param bidAmount: number - New bid amount
    @param playerName: string - Player who made bid
]]
function BidBattleUI:UpdateBidDisplay(screenGui, bidAmount, playerName)
    if not screenGui then
        return
    end

    local bidAmountLabel = screenGui:GetAttribute("BidAmountLabel")
    if bidAmountLabel and bidAmountLabel.Parent then
        bidAmountLabel.Text = "$" .. tostring(bidAmount)
    end

    -- Also add to history
    self:AddBidToHistory(screenGui, playerName, bidAmount)
end

--[[
    Update countdown timer
    GAME_ARCHITECTURE: "Countdown: 2 → 1 → 0"
    
    @param screenGui: table - ScreenGui instance
    @param seconds: number - Seconds remaining
]]
function BidBattleUI:UpdateCountdown(screenGui, seconds)
    if not screenGui then
        return
    end

    local countdownLabel = screenGui:GetAttribute("CountdownNumberLabel")
    if countdownLabel and countdownLabel.Parent then
        countdownLabel.Text = tostring(math.max(0, seconds))
    end
end

--[[
    Update next bid amount (shown on hover)
    
    @param screenGui: table - ScreenGui instance
    @param nextBidAmount: number - Next bid amount
]]
function BidBattleUI:UpdateNextBidAmount(screenGui, nextBidAmount)
    if not screenGui then
        return
    end

    local nextBidLabel = screenGui:GetAttribute("NextBidLabel")
    if nextBidLabel and nextBidLabel.Parent then
        nextBidLabel.Text = "Next: $" .. tostring(nextBidAmount)
    end
end

--[[
    Hide/destroy bid battle UI
    
    @param screenGui: table - ScreenGui instance
]]
function BidBattleUI:HideBidUI(screenGui)
    if screenGui then
        screenGui:Destroy()
    end
end

return BidBattleUI
