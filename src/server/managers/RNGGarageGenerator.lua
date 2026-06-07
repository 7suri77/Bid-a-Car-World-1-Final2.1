--[[
    RNGGarageGenerator.lua
    Purpose: Create random garages based on tier (ONE physical location, dynamic generation)
    GAME_ARCHITECTURE: "Physical Garage Details - Location: Workspace > Garage"
    NOW INCLUDES: SpawnCarModel() and SpawnDecorationModel() functions
]]

local RNGGarageGenerator = {}

-- Tier specifications per GAME_ARCHITECTURE
local TIER_SPECS = {
    BEGINNER = {
        entryFee = 200,
        carRarities = { common = 1/4, uncommon = 1/5, rare = 1/8 },
        decoRange = { min = 4, max = 7 },
        lockerChance = 1/10
    },
    ADVANCED = {
        entryFee = 500,
        carRarities = { uncommon = 1/8, rare = 1/6, epic = 1/10 },
        decoRange = { min = 7, max = 13 },
        lockerChance = 1/4
    },
    EXPERT = {
        entryFee = 1200,
        carRarities = { rare = 1/10, epic = 1/6, legendary = 1/12, spec = 0.03 },
        decoRange = { min = 13, max = 21 },
        lockerChance = 1/2
    },
    CHOSEN = {
        entryFee = 2500,
        carRarities = { rare = 1/36, epic = 1/24, legendary = 1/8, spec = 0.10 },
        decoRange = { min = 21, max = 50 },
        lockerChance = 1/1
    },
    TIER5 = {
        entryFee = 5000,
        carRarities = { epic = 1/24, legendary = 1/8, spec = 0.25 },
        decoRange = { min = 50, max = 80 },
        lockerChance = 2  -- GAME_ARCHITECTURE: "2x 1/1 (always double)"
    }
}

-- Garage spawn locations per GAME_ARCHITECTURE
local GARAGE_CONFIG = {
    location = workspace:FindFirstChild("Garage") or workspace,
    carSpawnPoint = Vector3.new(0, 0, 0),  -- Center of garage
    decoSpawnRadius = 20,  -- Radius around garage for decorations
}

--[[
    Generate a random garage
    @param tierType: string - Tier type
    @return: table - Generated garage
]]
function RNGGarageGenerator:GenerateGarage(tierType)
    local spec = TIER_SPECS[tierType]
    if not spec then
        error("Unknown tier type: " .. tostring(tierType))
    end
    
    return {
        tier = tierType,
        car = self:GenerateCar(spec.carRarities),
        decorations = self:GenerateDecorations(spec.decoRange),
        lockers = self:GenerateLockers(spec.lockerChance),  -- Changed to lockers (plural)
        generatedAt = os.time()
    }
end

--[[
    Roll car rarity based on tier
    @param rarities: table - Rarity chances
    @return: string - Rarity (common, uncommon, rare, epic, legendary, spec)
]]
function RNGGarageGenerator:RollCarRarity(rarities)
    local roll = math.random()
    local accumulated = 0
    
    for rarity, chance in pairs(rarities) do
        accumulated = accumulated + chance
        if roll <= accumulated then
            return rarity
        end
    end
    
    return "common"  -- Fallback
end

