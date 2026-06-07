--[[
    PlotManager.lua
    Purpose: Manage player plot, conveyors, and placements (Physical on map)
    FULLY IMPLEMENTS GAME_ARCHITECTURE PlotManager section
]]

local PlotManager = {}
local Config = require(script.Parent:WaitForChild("Config"))

--[[
    Place car on conveyor
    @param playerId: string - Player ID
    @param carId: string - Car ID
    @param conveyorId: string - Conveyor ID
    @return: boolean - Success
]]
function PlotManager:PlaceCar(playerId, carId, conveyorId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local ItemDatabase = require(script.Parent:WaitForChild("ItemDatabase"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    -- Find car in inventory
    local carData = nil
    for _, car in ipairs(player.inventory.cars or {}) do
        if car.id == carId then
            carData = car
            break
        end
    end
    
    if not carData then
        return false
    end
    
    -- Find conveyor and place car
    for _, conveyor in ipairs(player.plot.conveyors) do
        if conveyor.id == conveyorId then
            conveyor.car = {
                id = carData.id,
                income = carData.income,
                boosted = false
            }
            carData.onConveyorId = conveyorId
            return true
        end
    end
    return false
end

--[[
    Place NPC on conveyor (for income boost)
    @param playerId: string - Player ID
    @param npcId: string - NPC ID
    @param conveyorId: string - Conveyor ID
    @return: boolean - Success
]]
function PlotManager:PlaceNPC(playerId, npcId, conveyorId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    -- Find NPC in inventory
    local npcData = nil
    for _, npc in ipairs(player.inventory.dice or {}) do
        if npc.id == npcId then
            npcData = npc
            break
        end
    end
    
    if not npcData then
        return false
    end
    
    -- Find conveyor and place NPC
    for _, conveyor in ipairs(player.plot.conveyors) do
        if conveyor.id == conveyorId then
            conveyor.npc = {
                id = npcData.id,
                boostPercent = npcData.boostPercent or 0
            }
            return true
        end
    end
    return false
end

--[[
    Remove car from conveyor
    @param playerId: string - Player ID
    @param conveyorId: string - Conveyor ID
    @return: boolean - Success
]]
function PlotManager:RemoveCar(playerId, conveyorId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    for _, conveyor in ipairs(player.plot.conveyors) do
        if conveyor.id == conveyorId then
            if conveyor.car then
                -- Find car in inventory and update onConveyorId
                for _, car in ipairs(player.inventory.cars or {}) do
                    if car.id == conveyor.car.id then
                        car.onConveyorId = nil
                        break
                    end
                end
            end
            conveyor.car = nil
            return true
        end
    end
    return false
end

--[[
    Remove NPC from conveyor
    @param playerId: string - Player ID
    @param conveyorId: string - Conveyor ID
    @return: boolean - Success
]]
function PlotManager:RemoveNPC(playerId, conveyorId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    for _, conveyor in ipairs(player.plot.conveyors) do
        if conveyor.id == conveyorId then
            conveyor.npc = nil
            return true
        end
    end
    return false
end

--[[
    Calculate accumulated income for ONE conveyor
    GAME_ARCHITECTURE: Income calculation with NPC boost
    
    @param conveyor: table - Conveyor data
    @return: number - Accumulated income
]]
function PlotManager:CalculateConveyorIncome(conveyor)
    if not conveyor.car then
        return 0
    end
    
    local currentTime = os.time()
    local lastCollected = conveyor.lastCollected or 0
    local timeSinceLastCollect = currentTime - lastCollected
    
    -- Cap at 8 hours offline max (per GAME_ARCHITECTURE)
    local maxOfflineTime = 8 * 60 * 60  -- 8 hours in seconds
    local actualTime = math.min(timeSinceLastCollect, maxOfflineTime)
    
    -- Base income per minute
    local baseIncome = conveyor.car.income or 0
    
    -- NPC boost percentage
    local npcBoost = 0
    if conveyor.npc then
        npcBoost = conveyor.npc.boostPercent or 0
    end
    
    -- Calculate: baseIncome (per minute) converted to per second * boost factor
    -- baseIncome is per minute, so divide by 60 to get per second
    local totalIncomePerSecond = (baseIncome / 60) * (1 + npcBoost / 100)
    
    -- Accumulated = total per second * time in seconds
    local accumulated = math.floor(totalIncomePerSecond * actualTime)
    
    return accumulated
end

--[[
    Collect income from single conveyor
    @param playerId: string - Player ID
    @param conveyorId: string - Conveyor ID
    @return: number - Amount collected
]]
function PlotManager:CollectIncome(playerId, conveyorId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return 0
    end
    
    for _, conveyor in ipairs(player.plot.conveyors) do
        if conveyor.id == conveyorId then
            local accumulated = self:CalculateConveyorIncome(conveyor)
            
            if accumulated > 0 then
                PlayerDataManager:UpdateMoney(playerId, accumulated)
                PlayerDataManager:UpdateStats(playerId, "totalMoneyEarned", accumulated)
            end
            
            conveyor.income_accumulated = 0
            conveyor.lastCollected = os.time()
            
            return accumulated
        end
    end
    return 0
end

--[[
    Collect income from ALL conveyors at once
    @param playerId: string - Player ID
    @return: number - Total amount collected
]]
function PlotManager:CollectAll(playerId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return 0
    end
    
    local totalCollected = 0
    
    for _, conveyor in ipairs(player.plot.conveyors) do
        local accumulated = self:CalculateConveyorIncome(conveyor)
        
        if accumulated > 0 then
            totalCollected = totalCollected + accumulated
            conveyor.income_accumulated = 0
            conveyor.lastCollected = os.time()
        end
    end
    
    if totalCollected > 0 then
        PlayerDataManager:UpdateMoney(playerId, totalCollected)
        PlayerDataManager:UpdateStats(playerId, "totalMoneyEarned", totalCollected)
    end
    
    return totalCollected
end

--[[
    Calculate offline income for player (when joining)
    GAME_ARCHITECTURE: "Calculate time offline (max 8 hours per conveyor)"
    
    @param playerId: string - Player ID
    @return: number - Total offline income
]]
function PlotManager:CalculateOfflineIncome(playerId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return 0
    end
    
    local totalOfflineIncome = 0
    
    for _, conveyor in ipairs(player.plot.conveyors) do
        local conveyorIncome = self:CalculateConveyorIncome(conveyor)
        totalOfflineIncome = totalOfflineIncome + conveyorIncome
        conveyor.lastCollected = os.time()
    end
    
    return totalOfflineIncome
end

--[[
    Add accumulated income to conveyor (for tracking)
    @param playerId: string - Player ID
    @param conveyorId: string - Conveyor ID
    @param amount: number - Amount to add
    @return: boolean - Success
]]
function PlotManager:AddAccumulatedIncome(playerId, conveyorId, amount)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    for _, conveyor in ipairs(player.plot.conveyors) do
        if conveyor.id == conveyorId then
            conveyor.income_accumulated = (conveyor.income_accumulated or 0) + amount
            return true
        end
    end
    return false
end

--[[
    Update income per second for conveyor (recalculate based on car + NPC)
    @param playerId: string - Player ID
    @param conveyorId: string - Conveyor ID
    @return: number - New income per second
]]
function PlotManager:UpdateIncomePerSecond(playerId, conveyorId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return 0
    end
    
    for _, conveyor in ipairs(player.plot.conveyors) do
        if conveyor.id == conveyorId then
            if not conveyor.car then
                return 0
            end
            
            local baseIncome = conveyor.car.income or 0
            local npcBoost = 0
            
            if conveyor.npc then
                npcBoost = conveyor.npc.boostPercent or 0
            end
            
            local incomePerSecond = (baseIncome / 60) * (1 + npcBoost / 100)
            return math.floor(incomePerSecond)
        end
    end
    return 0
end

--[[
    Get plot status
    @param playerId: string - Player ID
    @return: table - Plot data
]]
function PlotManager:GetPlotStatus(playerId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return nil
    end
    
    return player.plot
end

--[[
    Unlock a new conveyor (via rebirth)
    @param playerId: string - Player ID
    @return: boolean - Success
]]
function PlotManager:UnlockConveyor(playerId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    -- Max 6 conveyors total (per GAME_ARCHITECTURE)
    if player.plot.unlockedCount < 6 then
        player.plot.unlockedCount = player.plot.unlockedCount + 1
        
        -- Add new conveyor to list
        local newConveyorId = "conveyor_" .. player.plot.unlockedCount
        table.insert(player.plot.conveyors, {
            id = newConveyorId,
            car = nil,
            npc = nil,
            income_accumulated = 0,
            lastCollected = 0
        })
        
        print("[PlotManager] Unlocked conveyor " .. newConveyorId .. " for player " .. playerId)
        return true
    end
    return false
end

return PlotManager
