--[[
    NPCBidController.lua
    Purpose: AI brain for all bot bidders (shared across all bots)
    FULLY IMPLEMENTS GAME_ARCHITECTURE bot bidding logic
    
    Core Logic:
    - All bots use SINGLE SHARED AI (not individual)
    - Bids range: 35-65% of garage value
    - Each bid: random amount within that range
    - Timing: 1 second between bids (not simultaneous)
    - Stop condition: Random stop between 35-65%
    - BID INCREMENT USES 10% SYSTEM (same as player)
    
    FIXED: garageValue = CarPrice + (DecoCount * 20) - NO LOCKER BONUS (lockers are bonus, not in value calc)
]]

local NPCBidController = {}
local Config = require(script.Parent:WaitForChild("Config"))

--[[
    Calculate total garage value
    GAME_ARCHITECTURE: "garageValue = CarPrice + (DecoCount * 20)"
    NOTE: Lockers are BONUS only, NOT calculated in garageValue
    
    @param garage: table - Garage data
    @return: number - Total value
]]
function NPCBidController:CalculateGarageValue(garage)
    local ItemDatabase = require(script.Parent:WaitForChild("ItemDatabase"))
    
    local carPrice = 0
    if garage.car then
        local carData = ItemDatabase:GetCar(garage.car.id)
        -- Car price estimated as income * 15 (rough market value)
        carPrice = (carData and carData.income * 15) or 100
    end
    
    -- FIXED: Decorations value only (lockers are bonus, not in calculation)
    local decoValue = (garage.decorations and #garage.decorations or 0) * 20
    
    return carPrice + decoValue
end

--[[
    Determine bot bidding range (35-65% of garage value)
    GAME_ARCHITECTURE: "minBid = garageValue * 0.35" and "maxBid = garageValue * 0.65"
    
    @param garageValue: number - Total garage value
    @return: table - Min and max bid amounts
]]
function NPCBidController:DetermineBidRange(garageValue)
    return {
        min = math.floor(garageValue * 0.35),
        max = math.floor(garageValue * 0.65)
    }
end

--[[
    Generate next bot bid (with 10% increment)
    GAME_ARCHITECTURE: "botIncrement = currentBidAmount * 0.10"
    
    @param currentBid: number - Current bid amount
    @return: number - Next bid amount
]]
function NPCBidController:GenerateNextBid(currentBid)
    local increment = math.ceil(currentBid * Config.BID_INCREMENT_PERCENT)
    return currentBid + increment
end

--[[
    Check if bot should continue bidding
    @param currentBid: number - Current bid
    @param stopPoint: number - Bot's stop point
    @return: boolean - Continue status
]]
function NPCBidController:ShouldContinueBidding(currentBid, stopPoint)
    return currentBid < stopPoint
end

--[[
    Execute bot bidding logic (async with delays)
    GAME_ARCHITECTURE: "Timing: 1 second between bids"
    
    Runs bot bidding independently, doesn't block
    Each bot bid comes 1 second apart
    
    @param bidSession: table - Current bid session
    @param botName: string - Bot name
    @param bidId: string - Bid ID
]]
function NPCBidController:ExecuteBotLogicAsync(bidSession, botName, bidId)
    local BidEngine = require(script.Parent:WaitForChild("BidEngine"))
    
    task.spawn(function()
        local garageValue = self:CalculateGarageValue(bidSession.garage)
        local bidRange = self:DetermineBidRange(garageValue)
        
        -- Random stop point between min and max
        local randomStopPoint = math.random(bidRange.min, bidRange.max)
        
        local currentBid = bidSession.currentBid
        
        -- Bot bids until reaching random stop point
        while currentBid < randomStopPoint do
            task.wait(Config.BOT_BID_TIME)  -- 1 second between bids
            
            currentBid = self:GenerateNextBid(currentBid)
            
            -- Submit bid to BidEngine
            BidEngine:BotBid(bidId, botName, currentBid)
            
            if currentBid >= randomStopPoint then
                BidEngine:BotStopBidding(bidId, botName)
                break
            end
        end
    end)
end

--[[
    Get all bot bidding actions (for simulation/planning)
    Used to preview what a bot will do
    
    @param bidSession: table - Current bid session
    @param botName: string - Bot name
    @return: table - Bid actions planned
]]
function NPCBidController:PlanBotActions(bidSession, botName)
    local garageValue = self:CalculateGarageValue(bidSession.garage)
    local bidRange = self:DetermineBidRange(garageValue)
    local randomStopPoint = math.random(bidRange.min, bidRange.max)
    
    local bidActions = {}
    local currentBid = bidSession.currentBid
    
    while currentBid < randomStopPoint do
        currentBid = self:GenerateNextBid(currentBid)
        
        table.insert(bidActions, {
            botName = botName,
            amount = currentBid,
            delay = Config.BOT_BID_TIME
        })
    end
    
    return bidActions
end

return NPCBidController
