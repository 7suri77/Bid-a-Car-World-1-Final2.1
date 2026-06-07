--[[
    BidEngine.lua
    Purpose: Control entire bid battle flow
    Manages bidding mechanics, 10% increment system, winner calculation
    FULLY IMPLEMENTS GAME_ARCHITECTURE bidding flow
]]

local BidEngine = {}
local activeBids = {}
local Config = require(script.Parent:WaitForChild("Config"))

--[[
    Start a new bid session
    GAME_ARCHITECTURE Flow:
    1. Player selects tier → Teleport to RNG Garage
    2. RNG Garage generated
    3. 3 random bots selected
    4. Set starting bid price (tier-based)
    5. Start bidding phase (2 sec player, 1 sec bots)
    
    @param playerId: string - Player ID
    @param tierType: string - Bid tier (BEGINNER, ADVANCED, etc)
    @param entryFee: number - Entry fee amount
    @return: table - Bid session data
]]
function BidEngine:StartBid(playerId, tierType, entryFee)
    local RNGGarageGenerator = require(script.Parent:WaitForChild("RNGGarageGenerator"))
    local ItemDatabase = require(script.Parent:WaitForChild("ItemDatabase"))
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    
    -- Deduct entry fee from player
    PlayerDataManager:UpdateMoney(playerId, -entryFee)
    PlayerDataManager:UpdateStats(playerId, "totalMoneySpent", entryFee)
    PlayerDataManager:UpdateStats(playerId, "totalBidsParticipated", 1)
    
    local bidId = "bid_" .. playerId .. "_" .. os.time()
    local garage = RNGGarageGenerator:GenerateGarage(tierType)
    local bots = ItemDatabase:GetRandomBots()
    
    local bidSession = {
        id = bidId,
        playerId = playerId,
        tierType = tierType,
        entryFee = entryFee,
        garage = garage,
        bots = bots,
        state = "WAITING",
        currentBid = 0,
        nextBidAmount = 0,
        biddingHistory = {},
        playerBids = { [playerId] = 0 },
        botBids = {},
        activeBidders = { [playerId] = true },
        startTime = os.time(),
        bidCountdown = 2,
        roundCount = 0,
        maxRounds = 50  -- Safety limit
    }
    
    -- Initialize bot bids and bidders
    for _, botName in ipairs(bots) do
        bidSession.botBids[botName] = 0
        bidSession.activeBidders[botName] = true
    end
    
    activeBids[bidId] = bidSession
    
    print("[BidEngine] Started bid session: " .. bidId .. " for player " .. playerId .. " in tier " .. tierType)
    return bidSession
end

--[[
    Set initial bid amount (tier-based starting price)
    GAME_ARCHITECTURE: "Set starting bid price (tier-based)"
    
    @param bidId: string - Bid session ID
    @param startingPrice: number - Initial bid amount
]]
function BidEngine:SetStartingBid(bidId, startingPrice)
    local bid = activeBids[bidId]
    if not bid then
        return false
    end
    
    bid.currentBid = startingPrice or 0
    bid.nextBidAmount = math.ceil(startingPrice * (1 + Config.BID_INCREMENT_PERCENT))
    bid.state = "BIDDING"
    
    table.insert(bid.biddingHistory, {
        player = "SYSTEM",
        amount = startingPrice,
        time = os.time(),
        description = "Starting bid"
    })
    
    return true
end