--[[
    Generate a car
    @param rarities: table - Rarity chances
    @return: table - Car data
]]
function RNGGarageGenerator:GenerateCar(rarities)
    local ItemDatabase = require(script.Parent:WaitForChild("ItemDatabase"))
    
    local rarity = self:RollCarRarity(rarities)
    local carsOfRarity = ItemDatabase:GetCarsByRarity(rarity)
    
    if #carsOfRarity == 0 then
        -- Fallback to common car
        carsOfRarity = ItemDatabase:GetCarsByRarity("common")
    end
    
    local selectedCar = carsOfRarity[math.random(1, #carsOfRarity)]
    return {
        id = selectedCar.id,
        name = selectedCar.name,
        rarity = selectedCar.rarity,
        income = selectedCar.income
    }
end

--[[
    Generate decorations
    @param decoRange: table - Min/max count
    @return: table - Decoration list
]]
function RNGGarageGenerator:GenerateDecorations(decoRange)
    local decoCount = math.random(decoRange.min, decoRange.max)
    local decorations = {}
    
    for i = 1, decoCount do
        table.insert(decorations, {
            id = "deco_" .. i,
            name = "#" .. i,
            value = 20,
            index = i
        })
    end
    
    return decorations
end

--[[
    Generate locker(s) based on tier
    GAME_ARCHITECTURE: "TIER5: 2x 1/1 (always double)"
    
    @param lockerChance: number - Chance to get locker
    @return: table - Array of locker data (can be 0, 1, or 2)
]]
function RNGGarageGenerator:GenerateLockers(lockerChance)
    local lockers = {}
    
    -- TIER5 has lockerChance = 2, meaning 2 guaranteed lockers
    if lockerChance == 2 then
        -- Generate 2 lockers for TIER5
        for i = 1, 2 do
            local rarities = { "silver", "gold", "black" }
            local rarity = rarities[math.random(1, 3)]
            
            table.insert(lockers, {
                id = "locker_" .. rarity .. "_" .. os.time() .. "_" .. i,
                rarity = rarity,
                unopened = true,
                contents = self:PopulateLockerContents(rarity)
            })
        end
    else
        -- Other tiers: roll for locker chance
        local roll = math.random()
        
        if roll <= lockerChance then
            local rarities = { "silver", "gold", "black" }
            local rarity = rarities[math.random(1, 3)]
            
            table.insert(lockers, {
                id = "locker_" .. rarity .. "_" .. os.time(),
                rarity = rarity,
                unopened = true,
                contents = self:PopulateLockerContents(rarity)
            })
        end
    end
    
    return lockers
end

--[[
    Populate locker with random contents
    @param rarity: string - Locker rarity
    @return: table - Locker contents
]]
function RNGGarageGenerator:PopulateLockerContents(rarity)
    local ItemDatabase = require(script.Parent:WaitForChild("ItemDatabase"))
    local lockerSpec = ItemDatabase.LOCKER_CONTENTS[rarity]
    
    if not lockerSpec then
        return {}
    end
    
    local contents = {}
    
    -- Add dice
    if math.random() <= lockerSpec.diceChance then
        local diceCount = math.random(lockerSpec.diceCount.min, lockerSpec.diceCount.max)
        for i = 1, diceCount do
            local diceIdx = math.random(1, #ItemDatabase.DICE)
            table.insert(contents, ItemDatabase.DICE[diceIdx])
        end
    end
    
    -- Add potion
    if math.random() <= lockerSpec.potionChance then
        local potionCount = math.random(lockerSpec.potionCount.min, lockerSpec.potionCount.max)
        for i = 1, potionCount do
            local potionIdx = math.random(1, #ItemDatabase.POTIONS)
            table.insert(contents, ItemDatabase.POTIONS[potionIdx])
        end
    end
    
    -- Add decorations
    local decoCount = math.random(lockerSpec.decoCount.min, lockerSpec.decoCount.max)
    for i = 1, decoCount do
        table.insert(contents, {
            id = "deco_" .. math.random(1, 100),
            name = "#" .. math.random(1, 100),
            value = 20,
            type = "decoration"
        })
    end
    
    return contents
end

--[[
    Spawn car model at center of garage
    GAME_ARCHITECTURE: "Spawn car model at center position"
    
    @param carId: string - Car ID
    @param carName: string - Car name (for display)
    @return: table - Model reference (for later cleanup)
]]
function RNGGarageGenerator:SpawnCarModel(carId, carName)
    local garageLocation = GARAGE_CONFIG.location
    if not garageLocation then
        warn("[RNGGarageGenerator] Garage location not found in Workspace")
        return nil
    end
    
    -- Create a placeholder car model (in real game, load from ServerStorage/ReplicatedStorage)
    local carModel = Instance.new("Part")
    carModel.Name = "Car_" .. carId
    carModel.Shape = Enum.PartType.Box
    carModel.Size = Vector3.new(4, 2, 8)
    carModel.Color = Color3.fromRGB(255, 200, 50)  -- Gold color
    carModel.Material = Enum.Material.Neon
    carModel.CanCollide = true
    carModel.CFrame = CFrame.new(GARAGE_CONFIG.carSpawnPoint)
    carModel.Parent = garageLocation
    
    -- Add BillboardGui with car name
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(4, 0, 1, 0)
    billboardGui.MaxDistance = 100
    billboardGui.Parent = carModel
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = carName
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 0
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboardGui
    
    print("[RNGGarageGenerator] Spawned car: " .. carName .. " at garage")
    return carModel
end

--[[
    Spawn decoration model around garage perimeter
    GAME_ARCHITECTURE: "Spawn each decoration model around garage perimeter"
    
    @param decoId: string - Decoration ID
    @param decoIndex: number - Decoration index (#1, #2, etc)
    @return: table - Model reference (for later cleanup)
]]
function RNGGarageGenerator:SpawnDecorationModel(decoId, decoIndex)
    local garageLocation = GARAGE_CONFIG.location
    if not garageLocation then
        warn("[RNGGarageGenerator] Garage location not found in Workspace")
        return nil
    end
    
    -- Random position around garage perimeter
    local angle = math.rad(math.random(0, 360))
    local radius = GARAGE_CONFIG.decoSpawnRadius
    local x = math.cos(angle) * radius
    local z = math.sin(angle) * radius
    local spawnPos = Vector3.new(x, 0, z)
    
    -- Create a placeholder decoration model
    local decoModel = Instance.new("Part")
    decoModel.Name = "Deco_" .. decoId
    decoModel.Shape = Enum.PartType.Ball
    decoModel.Size = Vector3.new(0.5, 0.5, 0.5)
    decoModel.Color = Color3.fromRGB(100, 200, 255)  -- Cyan color
    decoModel.Material = Enum.Material.Neon
    decoModel.CanCollide = false
    decoModel.CFrame = CFrame.new(spawnPos)
    decoModel.Parent = garageLocation
    
    -- Add BillboardGui with decoration number
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(1, 0, 1, 0)
    billboardGui.MaxDistance = 50
    billboardGui.Parent = decoModel
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = "#" .. decoIndex
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboardGui
    
    return decoModel
end

--[[
    Clear previous garage (remove all spawned models)
    GAME_ARCHITECTURE: "Clear previous garage (remove car, decorations, lockers)"
    
    @return: boolean - Success
]]
function RNGGarageGenerator:ClearGarage()
    local garageLocation = GARAGE_CONFIG.location
    if not garageLocation then
        return false
    end
    
    -- Remove all car models
    for _, child in ipairs(garageLocation:GetChildren()) do
        if child.Name:match("^Car_") or child.Name:match("^Deco_") or child.Name:match("^Locker_") then
            child:Destroy()
        end
    end
    
    print("[RNGGarageGenerator] Cleared garage")
    return true
end

return RNGGarageGenerator
