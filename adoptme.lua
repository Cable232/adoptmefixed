-- Adopt Me -> Local Roblox Tracker
-- Run separately from the autofarm. Disable its original Telemetry first.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local URL = "http://127.0.0.1:16384/api/tracker"
local INTERVAL = 15

local requestFn = request or http_request or (syn and syn.request) or (http and http.request)
assert(type(requestFn) == "function", "Executor HTTP request function unavailable")

local env = (type(getgenv) == "function" and getgenv()) or _G
if env.CableAdoptTrackerStop then env.CableAdoptTrackerStop() end
local running = true
env.CableAdoptTrackerStop = function() running = false end

local function snapshot()
    local ok, clientData = pcall(function()
        return require(ReplicatedStorage.ClientModules.Core.ClientData)
    end)
    if not ok or not clientData then return nil end
    local okData, data = pcall(function() return clientData.get_data() end)
    if not okData or type(data) ~= "table" then return nil end
    local mine = data[player.Name]
    if type(mine) ~= "table" then return nil end

    local inventory = mine.inventory or {}
    local food = inventory.food or {}
    local pets = inventory.pets or {}
    local potions, petCount, eggs, neon, mega, fullGrown = 0, 0, 0, 0, 0, 0
    for _, item in pairs(food) do
        if type(item) == "table" then
            local kind = string.lower(tostring(item.kind or item.id or ""))
            if kind == "pet_age_potion" then
                potions = potions + (tonumber(item.count) or 1)
            end
        end
    end
    for _, item in pairs(pets) do
        if type(item) == "table" then
            local kind = string.lower(tostring(item.kind or ""))
            if item.is_egg or string.find(kind, "egg", 1, true) then
                eggs = eggs + 1
            else
                petCount = petCount + 1
                local props = item.properties or {}
                if props.mega_neon then mega = mega + 1
                elseif props.neon then neon = neon + 1 end
                if (tonumber(props.age) or 1) >= 6 then fullGrown = fullGrown + 1 end
            end
        end
    end
    return {
        gameType = "adoptme",
        username = player.Name,
        userId = player.UserId,
        bucks = tonumber(mine.money) or 0,
        candy = tonumber(mine.candy_2026) or 0,
        stars = tonumber(mine.stars) or 0,
        recycler_tickets = tonumber(mine.pet_recycler_tickets_2026) or 0,
        age_up_potions = potions,
        pets_total = petCount,
        eggs = eggs,
        neon = neon,
        mega = mega,
        full_grown = fullGrown,
    }
end

task.spawn(function()
    while running do
        local data = snapshot()
        if data then
            pcall(function()
                requestFn({
                    Url = URL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(data),
                })
            end)
        end
        task.wait(INTERVAL)
    end
end)
