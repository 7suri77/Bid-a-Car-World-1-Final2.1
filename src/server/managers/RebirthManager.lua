--[[
    RebirthManager.lua
    Purpose: Handle progression milestones and unlocks
    FULLY IMPLEMENTS GAME_ARCHITECTURE Rebirth system
]]

local RebirthManager = {}

local REBIRTH_COSTS = {
    [1] = 2000,
    [2] = 5000,
    [3] = 10000
}

local REBIRTH_UNLOCKS = {
    [1] = { conveyor = true, luckBoosts = 2 },
    [2] = { trading = true },
    [3] = { conveyor = true, world2 = true }
}

--[[
    Check if player can rebirth
    GAME_ARCHITECTURE: "Player has $2000+ → click on rebirth button"
    
    @param playerId: string - Player ID
    @param level: number - Rebirth level (1, 2, 3)
    @return: boolean - Can rebirth
]]
function RebirthManager:CanRebirth(playerId, level)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    -- Check if level is sequential (must do rebirth 1 before 2, etc)
    if player.rebirths.count + 1 ~= level then
        return false
    end
    
    local cost = REBIRTH_COSTS[level]
    if not cost then
        return false
    end
    
    -- Check if player has enough money
    return player.money >= cost
end

--[[
    Execute rebirth
    GAME_ARCHITECTURE: "Money set to $0, Rebirth count +1, Unlock new features, Keep all items/cars/lockers"
    
    @param playerId: string - Player ID
    @param level: number - Rebirth level
    @return: boolean - Success
]]
function RebirthManager:ExecuteRebirth(playerId, level)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local PlotManager = require(script.Parent:WaitForChild("PlotManager"))
    
    if not self:CanRebirth(playerId, level) then
        return false
    end
    
    local player = PlayerDataManager:GetPlayer(playerId)
    if not player then
        return false
    end
    
    local cost = REBIRTH_COSTS[level]
    
    -- GAME_ARCHITECTURE: "Money set to $0 (lose all)"
    player.money = 0
    
    -- GAME_ARCHITECTURE: "Rebirth count +1"
    player.rebirths.count = level
    table.insert(player.rebirths.timestamps, os.time())
    
    -- GAME_ARCHITECTURE: "Unlock new features"
    local unlocks = REBIRTH_UNLOCKS[level]
    if unlocks then
        -- Unlock conveyor(s)
        if unlocks.conveyor then
            PlotManager:UnlockConveyor(playerId)
        end
        
        -- Unlock luck boosts
        if unlocks.luckBoosts then
            self:UnlockFeature(playerId, "luckBoosts")
            if not player.unlockedFeatures then
                player.unlockedFeatures = {}
            end
            player.unlockedFeatures.luckBoostsCount = (player.unlockedFeatures.luckBoostsCount or 0) + unlocks.luckBoosts
        end
        
        -- Unlock trading
        if unlocks.trading then
            self:UnlockFeature(playerId, "trading")
        end
        
        -- Unlock world 2
        if unlocks.world2 then
            self:UnlockFeature(playerId, "world2")
        end
    end
    
    print("[RebirthManager] Player " .. playerId .. " rebirthéd to level " .. level)
    return true
end

--[[
    Unlock a specific feature
    @param playerId: string - Player ID
    @param feature: string - Feature name (trading, world2, luckBoosts, etc)
    @return: boolean - Success
]]
function RebirthManager:UnlockFeature(playerId, feature)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    if not player.unlockedFeatures then
        player.unlockedFeatures = {}
    end
    
    player.unlockedFeatures[feature] = true
    print("[RebirthManager] Unlocked feature: " .. feature .. " for player " .. playerId)
    return true
end

--[[
    Check if feature is unlocked
    @param playerId: string - Player ID
    @param feature: string - Feature name
    @return: boolean - Unlocked status
]]
function RebirthManager:IsFeatureUnlocked(playerId, feature)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return false
    end
    
    if not player.unlockedFeatures then
        return false
    end
    
    return player.unlockedFeatures[feature] or false
end

--[[
    Get rebirth status
    @param playerId: string - Player ID
    @return: table - Rebirth data (count, timestamps, unlocked features)
]]
function RebirthManager:GetRebirthStatus(playerId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return nil
    end
    
    return {
        count = player.rebirths.count,
        timestamps = player.rebirths.timestamps,
        unlockedFeatures = player.unlockedFeatures or {}
    }
end

--[[
    Get next rebirth cost
    @param playerId: string - Player ID
    @return: number - Next cost (or nil if no more rebirths)
]]
function RebirthManager:GetNextRebirthCost(playerId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return nil
    end
    
    local nextLevel = player.rebirths.count + 1
    return REBIRTH_COSTS[nextLevel] or nil
end

--[[
    Get rebirth unlocks for a specific level
    @param level: number - Rebirth level
    @return: table - Unlocks info
]]
function RebirthManager:GetRebirthUnlocks(level)
    if level > 3 then
        return nil
    end
    
    local unlocks = REBIRTH_UNLOCKS[level]
    local details = {
        level = level,
        cost = REBIRTH_COSTS[level],
        unlocks = {}
    }
    
    if unlocks.conveyor then
        table.insert(details.unlocks, "+1 Conveyor")
    end
    if unlocks.luckBoosts then
        table.insert(details.unlocks, "+" .. unlocks.luckBoosts .. " Luck Boosts")
    end
    if unlocks.trading then
        table.insert(details.unlocks, "Trade System")
    end
    if unlocks.world2 then
        table.insert(details.unlocks, "Access to World 2")
    end
    
    return details
end

--[[
    Get all rebirth info for player
    @param playerId: string - Player ID
    @return: table - Complete rebirth data
]]
function RebirthManager:GetRebirthInfo(playerId)
    local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    local player = PlayerDataManager:GetPlayer(playerId)
    
    if not player then
        return nil
    end
    
    local nextLevel = player.rebirths.count + 1
    local nextCost = REBIRTH_COSTS[nextLevel]
    local canRebirth = self:CanRebirth(playerId, nextLevel)
    
    return {
        currentLevel = player.rebirths.count,
        nextLevel = nextLevel,
        nextCost = nextCost,
        currentMoney = player.money,
        canRebirth = canRebirth,
        unlockedFeatures = player.unlockedFeatures or {},
        timestamps = player.rebirths.timestamps
    }
end

return RebirthManager