--[[
    Player places a bid (10% increment system)
    GAME_ARCHITECTURE: "Bid raise with 10% of CURRENT BID VALUE"
    Example: Current bid $300 → Next raise is $300 * 0.10 = $30 → New bid $330
    
    @param bidId: string - Bid session ID
    @param playerId: string - Player ID
    @param bidAmount: number - Amount to bid
    @return: boolean - Success status
]]
function BidEngine:PlayerBid(bidId, playerId, bidAmount)
    local bid = activeBids[bidId]
    if not bid then
        return false
    end
    
    if bid.playerBids[playerId] == nil then
        return false  -- Player not in this bid
    end
    
    -- Validate bid amount (must be 10% increment of current bid)
    local expectedNewBid = bid.nextBidAmount
    
    if bidAmount ~= expectedNewBid then
        print("[BidEngine] Invalid bid: expected " .. expectedNewBid .. " but got " .. bidAmount)
        return false
    end
    
    -- Check player has enough money
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local playerMoney = PlayerDataManager:GetMoney(playerId)
    
    if playerMoney < bidAmount then
        return false
    end
    
    bid.currentBid = bidAmount
    bid.playerBids[playerId] = bidAmount
    bid.nextBidAmount = math.ceil(bidAmount * (1 + Config.BID_INCREMENT_PERCENT))
    
    table.insert(bid.biddingHistory, {
        player = playerId,
        amount = bidAmount,
        time = os.time()
    })
    
    PlayerDataManager:UpdateStats(playerId, "totalMoneySpent", bidAmount - (bid.playerBids[playerId] or 0))
    
    print("[BidEngine] Player bid: " .. bidAmount .. " in session " .. bidId)
    return true
end

--[[
    Bot places a bid (10% increment system)
    Called by NPCBidController
    
    @param bidId: string - Bid session ID
    @param botName: string - Bot name
    @param bidAmount: number - Amount to bid
]]
function BidEngine:BotBid(bidId, botName, bidAmount)
    local bid = activeBids[bidId]
    if not bid then
        return false
    end
    
    if bid.botBids[botName] == nil then
        return false  -- Bot not in this bid
    end
    
    bid.currentBid = bidAmount
    bid.botBids[botName] = bidAmount
    bid.nextBidAmount = math.ceil(bidAmount * (1 + Config.BID_INCREMENT_PERCENT))
    
    table.insert(bid.biddingHistory, {
        player = botName,
        amount = bidAmount,
        time = os.time()
    })
    
    print("[BidEngine] Bot bid: " .. botName .. " bids " .. bidAmount)
    return true
end

--[[
    Set bot as inactive (stops bidding)
    
    @param bidId: string - Bid session ID
    @param botName: string - Bot name
]]
function BidEngine:BotStopBidding(bidId, botName)
    local bid = activeBids[bidId]
    if not bid then
        return false
    end
    
    bid.activeBidders[botName] = false
    print("[BidEngine] Bot stopped bidding: " .. botName)
    return true
end

--[[
    Calculate bid winner
    GAME_ARCHITECTURE: "Calculate winner (highest bid)"
    
    @param bidId: string - Bid session ID
    @return: string - Winner (playerId or botName)
]]
function BidEngine:CalculateWinner(bidId)
    local bid = activeBids[bidId]
    if not bid then
        return nil
    end
    
    local maxBid = 0
    local winner = nil
    
    -- Check player bid
    if bid.playerBids[bid.playerId] and bid.playerBids[bid.playerId] > maxBid then
        maxBid = bid.playerBids[bid.playerId]
        winner = bid.playerId
    end
    
    -- Check bot bids
    for botName, amount in pairs(bid.botBids) do
        if amount > maxBid then
            maxBid = amount
            winner = botName
        end
    end
    
    print("[BidEngine] Winner calculated: " .. tostring(winner) .. " with bid $" .. maxBid)
    return winner
end

