# 🎮 BID A CAR (WORLD 1) - GAME ARCHITECTURE SCHEMA

**Game Type:** Roblox Bid Battle Simulator with RNG Garages & Progression  
**Status:** Development from scratch  
**Date Created:** May 19, 2026  
**Last Updated:** June 12, 2026

---

## 📋 TABLE OF CONTENTS

1. [Game Overview](#game-overview)
2. [Game Flow & Player Journey](#game-flow--player-journey)
3. [Core Systems Architecture](#core-systems-architecture)
4. [Manager Breakdown](#manager-breakdown)
5. [DataStore Structure](#datastore-structure)
6. [UI/UX Wireframes](#uiux-wireframes)
7. [Folder Structure](#folder-structure)
8. [Bid Mechanics Deep Dive](#bid-mechanics-deep-dive)
9. [Item System](#item-system)
10. [Progression & Rebirths](#progression--rebirths)
11. [Complete Car Index](#complete-car-index)
12. [NPC & Decoration Details](#npc--decoration-details)
13. [Locker Contents](#locker-contents)

---

## 🎯 GAME OVERVIEW

### What is Bid A Car?
A Roblox game where players engage in **bid battles** to win RNG garages containing:
- **Random Rarity Cars** (Common → Rare → Epic → Legendary → SPEC)
- **Decorations** (#1-#N, $20 value each, 4-50 per garage based on tier)
- **Lockers** (time-locked containers with dice & potions)
- **NPCs** (from Dice Shop, provide income boosts on conveyors)

### Core Loop
```
Player → Select Bid Tier → Enter Bid Battle → Win/Lose → Collect Rewards → 
Place on Plot → Generate Income → Rebirth → Unlock World 2
```

### Start State
- **Starting Money:** $700
- **Starting Conveyors:** 3 (6 spots total on plot)
- **First Task:** Mini-tutorial (cursor guides click BID → BEGINNER) → Game starts

---

## 🎬 GAME FLOW & PLAYER JOURNEY

```
┌────────────────────────────────────────────────────────────────┐
│                    GAME START (New Player)                     │
└─────────────────────────────┬────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Mini Tutorial   │
                    │ Cursor clicks:   │
                    │ 1. [BID] button  │
                    │ 2. [BEGINNER]    │
                    │ Duration: <1 min │
                    │ Mandatory        │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────────────────────────┐
                    │  MAIN LOBBY (Physical World)         │
                    │  3D Walking Area + Screen Overlay    │
                    │  9 UI Buttons distributed            │
                    │  $700 in pocket (top-right display)  │
                    │  WASD Movement enabled               │
                    └────────┬──────────────────────────────┘
                             │
        ┌────────────┬────────────────┬────────────────────┐
        │            │                │                    │
    [TOP ROW]    [TOP ROW]        [TOP ROW]         [WALLET]
    [Events]     [Garage]         [Shop]            $700
    (Purple)     (Cyan) ◄─────    (Green)           (Top-Right)
                      │
         [BID TOP-LEFT] │ [BID BOTTOM-CENTER] ◄───┐
         [Settings]     │      (Green)              │
         (Gear)         │                           │
                        ▼                           │
              ┌──────────────────────┐              │
              │ TierSelectionUI      │              │
              │ (Pop-up, Horizontal) │              │
              │                      │              │
              │ [BEGINNER][ADVANCED] │              │
              │ [EXPERT][CHOSEN]     │              │
              │ [TIER 5] (scroll)    │              │
              │                      │              │
              └────────┬─────────────┘              │
                       │                            │
                    Click Tier                      │
                       │                            │
                       ▼ (Deduct Money + Teleport) │
              ┌──────────────────────┐              │
              │  RNG GARAGE          │              │
              │  (Bid Battle Arena)  │              │
              │  PHYSICALLY ON MAP   │              │
              │                      │              │
              │  Player + 3 Bots     │              │
              │  Standing on yellow  │              │
              │  platform            │              │
              │                      │              │
              │  RNG GENERATED:      │              │
              │  - 1 Car             │              │
              │  - Decorations       │              │
              │  - Locker (chance)   │              │
              │                      │              │
              │  [BID] Button        │              │
              │  Live Bid Display    │              │
              │  Countdown Timer     │              │
              └────────┬─────────────┘              │
                       │                            │
                ┌──────┴──────┐                     │
                ▼             ▼                     │
              WIN           LOSS                    │
               │              │                     │
               ▼              ▼                     │
        ┌─────────────┐  ┌──────────────┐          │
        │ Selection   │  │ Money Lost   │          │
        │ 0-2 Deco    │  │ (if bid)     │          │
        │ Auto-sell   │  │ Refund entry │          │
        │ Lockers     │  │ (if no bid)  │          │
        └────┬────────┘  └──────┬───────┘          │
             │                  │                   │
             └──────┬───────────┘                   │
                    ▼ (Teleport back to Lobby)     │
            ┌──────────────────────┐               │
            │ Back to MAIN LOBBY   │               │
            │ Inventory Updated    │               │
            │ Income Ready         │               │
            └────────┬─────────────┘               │
                     │                              │
        ┌────────────┼────────────┬────────────┐   │
        │            │            │            │   │
    [Inventory]  [Place Car]  [Rebirth]  [To Shop]─┘
    Button       UI           Button      Button
    (Bottom-L)                (Bottom-R)  (Top-R:Green)
        │            │            │
        ▼            ▼            ▼
    [Inv UI]    [PlotUI]    [Rebirth Check]
    Pop-up      Physical    Pop-up
               on Map
```

---

## 🏗️ CORE SYSTEMS ARCHITECTURE

### System Dependencies Graph
```
DataStoreManager (Foundation - Saves Everything)
      │
      ├─→ PlayerDataManager (Player State)
      │
      ├─→ BidEngine (Bid Battle Logic)
      │   ├─→ NPCBidController (Bot AI)
      │   └─→ RNGGarageGenerator (Garage Creation)
      │
      ├─→ InventoryManager (Items, Cars, Lockers, Decorations)
      │   └─→ ItemDatabase (All item definitions)
      │
      ├─→ PlotManager (Conveyor System, Placement)
      │   └─→ IncomeGenerator (Passive Money Generation)
      │
      ├─→ RebirthManager (Progression, Unlocks)
      │
      ├─→ ShopManager (Dice Shop)
      │   └─→ DiceRNG (NPC Generation)
      │
      ├─→ TradeManager (Player-to-Player Trading)
      │
      ├─→ TeleportManager (Location Transitions)
      │
      └─→ UIManager (All UI Rendering)
          ├─→ TierSelectionUI (Pop-up)
          ├─→ BidBattleUI (Screen overlay)
          ├─→ InventoryUI (Pop-up) 
          ├─→ RebirthUI (Pop-up)
          ├─→ TradeUI (Pop-up)
          ├─→ DiceShopUI (Pop-up)
          └─→ MainLobbyUI (Physical World Overlay - 9 Buttons)
```

---

## 👨‍💼 MANAGER BREAKDOWN

### 1. **DataStoreManager**
**Purpose:** Auto-save all player data every 2 minutes

**Saves:**
```lua
{
  playerId = "player_id",
  timestamp = os.time(),
  money = 700,
  rebirthCount = 0,
  inventory = { ... },
  plot = { ... },
  stats = { ... }
}
```

**Key Functions:**
- `Save()` - Called every 2 min
- `Load()` - On player join
- `UpdateField(key, value)` - Real-time updates

---

### 2. **PlayerDataManager**
**Purpose:** Handle all player state in-memory

**Stores:**
```lua
players[playerId] = {
  money = 700,
  rebirths = {
    count = 0,
    timestamp = 0
  },
  inventory = {
    items = {},      -- Decorations, Potions
    cars = {},       -- Owned cars
    lockers = {},    -- Time-locked containers
    dice = {}        -- From shop
  },
  plot = {
    conveyors = {
      { car = nil, npc = nil },
      { car = nil, npc = nil },
      ...
    }
  },
  luckBoosts = {
    active = {},     -- Currently running
    expired = {}
  },
  stats = {
    totalBidsWon = 0,
    totalBidsLost = 0,
    totalMoneySpent = 0,
    totalMoneyEarned = 0
  }
}
```

**Key Functions:**
- `GetPlayer(playerId)`
- `UpdateMoney(playerId, amount)`
- `AddToInventory(playerId, itemType, item)`
- `RemoveFromInventory(playerId, itemType, itemId)`

---

### 3. **BidEngine**
**Purpose:** Control entire bid battle flow

**States:**
- `WAITING` - Waiting for players
- `BIDDING` - Active bidding phase
- `SETTLING` - Determining winner
- `COMPLETED` - Bid finished

**Flow:**
```
1. Player selects tier → Teleport to RNG Garage
2. RNG Garage generated (random car + decorations per tier specs)
3. 3 random bots selected from 6 available (Bacon, Barbara, Jack, Jeff, Mashallah, Roblofía)
4. Set starting bid price (tier-based)
5. Start bidding phase (2 sec player, 1 sec bots)
6. Bid raise with 10% of CURRENT BID VALUE
   Example: Current bid $300 → Next raise is $300 * 0.10 = $30 → New bid $330
7. Countdown: 2 → 1 → 0
8. If no bids: auto-end, refund entry fee
9. If bids made: Calculate winner (highest bid)
10. Winner selection phase (0-2 decorations can be selected)
11. Loser handling (money lost)
12. Teleport back to Lobby
```

**Key Functions:**
- `StartBid(playerId, tierPrice, garageType)`
- `PlayerBid(playerId, amount)`
- `BotBid(amount)` - Called by NPCBidController
- `CalculateWinner()`
- `SettleWin(playerId)`
- `SettleLoss(playerId, bidAmount)`
- `SelectDecorations(playerId, decorationIds[])`

---

### 4. **NPCBidController**
**Purpose:** AI brain for all bot bidders (shared across all bots)

**Core Logic:**
- All bots use **SINGLE SHARED AI** (not individual)
- Bids range: **35-65% of rng garage value**
- Each bid: each bid add +10% of the actual bid ( if the bid is 300$ it will increase with 30$ and so )
- Timing: 1 second between bids for bots, and 3 seconds for the player
- Stop condition: Bots random stop between 35-65%, one brain controlling them all
- **BID INCREMENT USES 10% SYSTEM** (same as player)

**Algorithm:**
```
garageValue = CarPrice + (DecoCount * 20)
minBid = garageValue * 0.35
maxBid = garageValue * 0.65
randomStopPoint = Random(minBid, maxBid)

while currentBidAmount < randomStopPoint:
    botIncrement = currentBidAmount * 0.10  -- 10% of current bid
    currentBidAmount += botIncrement
    wait(1 second)
    Bid(currentBidAmount)
    
    if currentBidAmount >= randomStopPoint:
        Stop()
```

**Key Functions:**
- `CalculateGarageValue(garage)`
- `DetermineBidRange(garageValue)`
- `GenerateNextBid(currentBid)`
- `ShouldContinueBidding(currentBid, stopPoint)`

---

### 5. **RNGGarageGenerator**
**Purpose:** Create random garages based on tier (ONE physical location, dynamic generation)

**Physical Garage Details:**
- **Location:** Workspace > Garage (pre-built map area)
- **Platform:** Yellow spotlight platform where bots/player stand
- **Car Spawn Point:** Back of garage (car model displays here) 
- **Decorations Spawn:** Randomly placed around garage area and around the car
- **Lighting:** Dynamic based on tier (if its golden its brighter)
- **Camera Position:** Third-person view, player sees themselves + 3 bots facing car

**Tier Specifications:**

| Tier | Entry | Car Rarity | Deco Count | Locker Rate |
|------|-------|-----------|-----------|------------|
| BEGINNER | $200 | Common-Rare | 4-7 | 1/10 |
| ADVANCED | $500 | Uncommon-Epic | 7-13 | 1/4 |
| EXPERT | $1200 | Rare-Legendary + 3% SPEC | 13-21 | 1/2 |
| CHOSEN | $2500 | Rare-Legendary + 10% SPEC | 21-50 | 1/1 (always) |
| ULTIMATE | $5000 | Epic-Legendary +25% SPEC | 50-80 | 2x 1/1 (always double) |


**RNG GARAGES**

- Basic:
- Golden: 
- Diamond:
- RUBY :

**CAR RARITIES** + **RNG GARAGES**

- BEGINNER: common 1/4 | uncommon 1/5 | rare 1/8
- ADVANCED: uncommon 1/8 | rare 1/6 | epic 1/10
- EXPERT: rare 1/10 | epic 1/6 | legendary 1/12 (3% SPEC INSTEAD OF LEGENDARY)               |FOR BASIC RNG GARAGE
- CHOSEN: rare 1/36 | epic 1/24 | legendary 1/8 (10% SPEC INSTEAD OF LEGENDARY)
- ULTIMATE: epic 1/24 | legendary 1/8 (25% SPEC INSTEAD OF LEGENDARY)

- BEGINNER: common 1/8 | uncommon 1/4 | rare 1/6
- ADVANCED: uncommon 1/12 | rare 1/6 | epic 1/6
- EXPERT: rare 1/14 | epic 1/8 | legendary 1/10 (5% SPEC INSTEAD OF LEGENDARY)         |FOR GOLDEN RNG GARAGE
- CHOSEN: rare 1/50 | epic 1/30 | legendary 1/5 (12% SPEC INSTEAD OF LEGENDARY)
- ULTIMATE: epic 1/36 | legendary 1/5 (30% SPEC INSTEAD OF LEGENDARY)

- BEGINNER: common 1/10 | uncommon 1/8 | rare 1/4
- ADVANCED: uncommon 1/12 | rare 1/8 | epic 1/4 
- EXPERT: rare 1/20 | epic 1/10 | legendary 1/8 (5% SPEC INSTEAD OF LEGENDARY)         |FOR DIAMOND RNG GARAGE
- CHOSEN: rare 1/50 | epic 1/50 | legendary 1/3 (15% SPEC INSTEAD OF LEGENDARY)
- ULTIMATE: epic 1/50 | legendary 1/2 (30% SPEC INSTEAD OF LEGENDARY)

- BEGGINER: common 1/10 | uncommon 1/10 | rare 1/2
- ADVANCED: uncommon 1/14 | rare 1/10 | epic 1/4
- EXPERT: rare 1/50 | epic 1/14 | legendary 1/6 (10% SPEC INSTEAD OF LEGENDARY)      |FOR RUBY RNG GARAGE
- CHOSEN: rare 1/50 | epic 1/50 | legendary 1/2 (20% SPEC INSTEAD OF LEGENDARY)
- ULTIMATE: epic 1/50 | legendary 1/2 ( 40% SPEC INSTEAD OF LEGENDARY)

**Generation Process:**
```
1. Clear previous garage (remove car, decorations, lockers)
2. Roll car rarity based on tier
3. Roll car model from that rarity pool (see Complete Car Index)
4. Spawn car model at center position
5. Roll decoration count (min-max based on tier)
6. Generate decoration indices (#1, #2, #3... based on count)
7. Spawn each decoration model around garage perimeter
8. Determine if locker drops (based on rate)
9. If locker: Roll locker rarity (33% equal chance Silver/Gold/Black)
10. Spawn locker model(s) visible to all players
11. Populate locker contents (see Locker Contents section)
12. Update all players' screens with BidUI overlay
```

**Key Functions:**
- `GenerateGarage(tierType)`
- `RollCarRarity(tier)`
- `SelectCarModel(rarity)`
- `GenerateDecorations(count)`
- `RollLocker(tier)`
- `PopulateLockerContents(lockerRarity)`
- `SpawnCarModel(carId, position)`
- `SpawnDecorationModel(decorationId, position)`
- `ClearGarage()` - Removes all models before new generation

---

### 6. **InventoryManager**
**Purpose:** Manage all inventory items (Items, Cars, Lockers, Decorations)

**Structure:**
```lua
inventory[playerId] = {
  -- Items Tab
  items = {
    { id = "deco_001", name = "#1", value = 20, rarity = "common" },
    { id = "deco_002", name = "#2", value = 20, rarity = "common" },
    { id = "potion_luck_001", name = "Luck Boost", duration = 3600, type = "silver" },
    { id = "dice_basic_001", name = "Basic Dice", type = "basic" },
    { id = "locker_001", name = "Silver Locker", rarity = "silver", openedAt = 0, unopened = true }
  },
  
  -- Cars Tab
  cars = {
    { id = "car_ford_caisu_001", name = "Ford Caisu", rarity = "common", income = 15, owned = true },
    { id = "car_mcArren_senior_001", name = "McArren Senior", rarity = "legendary", income = 280, owned = false },
  },
  
  -- Locker Tab
  lockers = {
    { id = "locker_silver_001", rarity = "silver", timeToOpen = 3600, unopened = true },
    { id = "locker_gold_001", rarity = "gold", timeToOpen = 14400, unopened = false, contents = {...} }
  },
  
  -- Index Tab (View Only - All Cars)
  index = {
    -- Shows all cars in game with rarity, income, and lock status
  }
}
```

**UI Tab Structure:**

1. **Items Tab** - Grid layout VIRAL MODERN UI
   - Decorations (numbered #1, #2, etc. - 4 per row, scrollable)
   - Potions (4 per row, scrollable)
   - Dice (4 per row, scrollable)
   - Lockers (separate section)

2. **Cars Tab** - Modern Grid with Rarity Sections VIRAL MORDEN UI
   - `Common` cars - Full row
   - `Uncommon` cars - Full row
   - `Rare` - Full row
   - `Epic` - Full row
   - `Legendary` - Full row
   - `SPEC` - Full row
      there are 4 cars per row cause its how any other VIRAL MODERN UI HAVE
     scrollable in up and down, 3X4 cars, sorted by rarity
   c   c   c   c
   c   c   c   c
   c   c   c   c
     like that will be the cars placed, -- common -- and under the common will be the common cars placed, -- uncommon -- and under it the uncommon cars, and so
   
   **Each car shows:**
   - Color image (with no background)
   - Car name
   - Income $/min
   - If owned: Colored image + Income visible
   - If not owned: Black image + Lock icon + "???" income

3. **Locker Tab** - List with time remaining 
LOCKERS AUTOMATICALLY STARTING THE TIMER, SO IF YOU FIND A SILVER ONE YOU JUST NEED TO WAIT 1H FOR IT TO BE ABLE TO OPEN
   - Silver (1 hour) - Timer or [OPEN]
   - Gold (4 hours) - Timer or [OPEN]
   - Black (8 hours) - Timer or [OPEN]
   
   **When opened:**
   - Modal popup showing rewards
   - Auto-collect into inventory
   - Locker vanishes after

4. **Index Tab** - View only
   - All cars in game
   - Owned cars: Colored + Income value
   - Locked cars: Black + Lock icon + "???" income
   - Sorted by rarity

**Key Functions:**
- `GetInventory(playerId)`
- `AddItem(playerId, itemType, item)`
- `RemoveItem(playerId, itemType, itemId)`
- `ListItems(playerId)`
- `GetCars(playerId, ownedOnly = true)`
- `OpenLocker(playerId, lockerId)`
- `UsePotion(playerId, potionId)`
- `ConsumeItem(playerId, itemType, itemId, quantity)`

---

### 7. **PlotManager**
**Purpose:** Manage player plot, conveyors, and placements (Physical on map)

**Plot Structure:**
```lua
plot[playerId] = {
  conveyors = {
    {
      id = "conveyor_1",
      car = { id = "car_x1", income = 50, boosted = false },
      npc = { id = "npc_booster_1", boostType = "golden_dice", boostPercent = 50 },
      income_accumulated = 1250,
      lastCollected = os.time()
    },
    { id = "conveyor_2", car = nil, npc = nil, income_accumulated = 0, lastCollected = 0 },
    ...
  },
  totalConveyors = 3,
  unlockedCount = 3
}
```

**Conveyor System:**
- Max 6 conveyors total
- Start with 3
- +1 at Rebirth 1 ($2000)
- +1 at Rebirth 3 ($10000)
- +1 at Robux 19 (premium)
- **1 car + 1 NPC per conveyor**
- Income: BASE (car) + BOOST (NPC %)

**Income Generation:**
```
Base Income = Car's $/min
With NPC = Car Income * (1 + NPC Boost%)

Example:
Car X1 = $50/min
NPC Booster (Golden Dice) = 50% boost
Total = $50 * 1.5 = $75/min

Offline MAX = 8 hours
$75/min * 60 = $4,500/hour
$4,500 * 8 = $36,000 max offline
```

**Collection Mechanic:**
- Player walks to car on plot
- Press `E` → "Collect" prompt
- Shows total accumulated since last collect
- Updates in real-time
- Money added to player wallet
- Counter resets

**Key Functions:**
- `PlaceCar(playerId, carId, conveyorId)`
- `PlaceNPC(playerId, npcId, conveyorId)`
- `RemoveCar(playerId, conveyorId)`
- `RemoveNPC(playerId, conveyorId)`
- `CollectIncome(playerId, conveyorId)`
- `CalculateOfflineIncome(playerId)`
- `UnlockConveyor(playerId)` - Rebirth system calls this
- `GetPlotStatus(playerId)`

---

### 8. **IncomeGenerator**
**Purpose:** Passive money generation system (offline included)

**Logic:**
```
When player joins/loads:
1. Check last logout time
2. Calculate time offline (max 8 hours per conveyor)
3. For each conveyor with a car:
   - Calculate: minutes_offline * income_per_minute (capped at 8 hours)
   - Add to accumulated income
4. When player presses E on car:
   - Show accumulated amount
   - Add to wallet
   - Reset counter
   - Reset lastCollected timestamp
```

**Calculation:**
```lua
function CalculateAccumulatedIncome(conveyor, timeSinceLastCollect)
    maxOfflineTime = 8 * 60 * 60  -- 8 hours in seconds
    actualTime = min(timeSinceLastCollect, maxOfflineTime)
    
    baseIncome = conveyor.car.income
    npcBoost = conveyor.npc ? conveyor.npc.boostPercent : 0
    totalIncomePerSecond = (baseIncome / 60) * (1 + npcBoost/100)
    
    accumulated = totalIncomePerSecond * actualTime
    return floor(accumulated)
end
```

**Key Functions:**
- `CalculateOfflineIncome(playerId, conveyorId)`
- `AddAccumulatedIncome(playerId, conveyorId, amount)`
- `CollectAll(playerId)` - Collecting all the income for the conveyors
- `UpdateIncomePerSecond(playerId, conveyorId)`

---

### 9. **RebirthManager**
**Purpose:** Handle progression milestones and unlocks

**Rebirth Levels:**

| Level | Cost | Effect | Unlocks |
|-------|------|--------|---------|
| 0 (Start) | - | - | - |
| 1 | $2,000 | Reset money to $0 | +1 Conveyor (4 total), +2 Luck Boosts |
| 2 | $5,000 | Reset money to $0 | Trade System (Player ↔ Player) |
| 3 | $10,000 | Reset money to $0 | +1 Conveyor (5 total), Access World 2 |

**Mechanics:**
```
1. Player has $2000+ → click on rebirth button → Rebirth UI
2. Player confirms rebirth
3. Money set to $0 (lose all)
4. Rebirth count +1
5. Unlock new features
6. Keep all items/cars/lockers
7. Keep NPCs on conveyors
8. Reset money only
9. Update DataStore
```

**Key Functions:**
- `CanRebirth(playerId, level)`
- `ExecuteRebirth(playerId, level)`
- `UnlockFeature(playerId, feature)`
- `GetRebirthStatus(playerId)`
- `GetNextRebirthCost(playerId)`

---

### 10. **ShopManager**
**Purpose:** Dice shop where players buy RNG dice to obtain NPC Boosters
pop-up intended, 
**Access** Merchant npc area, player click on Shop it gets teleported to the merchant, hold E to acces the dice shop

**Shop Interface:**
Modern smooth UI style (Cyan/Purple theme - Bid Battles aesthetic)

```
┌────────────────────────────────┐
│         DICE SHOP              │
├────────────────────────────────┤
│                                │
│ [BASIC DICE] [GOLDEN DICE]     │
│ $150         $300              │
│ [BUY]        [BUY]             │
│                                │
│ [DIAMOND DICE] [NA-SPEC DICE]  │
│ $1100        $2500             │
│ [BUY]        [BUY]             │
│                                │
└────────────────────────────────┘
```

**Dice Types & Contents:**

| Dice | Price | NPC Rarity | Boost Range | Availability |
|------|-------|------------|-------------|--------------|
| Basic | $150 | Common-Rare | 10-30%+ | Always |
| Golden | $300 | Uncommon-Epic | 20-60% | Always |
| Diamond | $1100 | Rare-Legendary | 50-100% | Always |
| NA-SPEC | $2500 | Rare-SPEC | 50-150% | Rebirth 1+ |


**Flow:**
```
0. Player clicks Shop button and teleports to Merchant area
1. Player presses E on Merchant NPC → DiceShopUI pop-up opens
2. Player selects dice type and clicks [BUY]
3. Money deducted from wallet
4. Dice goes to Items → Inventory
5. Player opens dice → RNG rolls NPC (Dice disappears, NPC obtained)
6. NPC goes to Items → Inventory
7. Player places NPC on conveyor at their plot
```

**Key Functions:**
- `BuyDice(playerId, diceType)`
- `OpenDice(playerId, diceId)` - RNG NPC generation
- `GetDiceShop()` - Returns all available dice
- `CanAffordDice(playerId, diceType)`

---

### 11. **DiceRNG**
**Purpose:** Generate random NPCs from dice

**NPC Generation:**
```lua
function GenerateNPC(diceType)
    rarities = GetRaritiesForDice(diceType)
    boostPercent = RandomRange(MinBoost[diceType], MaxBoost[diceType])
    npcName = GenerateRandomName()
    
    return {
        id = generateUUID(),
        name = npcName,
        type = diceType,
        boostPercent = boostPercent,
        rarity = SelectRarity(rarities),
        createdAt = os.time()
    }
end
```

**Key Functions:**
- `RollNPC(diceType)`
- `GetNPCStats(npcId)`
- `GenerateBoostPercent(diceType)`

---

### 12. **TradeManager** (Rebirth 2+)
**Purpose:** Player-to-player trading

**Trade System:**
- Modern UI (Pet Simulator style)
- 1v1 trades
- Only cars & NPCs tradeable
- No cash trading
- Confirm from both sides required

**Flow:**
```
1. Player A opens trade
2. Adds car/NPC to offer
3. Sends to Player B
4. Player B sees incoming trade
5. Player B adds car/NPC to counter
6. Both confirm [ACCEPT] or [DECLINE]
7. If both accept: Swap items
8. Update DataStore
```

**Key Functions:**
- `InitiateTrade(playerAId, playerBId)`
- `AddToTrade(playerId, tradeId, itemType, itemId)`
- `RemoveFromTrade(playerId, tradeId, itemType, itemId)`
- `AcceptTrade(playerId, tradeId)`
- `DeclineTrade(playerId, tradeId)`
- `CompleteTrade(tradeId)`
- `GetPendingTrades(playerId)`

---

### 13. **TeleportManager**
**Purpose:** Handle all location transitions

**Teleport Points:**

| From | To | Trigger |
|------|-----|---------|
| Main Lobby | RNG Garage | Tier Selection (tier chosen + money deducted) |
| RNG Garage | Main Lobby | Win/Lose + Teleport back |
| Main Lobby | Merchant | SHOP button click |
| Merchant | Main Lobby | Exit |
| Main Lobby | Rebirth UI | REBIRTH button click |

**Key Functions:**
- `Teleport(playerId, destination, args = {})`
- `TeleportToRNGGarage(playerId, tierType)`
- `TeleportToLobby(playerId)`
- `TeleportToMerchant(playerId)`
- `GetTeleportPosition(location)`

---

### 14. **UIManager**
**Purpose:** Central hub for all UI rendering and button interactions

**UI Color Theme:**
- **Primary Cyan:** #00D4FF
- **Primary Purple:** #7B2CBF
- **Accent Green:** #00FF41 (Shop)
- **Accent Red:** #FF1744 (BID button)
- **Dark Blue:** #1A1F71 (Secondary buttons)

**UI Screens & Implementation:**

#### 1. **Main Lobby UI** - Physical World Screen Overlay (NO Pop-up)
**Layout:** 9 Buttons distributed on screen + Wallet Display

```
┌────────────────────────────────────────────────────────┐
│  [Events]        [Garage]         [Shop]               │
│  (Purple)        (Cyan)           (Green)      [$700]  │
│  #7B2CBF         #00D4FF          #00FF41      display │
│  COMING SOON     Tier Selection   Teleport             │
│                  Pop-up           to Merchant          │
│                                                        │
│  ┌─┐                                             ┌──┐ │
│  │⚙│ Settings                             Plot   │  │ │
│  │ │ Gear                                      │  │ │
│  │ │                                           │  │ │
│  │ │                                           │  │ │
│  │ │                                           │  │ │
│  │ │                                           │  │ │
│  │ │                                           │  │ │
│  └─┘                                             └──┘ │
│  ShopGamepass                              OfertaGamepass
│  (Future)                                 (Future)
│                                                        │
│  [Inventory]     [BID]            [Rebirth]           │
│  (Bottom-Left)   (Bottom-Center)  (Bottom-Right)      │
│  Pop-up         TierSelection UI   Pop-up             │
│  #00D4FF         #FF1744           #7B2CBF            │
│                                                        │
└────────────────────────────────────────────────────────┘

PLAYER WALKING AROUND 3D WORLD WITH WASD
All buttons are screen overlays (ScreenGui, not Part buttons)
```

**Button Details:**

1. **[Events]** - Top-Left (Purple #7B2CBF)
   - Status: COMING SOON
   - Action: None yet

2. **[Garage]** - Top-Center (Cyan #00D4FF)
   - Triggers: `TierSelectionUI:Show()`
   - Shows Pop-up with 5 tier options

3. **[Shop]** - Top-Right (Green #00FF41)
   - Action: `TeleportManager:TeleportToMerchant(playerId)`

4. **Settings** - Left Side (Gear Icon)
   - Status: COMING SOON (placeholder)

5. **ShopGamepass** - Left Side Below Settings
   - Status: COMING SOON (placeholder)

6. **OfertaGamepass** - Right Side (Near Plot)
   - Status: COMING SOON (placeholder)

7. **[Inventory]** - Bottom-Left (Cyan #00D4FF)
   - Action: `InventoryUI:Show()`
   - Shows Pop-up with 4 tabs (Items, Cars, Lockers, Index)

8. **[BID]** - Bottom-Center (Red #FF1744) - PROMINENT
   - Action: `TierSelectionUI:Show()`
   - Same as [Garage] button - Opens tier selection

9. **[Rebirth]** - Bottom-Right (Purple #7B2CBF)
   - Condition: Only shows if money >= $2000
   - Action: `RebirthUI:Show()`

10. **Wallet Display** - Top-Right Corner
    - Shows: `$` + current money
    - Color: Gold/Yellow accent
    - Updates: Real-time when money changes

---

#### 2. **Tier Selection UI** - Pop-up Window (Scrollable Horizontal)
- **Background:** Gradient from Cyan to Purple
- **Layout:** Single horizontal scrollable row
- **Visible tiers (scroll to see Tier 5):**
  - [BEGINNER] - $200 entry
  - [ADVANCED] - $500 entry
  - [EXPERT] - $1200 entry
  - [CHOSEN] - $2500 entry
  - [TIER 5] - $5000 entry (scrollable, appears after 4th)
- **Tier Cards Show:**
  - Tier name (large text)
  - Entry price (large cyan text)
  - Estimated decorations range (small text)
  - [SELECT] button on each tier
- **Action:** Click [SELECT] on tier → Deduct money → Teleport to RNG Garage
- **Close button:** X button in top-right corner
- **Scrollable:** Arrow buttons left/right or mouse scroll

---

#### 3. **Bid Battle UI** - Screen Overlay (Physical Garage)
- **Background:** 50% transparent overlay (not full screen, only edges)
- **Live bid display (top-center):**
  - Current bid amount (large red text)
  - Countdown timer (2 → 1 → 0)
  - Last bid player name
- **Bid history (right side):**
  - [Player Name: $XXX]
  - [Bot Name: $XXX]
  - [Bot Name: $XXX]
  - [Player Name: $XXX]
  - Scrollable list
- **Bottom-center buttons:**
  - [BID] Button (Red #FF1744) - LARGE, prominent
  - Shows next bid amount when hovered
- **Top buttons (always accessible):**
  - [Inventory] (small button)
  - [Settings] (small button)
- **Wallet display:** Bottom-right corner (live update)

---

#### 4. **Inventory UI** - Pop-up Window
- **Header:** Close (X) button, title "INVENTORY"
- **Tabs at top:** [Items] [Cars] [Lockers] [Index]
- **Items Tab:**
  - Grid layout (4 per row)
  - Sections: Decorations, Potions, Dice, Lockers
  - Each item shows: image, name, quantity, value
  - Scrollable
- **Cars Tab:**
  - Grid layout (4 per row)
  - Sorted by rarity (Common → SPEC)
  - Each car shows: image (colored if owned, black if locked), name, income $/min
  - Lock icon on unrevealed cars
  - Scrollable
- **Lockers Tab:**
  - List layout (not grid)
  - Each locker shows: rarity, time remaining, [OPEN] button if ready
  - Timer updates in real-time
  - Click [OPEN] → Reward modal pop-up
- **Index Tab:**
  - View-only list of all cars in game
  - Same styling as Cars Tab
  - Shows locked/owned status
  - No interaction

---

#### 5. **Rebirth UI** - Pop-up Confirmation
- **Title:** "REBIRTH CONFIRMATION"
- **Display:**
  - Current rebirth level
  - Cost of next rebirth
  - Benefits of next rebirth (text list)
  - Current money display
- **Buttons:**
  - [CONFIRM REBIRTH] (Green)
  - [CANCEL] (Dark Blue)
- **Warning:** "You will lose all current money" (Red text)

---

#### 6. **Trade UI** - Pop-up (Pet Simulator Style)
- **Two-panel layout:**
  - Left: Player A's offer
  - Right: Player B's offer
- **Each panel shows:**
  - Player name and avatar
  - Items offered (cars/NPCs grid)
  - [Add Item] button
  - [Remove Item] buttons on each item
- **Center:** Shows trade status
- **Bottom buttons:**
  - [ACCEPT] (Green)
  - [DECLINE] (Dark Blue)
  - [CANCEL] (Gray)

---

#### 7. **Dice Shop UI** - Pop-up Window
- **Background:** Gradient Cyan to Purple
- **Layout:** 2x2 grid
- **Each dice shows:**
  - Large dice image
  - Dice name (BASIC DICE, GOLDEN DICE, etc.)
  - Price in large cyan text
  - NPC rarity range (text)
  - [BUY] button (Red, prominent)
- **Wallet display:** Top-right corner
- **Close button:** X in top-right

---

**Key Functions:**
- `ShowTierSelection(playerId)` - Pop-up
- `ShowBidUI(playerId, garageInfo)` - Screen overlay
- `ShowInventory(playerId, tab = "cars")` - Pop-up
- `ShowRebirthUI(playerId)` - Pop-up
- `ShowTradeUI(playerAId, playerBId)` - Pop-up
- `ShowDiceShop(playerId)` - Pop-up
- `HideUI(playerId, uiName)` - Close any UI
- `UpdateWalletDisplay(playerId, newAmount)` - Real-time update
- `UpdateBidDisplay(currentBid, playerName)` - Live update
- `UpdateCountdown(seconds)` - Live timer

---

## 💾 DATASTORE STRUCTURE

### Main Save File Schema

```json
{
  "playerId": "player_id_12345",
  "timestamp": 1715113200,
  "gameVersion": "1.0.0",
  
  "account": {
    "username": "PlayerName",
    "joinDate": 1715000000,
    "lastLogin": 1715113200,
    "totalPlaytime": 3600
  },
  
  "wallet": {
    "money": 1500,
    "lastUpdated": 1715113200
  },
  
  "progression": {
    "rebirthCount": 0,
    "rebirthTimestamps": [],
    "currentWorld": 1,
    "tutorialCompleted": true
  },
  
  "inventory": {
    "items": [
      {
        "id": "deco_001",
        "type": "decoration",
        "name": "#1",
        "quantity": 1,
        "value": 20,
        "acquiredAt": 1715112000
      }
    ],
    "cars": [],
    "lockers": [],
    "dice": []
  },
  
  "plot": {
    "conveyors": [
      {
        "id": "conveyor_1",
        "car": null,
        "npc": null,
        "income_accumulated": 0,
        "lastCollected": 1715113200
      }
    ],
    "totalConveyors": 3,
    "unlockedCount": 3
  },
  
  "stats": {
    "totalBidsWon": 0,
    "totalBidsLost": 0,
    "totalBidsParticipated": 0,
    "totalMoneySpent": 0,
    "totalMoneyEarned": 0
  }
}
```

---

## 🗂️ FOLDER STRUCTURE

```
Bid-a-Car-World-1-Final2.1/
├── GAME_ARCHITECTURE.md (THIS FILE - The Bible)
├── src/
│   ├── server/
│   │   ├── Main.server.lua (Initialize all 14 managers)
│   │   ├── Config.lua (Global configuration)
│   │   ├── managers/
│   │   │   ├── DataStoreManager.lua
│   │   │   ├── PlayerDataManager.lua
│   │   │   ├── BidEngine.lua ✓ (Implemented)
│   │   │   ├── NPCBidController.lua (AI Logic)
│   │   │   ├── RNGGarageGenerator.lua
│   │   │   ├── InventoryManager.lua
│   │   │   ├── ItemDatabase.lua
│   │   │   ├── PlotManager.lua
│   │   │   ├── IncomeGenerator.lua
│   │   │   ├── RebirthManager.lua
│   │   │   ├── ShopManager.lua
│   │   │   ├── DiceRNG.lua
│   │   │   ├── TradeManager.lua
│   │   │   ├── TeleportManager.lua
│   │   │   └── UIManager.lua
│   │   └── UI+Implementation/
│   │       ├── BidBattleUI.lua (Implemented)
│   │       ├── InventoryUI.lua (Implemented)
│   │       ├── LobbyUI.lua (Main Lobby - 9 Buttons)
│   │       ├── TierSelectionUI.lua (Implemented)
│   │       ├── UIHandler.lua
│   │       └── UIManager.lua
│   ├── client/
│   │   └── (If needed for client-side UI handling)
│   └── shared/
│       └── (Shared modules if needed)
└── README.md
```

---

## 🎲 BID MECHANICS DEEP DIVE

### 10% Bid Increment System

**How It Works:**

```
Starting Bid: $100 (set by system)

Player/Bot 1 bids $100
Next available bid = $100 + ($100 * 0.10) = $100 + $10 = $110

Player/Bot 2 bids $110
Next available bid = $110 + ($110 * 0.10) = $110 + $11 = $121

Player/Bot 3 bids $121
Next available bid = $121 + ($121 * 0.10) = $121 + $12.10 = $133.10

...continues until highest bid reaches stop point
```

### NPC Bid Controller AI

**Garage Valuation:**
```
Example Garage (CHOSEN tier):
- Car Price: $800
- Decorations: 30 pieces × $20 = $600
- TOTAL GARAGE VALUE = $800 + $600 = $1400

AI Determines:
- Min Bid (35% of garage) = $1400 × 0.35 = $490
- Max Bid (65% of garage) = $1400 × 0.65 = $910
- Random Stop Point = Random($490, $910) = e.g., $650

Bot Strategy:
- Start with base bid $100
- Increment by 10% each round
- Continue until reaching $650 stop point
- Then STOP (all bots stop at once - shared AI)
```

### Bid Battle Flow

```
ROUND 1:
Player: Can bid or pass (2 sec decision time)
Bot 1: Auto-bids next increment (1 sec)
Bot 2: Auto-bids next increment (1 sec)
Bot 3: Auto-bids next increment (1 sec)
COUNTDOWN: 2 → 1 → 0

ROUND 2:
Player: Can bid or pass
Bot 1: Check if stop point reached? Yes → STOP
Bot 2: Already stopped
Bot 3: Already stopped
COUNTDOWN: 2 → 1 → 0

...continues until all bots stop or player drops out
```

### Winner Determination

```
Final Bids:
- Player: $700
- Bot 1: $650 (stopped)
- Bot 2: $650 (stopped)
- Bot 3: $650 (stopped)

WINNER: Player (highest bid $700)
```

### Win Rewards

```
Player wins garage with:
- 1 Car (directly added to inventory)
- Up to 30 Decorations (player selects 0-2)
- Up to 1-2 Lockers (auto-added)
```

---

## 🚗 ITEM SYSTEM

### Car Rarities & Income

| Rarity | Color | Income $/min | Example |
|--------|-------|-------------|---------|
| Common | Blue | 5-20 | Ford Caisu |
| Uncommon | Green | 20-50 | Toyota Camry |
| Rare | Purple | 50-100 | BMW M5 |
| Epic | Orange | 100-200 | Ferrari F8 |
| Legendary | Red | 200-300 | Lamborghini |
| SPEC | Rainbow | 300-500 | Bugatti |

### Decoration System

```
Decoration #1-#50:
- Type: Visual item
- Value: $20 each
- Stackable: Yes
- Purpose: Filler items in garage wins
- Auto-sell value: $20
```

### Potion System

```
Luck Boost (Silver):
- Type: Active consumable
- Duration: 1 hour
- Effect: +10% bid luck (placeholder effect)
- Obtained: Locker reward

Luck Boost (Gold):
- Type: Active consumable
- Duration: 4 hours
- Effect: +25% bid luck (placeholder)
- Obtained: Locker reward

Luck Boost (Black):
- Type: Active consumable
- Duration: 8 hours
- Effect: +50% bid luck (placeholder)
- Obtained: Locker reward
```

### Dice System

```
Basic Dice ($150):
- NPC Rarity: Common-Rare
- Boost Range: 10-30%
- Roll Animation: 2 seconds
- Result: Random NPC added to inventory

Golden Dice ($300):
- NPC Rarity: Uncommon-Epic
- Boost Range: 20-60%
- Roll Animation: 2 seconds

Diamond Dice ($1100):
- NPC Rarity: Rare-Legendary
- Boost Range: 50-100%
- Roll Animation: 2 seconds
- Unlock: Available from start

NA-SPEC Dice ($2500):
- NPC Rarity: Rare-SPEC
- Boost Range: 50-150%
- Roll Animation: 2 seconds
- Unlock: Rebirth 1+
```

---

## 🔄 PROGRESSION & REBIRTHS

### Rebirth 0 (Start)
- Money: $700
- Conveyors: 3
- Features: Basic gameplay

### Rebirth 1 ($2,000 cost)
- **Effect:** Reset money to $0
- **Unlocks:**
  - +1 Conveyor (total 4)
  - +2 Luck Boosts (start with 2 silver)
  - Access to NA-SPEC Dice
  - New skins/cosmetics (future)

### Rebirth 2 ($5,000 cost)
- **Effect:** Reset money to $0
- **Unlocks:**
  - Trade System (Player ↔ Player trading)
  - Limited-time events (future)

### Rebirth 3 ($10,000 cost)
- **Effect:** Reset money to $0
- **Unlocks:**
  - +1 Conveyor (total 5)
  - **ACCESS TO WORLD 2**
  - Advanced mechanics (future)

---

## 🚙 COMPLETE CAR INDEX

### Common Rarity Cars

| Car Name | Income $/min | Obtained |
|----------|-------------|----------|
| Ford Caisu | 15 | Beginner tier |
| Toyota Camry | 18 | Beginner tier |
| Honda Civic | 12 | Beginner tier |

### Uncommon Rarity Cars

| Car Name | Income $/min | Obtained |
|----------|-------------|----------|
| Tesla Model 3 | 35 | Advanced tier |
| BMW 330i | 40 | Advanced tier |
| Audi A4 | 38 | Advanced tier |

### Rare Rarity Cars

| Car Name | Income $/min | Obtained |
|----------|-------------|----------|
| BMW M5 | 75 | Expert tier |
| Porsche 911 | 85 | Expert tier |
| Mercedes AMG | 80 | Expert tier |

### Epic Rarity Cars

| Car Name | Income $/min | Obtained |
|----------|-------------|----------|
| Ferrari F8 | 150 | Chosen tier |
| Lamborghini Huracán | 160 | Chosen tier |
| McLaren 720S | 155 | Chosen tier |

### Legendary Rarity Cars

| Car Name | Income $/min | Obtained |
|----------|-------------|----------|
| Ferrari 488 Pista | 240 | Expert+ tier |
| Lamborghini Revuelto | 250 | Chosen+ tier |
| Bugatti Chiron | 270 | Ultimate tier |

### SPEC Rarity Cars

| Car Name | Income $/min | Obtained |
|----------|-------------|----------|
| Bugatti Bolide | 400 | Ultimate tier (rare) |
| Pagani Zonda | 420 | Ultimate tier (rare) |
| Koenigsegg Jesko | 450 | Ultimate tier (very rare) |

---

## 👾 NPC & DECORATION DETAILS

### NPC Boosters (from Dice)

```
NPC from Basic Dice ($150):
- Rarity: Common-Rare
- Boost: 10-30%
- Example: "Booster Bob" (20% boost)

NPC from Golden Dice ($300):
- Rarity: Uncommon-Epic
- Boost: 20-60%
- Example: "Golden Grace" (45% boost)

NPC from Diamond Dice ($1100):
- Rarity: Rare-Legendary
- Boost: 50-100%
- Example: "Diamond Duke" (75% boost)

NPC from NA-SPEC Dice ($2500):
- Rarity: Rare-SPEC
- Boost: 50-150%
- Example: "SPEC Supreme" (120% boost)
```

### Decoration Types

```
Decorations #1-#50:
- Generic filler items
- Each worth $20
- No special effects
- Used to fill garage values
- Stackable in inventory
```

---

## 🔐 LOCKER CONTENTS

### Silver Locker (1 hour to open)
```
Possible Contents (Random):
- 1-2 Decorations (#1-#20)
- 1 Luck Boost (Silver)
- 1 Dice (Basic)
- $50-$100 cash reward
```

### Gold Locker (4 hours to open)
```
Possible Contents (Random):
- 3-5 Decorations (#10-#35)
- 1 Luck Boost (Gold)
- 1 Dice (Golden)
- $200-$400 cash reward
- Rare: 1 Epic car piece (unlock future)
```

### Black Locker (8 hours to open)
```
Possible Contents (Random):
- 5-8 Decorations (#25-#50)
- 1 Luck Boost (Black)
- 1 Dice (Diamond or NA-SPEC)
- $500-$1000 cash reward
- Higher chance: Epic/Legendary car
- Very rare: SPEC car
```

---

## 🎓 TUTORIAL FLOW

### Mini-Tutorial (First Time Only)

```
Step 1: Cursor highlights [BID] button
        Text: "Click [BID] to start bidding!"
        Player clicks BID

Step 2: TierSelectionUI opens
        Text: "Select a tier to bid in"
        Cursor highlights [BEGINNER]
        Player clicks BEGINNER

Step 3: Game auto-deducts $200
        Teleports to RNG Garage
        
Step 4: BidBattleUI appears
        Text: "Click [BID] to place your first bid!"
        Cursor highlights [BID] button
        
Step 5: Player places first bid
        Tutorial ends, normal gameplay begins
```

---

## 🔧 KEY SYSTEMS TO IMPLEMENT (60% REMAINING)

**Priority Order:**

1. ✅ **BidEngine.lua** - DONE (bidding logic)
2. ⏳ **NPCBidController.lua** - Needs: AI calculation + bid placement
3. ⏳ **RNGGarageGenerator.lua** - Needs: Car/deco spawning + tier rarities
4. ⏳ **PlotManager.lua** - Needs: Conveyor UI + car placement
5. ⏳ **IncomeGenerator.lua** - Needs: Collection mechanic + offline calc
6. ⏳ **TeleportManager.lua** - Needs: Map transitions
7. ⏳ **RebirthManager.lua** - Needs: Feature unlocks + money reset
8. ⏳ **ShopManager.lua** - Needs: Dice purchase logic
9. ⏳ **DiceRNG.lua** - Needs: NPC generation + randomization
10. ⏳ **LobbyUI.lua** - Needs: 9 buttons + wallet display
11. ⏳ **Button connections** - All UI buttons → correct manager functions
12. ⏳ **DataStore integration** - Load/save cycle

---

**This document is the BIBLE. Everything in the game flows from this architecture.**

