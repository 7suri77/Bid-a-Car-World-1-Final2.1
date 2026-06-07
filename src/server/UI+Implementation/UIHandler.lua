--[[
    UIHandler.lua
    Purpose: Central client-side UI control and management
    Parent: StarterPlayer > StarterPlayerScripts
]]

local UIHandler = {}
local TierSelectionUI = require(script.Parent:WaitForChild("ui"):WaitForChild("TierSelectionUI"))

local activeUIs = {}

--[[
    Initialize UI system
]]
function UIHandler:Initialize()
    print("[UIHandler] Initializing...")
    
    -- Create RemoteEvents listener
    self:SetupRemoteEventListeners()
    
    -- Initialize TierSelectionUI
    TierSelectionUI:Create()
    
    print("[UIHandler] Initialized")
end

--[[
    Setup RemoteEvent listeners for server updates
]]
function UIHandler:SetupRemoteEventListeners()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Create RemoteEvent if not exists
    local UpdateUIEvent = ReplicatedStorage:FindFirstChild("UpdateUI")
    if not UpdateUIEvent then
        UpdateUIEvent = Instance.new("RemoteEvent")
        UpdateUIEvent.Name = "UpdateUI"
        UpdateUIEvent.Parent = ReplicatedStorage
    end
    
    -- Connect to RemoteEvent
    UpdateUIEvent.OnClientEvent:Connect(function(uiType, data)
        self:HandleUIUpdate(uiType, data)
    end)
    
    print("[UIHandler] RemoteEvent listeners setup")
end

--[[
    Handle UI updates from server
]]
function UIHandler:HandleUIUpdate(uiType, data)
    print("[UIHandler] Received update: " .. uiType)
    
    if uiType == "ShowTierSelection" then
        TierSelectionUI:Show()
    elseif uiType == "HideUI" then
        if data.ui == "TierSelection" then
            TierSelectionUI:Hide()
        end
    elseif uiType == "UpdateWallet" then
        self:UpdateWallet(data.amount)
    elseif uiType == "ShowBidUI" then
        self:ShowBidUI(data)
    end
end

--[[
    Update wallet display
]]
function UIHandler:UpdateWallet(amount)
    print("[UIHandler] Wallet updated: $" .. tostring(amount))
    -- Will implement wallet display update
end

--[[
    Show Bid UI
]]
function UIHandler:ShowBidUI(garageInfo)
    print("[UIHandler] Showing Bid UI")
    -- Will implement bid UI
end

-- Initialize on script start
UIHandler:Initialize()

return UIHandler
