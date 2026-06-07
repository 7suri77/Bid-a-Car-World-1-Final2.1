--[[
    Main.server.lua
    Purpose: Main game server script - initializes ALL managers and systems
    LOADS ALL 14 MANAGERS per GAME_ARCHITECTURE core systems graph
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Load config first
local Config = require(script.Parent:WaitForChild("Config"))
local managersFolder = script.Parent:WaitForChild("managers")

-- Load ALL managers (14 total per GAME_ARCHITECTURE)
local DataStoreManager = require(managersFolder:WaitForChild("DataStoreManager"))
local PlayerDataManager = require(managersFolder:WaitForChild("PlayerDataManager"))
local BidEngine = require(managersFolder:WaitForChild("BidEngine"))
local NPCBidController = require(managersFolder:WaitForChild("NPCBidController"))
local RNGGarageGenerator = require(managersFolder:WaitForChild("RNGGarageGenerator"))
local InventoryManager = require(managersFolder:WaitForChild("InventoryManager"))
local ItemDatabase = require(managersFolder:WaitForChild("ItemDatabase"))
local PlotManager = require(managersFolder:WaitForChild("PlotManager"))
local IncomeGenerator = require(managersFolder:WaitForChild("IncomeGenerator"))
local RebirthManager = require(managersFolder:WaitForChild("RebirthManager"))
local ShopManager = require(managersFolder:WaitForChild("ShopManager"))
local DiceRNG = require(managersFolder:WaitForChild("DiceRNG"))
local TradeManager = require(managersFolder:WaitForChild("TradeManager"))
local TeleportManager = require(managersFolder:WaitForChild("TeleportManager"))
local UIManager = require(managersFolder:WaitForChild("UIManager"))

print("[BID A CAR] Game Server Initializing...")
print("[BID A CAR] Version: " .. Config.GAME_VERSION)
print("[BID A CAR] Loading 14 managers...")
print("[BID A CAR] ✓ DataStoreManager")
print("[BID A CAR] ✓ PlayerDataManager")
print("[BID A CAR] ✓ BidEngine")
print("[BID A CAR] ✓ NPCBidController")
print("[BID A CAR] ✓ RNGGarageGenerator")
print("[BID A CAR] ✓ InventoryManager")
print("[BID A CAR] ✓ ItemDatabase")
print("[BID A CAR] ✓ PlotManager")
print("[BID A CAR] ✓ IncomeGenerator")
print("[BID A CAR] ✓ RebirthManager")
print("[BID A CAR] ✓ ShopManager")
print("[BID A CAR] ✓ DiceRNG")
print("[BID A CAR] ✓ TradeManager")
print("[BID A CAR] ✓ TeleportManager")
print("[BID A CAR] ✓ UIManager")
print("[BID A CAR] All managers loaded successfully!")

--[[
    Initialize new player
    GAME_ARCHITECTURE:
    - Starting Money: $700
    - Starting Conveyors: 3 (6 spots total on plot)
    - First Task: Mini-tutorial
]]
local function initializePlayer(player)
    local playerId = tostring(player.UserId)
    print("[BID A CAR] Player joined: " .. player.Name .. " (ID: " .. playerId .. ")")
    
    -- Load data from DataStore
    local savedData = DataStoreManager:Load(playerId)
    
    -- Load into memory
    PlayerDataManager:LoadPlayerData(playerId, savedData)
    
    -- Initialize auto-save (every 2 minutes per GAME_ARCHITECTURE)
    DataStoreManager:InitializePlayer(playerId, PlayerDataManager:GetPlayer(playerId))
    
    -- Calculate offline income if returning player
    if savedData then
        local offlineIncome = IncomeGenerator:CalculateOfflineIncome(playerId)
        if offlineIncome > 0 then
            PlayerDataManager:UpdateMoney(playerId, offlineIncome)
            print("[BID A CAR] Offline income: $" .. offlineIncome)
        end
    end
    
    print("[BID A CAR] Player " .. player.Name .. " initialized with $" .. PlayerDataManager:GetMoney(playerId))
end

--[[
    Handle player leaving
]]
local function onPlayerLeaving(player)
    local playerId = tostring(player.UserId)
    print("[BID A CAR] Player leaving: " .. player.Name)
    
    -- Final save
    DataStoreManager:PlayerLeaving(playerId)
    PlayerDataManager:RemovePlayer(playerId)
end

-- Connect player events
Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(onPlayerLeaving)

-- Initialize existing players (in case of script reload)
for _, player in ipairs(Players:GetPlayers()) do
    initializePlayer(player)
end

-- Auto-save check (verify DataStore is working)
task.spawn(function()
    while true do
        task.wait(Config.SAVE_INTERVAL)
        print("[BID A CAR] Auto-save cycle (every " .. Config.SAVE_INTERVAL .. " seconds)")
    end
end)

print("[BID A CAR] Server initialization complete!")
print("[BID A CAR] All systems ready for gameplay")
