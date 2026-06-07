Make these code changes?

src/server/managers/UIManager.lua
269
270
271
272
273
274
275
276
277
278
279
280
281
282
283
284
285
286
287
288
289
290
291
292
293
294
295
296
297
298
299
300
301
302
303
304
305
306
307
308
309
310
311
312
313
314
315
316
317
318
319
320
321
322
323
324
325
326
327
328
329
330
331
332
333
334
335
336
337
338
339
340
341
342
343
344
345
346
347
    Handles all screen displays, updates, and interactions
            seconds = seconds
        })
    end
    
    return true
end

--[[
    Update Inventory Display (When items change)
    @param playerId: string
    @param inventoryData: table - Full inventory data
]]
function UIManager:UpdateInventoryDisplay(playerId, inventoryData)
    if not playerUIStates[playerId] then
        self:InitializePlayer(playerId)
    end
    
    -- Fire RemoteEvent to client
    local RemoteEvent = game:GetService("ServerStorage"):FindFirstChild("UpdateUI")
    if RemoteEvent then
        RemoteEvent:FireClient(game.Players:FindFirstChild(playerId), "UpdateInventory", inventoryData or {})
    end
    
    return true
end

--[[
    Broadcast UI to multiple players (for shared events)
    @param playerIds: table - Array of player IDs
    @param uiType: string - Type of UI to show
    @param data: table - UI data
]]
function UIManager:BroadcastUI(playerIds, uiType, data)
    local RemoteEvent = game:GetService("ServerStorage"):FindFirstChild("UpdateUI")
    if RemoteEvent then
        for _, playerId in ipairs(playerIds) do
            RemoteEvent:FireClient(game.Players:FindFirstChild(playerId), uiType, data or {})
        end
    end
    
    print("[UIManager] UI '" .. uiType .. "' broadcast to " .. tostring(#playerIds) .. " players")
    return true
end

--[[
    Get current active UI for player
    @param playerId: string
    @return: string - UI name or nil
]]
function UIManager:GetActiveUI(playerId)
    if playerUIStates[playerId] then
        return playerUIStates[playerId].activeUI
    end
    return nil
end

--[[
    Get wallet amount for player
    @param playerId: string
    @return: number - Current wallet amount
]]
function UIManager:GetWalletAmount(playerId)
    if playerUIStates[playerId] then
        return playerUIStates[playerId].walletAmount
    end
    return 0
end

--[[
    Remove player UI state (on disconnect)
    @param playerId: string
]]
function UIManager:RemovePlayer(playerId)
    playerUIStates[playerId] = nil
    print("[UIManager] Player UI state removed: " .. tostring(playerId))
end

return UIManager
