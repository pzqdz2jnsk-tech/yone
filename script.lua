-- Optimized for Delta Executor
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local CONFIG = {
    FARM_SCRIPT_URL = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua",
    HOP_DELAY = 15,
    SCAN_INTERVAL = 5,
    MAX_SERVER_SEARCH = 50
}

local hopInProgress = false
local localPlayer = Players.LocalPlayer

-- Using regular wait function instead of RunService (better compatibility)
function findViciousBee()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and string.lower(obj.Name):find("vicious") then
            if obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                return true
            end
        end
    end
    return false
end

function loadFarmScript()
    local success, err = pcall(function()
        loadstring(game:HttpGet(CONFIG.FARM_SCRIPT_URL))()
    end)
    if success then
        print("✅ Farm script loaded successfully!")
    else
        print("❌ Failed to load farm script: " .. tostring(err))
    end
    return success
end

function getAvailableServers()
    local servers = {}
    local placeId = game.PlaceId
    
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=" .. CONFIG.MAX_SERVER_SEARCH
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end)
    
    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
        print("🌐 Found " .. #servers .. " available servers")
    else
        print("❌ Failed to fetch server list")
    end
    
    return servers
end

function hopServer()
    if hopInProgress then
        print("⏳ Server hop already in progress...")
        return false
    end
    
    hopInProgress = true
    local servers = getAvailableServers()
    
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        print("🔄 Hopping to new server... (" .. #servers .. "/" .. CONFIG.MAX_SERVER_SEARCH .. ")")
        
        local success, errorMsg = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, localPlayer)
        end)
        
        if not success then
            print("❌ Teleport failed: " .. tostring(errorMsg))
            -- Alternative hop method
            local success2 = pcall(function()
                TeleportService:Teleport(game.PlaceId, localPlayer)
            end)
            if success2 then
                print("✅ Using alternative hop method")
            end
        end
        
        hopInProgress = false
        return success
    else
        print("❌ No suitable servers found for hopping")
        hopInProgress = false
        return false
    end
end

-- Simple queue system for server hopping
function simpleHop()
    print("🚀 Attempting simple server hop...")
    local success = pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
    return success
end

-- Main script
print("==================================================================")
print("🚀 Vicious Bee Auto Hop Started")
print("📋 Configuration Loaded")
print("==================================================================")

while wait(CONFIG.SCAN_INTERVAL) do
    if not hopInProgress then
        if findViciousBee() then
            print("🎯 Vicious Bee detected! Loading farm script...")
            if loadFarmScript() then
                print("✅ Farming script activated successfully!")
                break
            else
                print("🔄 Script load failed, hopping server...")
                if not hopServer() then
                    wait(CONFIG.HOP_DELAY)
                    simpleHop()
                end
            end
        else
            print("🔎 No Vicious Bee found, hopping server...")
            if not hopServer() then
                wait(CONFIG.HOP_DELAY)
                simpleHop()
            end
        end
    end
end