--[[
    Settle a win (player wins the bid)
    GAME_ARCHITECTURE: "Winner selection phase (0-2 decorations can be selected)"
    
    @param bidId: string - Bid session ID
    @param playerId: string - Player ID
    @return: table - Garage contents (car, decorations, locker)
]]
function BidEngine:SettleWin(bidId, playerId)
    local bid = activeBids[bidId]
    if not bid then
        return nil
    end
    
    local InventoryManager = require(script.Parent:WaitForChild("InventoryManager"))
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    
    -- Add car to inventory
    if bid.garage.car then
        local carItem = {
            id = bid.garage.car.id,
            type = "car",
            name = bid.garage.car.name,
            rarity = bid.garage.car.rarity,
            income = bid.garage.car.income,
            owned = true,
            acquiredAt = os.time()
        }
        InventoryManager:AddItem(playerId, "cars", carItem)
    end
    
    -- Add locker to inventory if exists
    if bid.garage.locker then
        InventoryManager:AddItem(playerId, "lockers", bid.garage.locker)
    end
    
    -- Decorations will be selected by player in UI (0-2)
    local rewards = {
        car = bid.garage.car,
        decorations = bid.garage.decorations,  -- All available, player selects 0-2
        locker = bid.garage.locker,
        bidAmount = bid.currentBid
    }
    
    -- Update stats
    PlayerDataManager:UpdateStats(playerId, "totalBidsWon", 1)
    PlayerDataManager:UpdateStats(playerId, "totalMoneyEarned", 0)  -- No immediate earning, decorations are $20 each
    
    bid.state = "COMPLETED"
    activeBids[bidId] = nil
    
    print("[BidEngine] Player won! Settled win for " .. playerId)
    return rewards
end

--[[
    Settle a loss (player loses the bid)
    GAME_ARCHITECTURE: "Loser handling (money lost)"
    - If no bids: refund entry fee
    - If bidded: lose all bid money
    
    @param bidId: string - Bid session ID
    @param playerId: string - Player ID
    @return: table - Loss info
]]
function BidEngine:SettleLoss(bidId, playerId)
    local bid = activeBids[bidId]
    if not bid then
        return false
    end
    
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    
    -- Check if player made any bids
    local playerBid = bid.playerBids[playerId] or 0
    
    if playerBid == 0 then
        -- No bid made - refund entry fee
        PlayerDataManager:UpdateMoney(playerId, bid.entryFee)
        print("[BidEngine] No bid made - refunded entry fee $" .. bid.entryFee)
    else
        -- Bid made - lose all bid money (already deducted, just don't refund)
        print("[BidEngine] Player lost bid $" .. playerBid)
    end
    
    -- Update stats
    PlayerDataManager:UpdateStats(playerId, "totalBidsLost", 1)
    
    bid.state = "COMPLETED"
    activeBids[bidId] = nil
    
    return {
        playerBid = playerBid,
        entryFee = bid.entryFee,
        moneyLost = playerBid
    }
end

--[[
    Player selects decorations after winning
    GAME_ARCHITECTURE: "Winner selection phase (0-2 decorations can be selected)"
    
    @param bidId: string - Bid session ID
    @param playerId: string - Player ID
    @param decorationIds: table - Array of decoration IDs (max 2)
    @return: boolean - Success
]]
function BidEngine:SelectDecorations(bidId, playerId, decorationIds)
    local InventoryManager = require(script.Parent:WaitForChild("InventoryManager"))
    
    if not decorationIds or #decorationIds > 2 then
        return false
    end
    
    for _, decoId in ipairs(decorationIds) do
        local decoration = {
            id = "deco_" .. decoId,
            type = "decoration",
            name = "#" .. decoId,
            value = 20,
            rarity = "common",
            acquiredAt = os.time()
        }
        InventoryManager:AddItem(playerId, "items", decoration)
    end
    
    print("[BidEngine] Player selected " .. #decorationIds .. " decorations")
    return true
end

--[[
    Get active bid session
    @param bidId: string - Bid session ID
    @return: table - Bid session data
]]
function BidEngine:GetBid(bidId)
    return activeBids[bidId]
end

--[[
    Get all active bids (for debugging)
    @return: table - All active bid sessions
]]
function BidEngine:GetActiveBids()
    return activeBids
end

--[[
    Check if any active bidders remain
    @param bidId: string - Bid session ID
    @return: boolean - True if someone is still bidding
]]
function BidEngine:HasActiveBidders(bidId)
    local bid = activeBids[bidId]
    if not bid then
        return false
    end
    
    for _, isActive in pairs(bid.activeBidders) do
        if isActive then
            return true
        end
    end
    
    return false
end

return BidEngine
