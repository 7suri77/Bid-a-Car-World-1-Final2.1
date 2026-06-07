--[[
    LobbyUI.lua
    Purpose: Main Lobby UI Overlay - Physical World (NO Pop-up)
    FULLY IMPLEMENTS GAME_ARCHITECTURE UI specifications
    
    Layout:
    - Top-right buttons: [Events] [Garage] [Shop]
    - Bottom-right: Wallet Display (live real-time update)
    - Bottom-left: [Inventory] [Settings]
    - Overlay on 3D world (no full-screen pop-up)
]]

local LobbyUI = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- UI Color Theme from GAME_ARCHITECTURE
local UI_COLORS = {
    PRIMARY_CYAN = Color3.fromRGB(0, 212, 255),
    PRIMARY_PURPLE = Color3.fromRGB(123, 44, 191),
    ACCENT_GREEN = Color3.fromRGB(0, 255, 65),
    ACCENT_RED = Color3.fromRGB(255, 23, 68),
    DARK_BLUE = Color3.fromRGB(26, 31, 113)
}

--[[
    Create and show lobby UI for a player
    @param playerId: string - Player ID
    @param PlayerDataManager: module - Player data manager
    @param InventoryManager: module - Inventory manager
    @param ItemDatabase: module - Item database
    @return: table - UI frame reference
]]
function LobbyUI:ShowLobbyUI(playerId, PlayerDataManager, InventoryManager, ItemDatabase)
    local player = Players:FindFirstChild(tostring(playerId))
    if not player then
        return nil
    end

    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove existing lobby UI if present
    local existingUI = playerGui:FindFirstChild("LobbyUI")
    if existingUI then
        existingUI:Destroy()
    end

    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LobbyUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- ========== TOP-RIGHT BUTTONS ==========
    
    -- Events Button (Purple)
    local eventsBtn = self:CreateButton(
        "Events",
        UI_COLORS.PRIMARY_PURPLE,
        UDim2.new(0, 120, 0, 40),
        UDim2.new(1, -130, 0, 10)
    )
    eventsBtn.Parent = screenGui
    
    -- Garage Button (Cyan) - Teleport to Plot
    local garageBtn = self:CreateButton(
        "Garage",
        UI_COLORS.PRIMARY_CYAN,
        UDim2.new(0, 120, 0, 40),
        UDim2.new(1, -260, 0, 10)
    )
    garageBtn.Parent = screenGui
    garageBtn.MouseButton1Click:Connect(function()
        print("[LobbyUI] Garage button clicked for player " .. tostring(playerId))
        -- ✅ TELEPORT TO PLOT (Player's Garage)
        local TeleportManager = require(script.Parent.Parent:WaitForChild("managers"):WaitForChild("TeleportManager"))
        TeleportManager:TeleportToLobby(playerId)  -- This will teleport to PLOT location
    end)
    
    -- Shop Button (Lime Green) - Teleport to Merchant (Dice Shop)
    local shopBtn = self:CreateButton(
        "Shop",
        UI_COLORS.ACCENT_GREEN,
        UDim2.new(0, 120, 0, 40),
        UDim2.new(1, -390, 0, 10)
    )
    shopBtn.Parent = screenGui
    shopBtn.MouseButton1Click:Connect(function()
        print("[LobbyUI] Shop button clicked for player " .. tostring(playerId))
        local TeleportManager = require(script.Parent.Parent:WaitForChild("managers"):WaitForChild("TeleportManager"))
        TeleportManager:TeleportToMerchant(playerId)
    end)

    -- ========== BOTTOM-RIGHT: WALLET DISPLAY ==========
    
    local walletFrame = Instance.new("Frame")
    walletFrame.Name = "WalletDisplay"
    walletFrame.Size = UDim2.new(0, 200, 0, 60)
    walletFrame.Position = UDim2.new(1, -210, 1, -70)
    walletFrame.BackgroundColor3 = UI_COLORS.DARK_BLUE
    walletFrame.BorderSizePixel = 0
    walletFrame.Parent = screenGui
    
    -- Wallet label
    local walletLabel = Instance.new("TextLabel")
    walletLabel.Name = "WalletLabel"
    walletLabel.Size = UDim2.new(1, 0, 0.5, 0)
    walletLabel.Position = UDim2.new(0, 0, 0, 0)
    walletLabel.BackgroundTransparency = 1
    walletLabel.Text = "WALLET"
    walletLabel.TextColor3 = UI_COLORS.PRIMARY_CYAN
    walletLabel.TextSize = 14
    walletLabel.Font = Enum.Font.GothamBold
    walletLabel.Parent = walletFrame
    
    -- Money amount (real-time update)
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Name = "MoneyAmount"
    moneyLabel.Size = UDim2.new(1, 0, 0.5, 0)
    moneyLabel.Position = UDim2.new(0, 0, 0.5, 0)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "$" .. tostring(PlayerDataManager:GetMoney(playerId))
    moneyLabel.TextColor3 = UI_COLORS.ACCENT_GREEN
    moneyLabel.TextSize = 20
    moneyLabel.Font = Enum.Font.GothamBold
    moneyLabel.Parent = walletFrame

    -- ========== BOTTOM-LEFT: INVENTORY & SETTINGS ==========
    
    -- Inventory Button
    local inventoryBtn = self:CreateButton(
        "Inventory",
        UI_COLORS.PRIMARY_CYAN,
        UDim2.new(0, 120, 0, 40),
        UDim2.new(0, 10, 1, -50)
    )
    inventoryBtn.Parent = screenGui
    inventoryBtn.MouseButton1Click:Connect(function()
        print("[LobbyUI] Inventory button clicked for player " .. tostring(playerId))
        local InventoryUI = require(script.Parent:WaitForChild("InventoryUI"))
        -- ✅ FIXED #2: Pass all required parameters (InventoryManager, ItemDatabase)
        InventoryUI:ShowInventory(playerId, PlayerDataManager, InventoryManager, ItemDatabase, "cars")
    end)
    
    -- Settings Button
    local settingsBtn = self:CreateButton(
        "Settings",
        UI_COLORS.DARK_BLUE,
        UDim2.new(0, 120, 0, 40),
        UDim2.new(0, 10, 1, -100)
    )
    settingsBtn.Parent = screenGui

    -- ========== LIVE WALLET UPDATE ==========
    
    -- Create a connection to update wallet in real-time
    task.spawn(function()
        while screenGui and screenGui.Parent do
            local currentMoney = PlayerDataManager:GetMoney(playerId)
            if moneyLabel and moneyLabel.Parent then
                moneyLabel.Text = "$" .. tostring(currentMoney)
            end
            task.wait(0.5)  -- Update every 0.5 seconds
        end
    end)

    print("[LobbyUI] Created lobby UI for player " .. tostring(playerId))
    return screenGui
end

--[[
    Create a standard button with styling
    @param buttonText: string - Button label
    @param backgroundColor: Color3 - Button color
    @param size: UDim2 - Button size
    @param position: UDim2 - Button position
    @return: table - TextButton instance
]]
function LobbyUI:CreateButton(buttonText, backgroundColor, size, position)
    local button = Instance.new("TextButton")
    button.Name = buttonText .. "Button"
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = backgroundColor
    button.BorderSizePixel = 0
    button.Text = buttonText
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 16
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = button.BackgroundColor3:lerp(Color3.fromRGB(255, 255, 255), 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = backgroundColor
    end)
    
    return button
end

--[[
    Update wallet display with new amount
    @param screenGui: table - ScreenGui instance
    @param newAmount: number - New money amount
]]
function LobbyUI:UpdateWalletDisplay(screenGui, newAmount)
    if not screenGui then
        return
    end
    
    local moneyLabel = screenGui:FindFirstChild("WalletDisplay", true)
    if moneyLabel then
        moneyLabel = moneyLabel:FindFirstChild("MoneyAmount")
        if moneyLabel then
            moneyLabel.Text = "$" .. tostring(newAmount)
        end
    end
end

--[[
    Hide/destroy lobby UI
    @param screenGui: table - ScreenGui instance
]]
function LobbyUI:HideLobbyUI(screenGui)
    if screenGui then
        screenGui:Destroy()
    end
end

return LobbyUI
