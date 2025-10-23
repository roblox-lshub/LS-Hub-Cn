local player = game:GetService("Players").LocalPlayer
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local character = player.Character or player.CharacterAdded:Wait()
local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local scriptStartTime = os.time()
local forbiddenZoneCenter = Vector3.new(352.884155, 13.0287256, -1353.05396)
local forbiddenRadius = 80
local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
local currentJobId = game.JobId
local availableServers = {}

for _, server in ipairs(servers.data) do
    if server.id ~= currentJobId and server.playing < server.maxPlayers then
        table.insert(availableServers, server.id)
    end
end

local targetItems = {
    "Money Printer",
    "Blue Candy Cane",
    "Bunny Balloon",
    "Ghost Balloon",
    "Clover Balloon",
    "Bat Balloon",
    "Gold Clover Balloon",
    "Golden Rose",
    "Black Rose",
    "Heart Balloon",
    "Diamond Ring",
    "Diamond",
    "Void Gem",
    "Dark Matter Gem",
    "Rollie"
}

local function ShowNotification(text)
    game.StarterGui:SetCore(
        "SendNotification",
        {
            Title = "提示",
            Text = text,
            Duration = 5
        }
    )
end

local function checkTimeout()
    return (os.time() - scriptStartTime) >= 120
end

local function TPServer()
    if #availableServers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, availableServers[math.random(1, #availableServers)])
    else
        ShowNotification("没有可用服务器")
    end
end

local function AutoPickItem()
    ShowNotification("正在寻找稀有物品...")

    while task.wait(0.1) do
        if checkTimeout() then
            TPServer()
            return false
        end

        local foundItem = false
        for _, itemFolder in pairs(game:GetService("Workspace").Game.Entities.ItemPickup:GetChildren()) do
            for _, item in pairs(itemFolder:GetChildren()) do
                if item:IsA("MeshPart") or item:IsA("Part") then
                    local itemPos = item.Position
                    local distance = (itemPos - forbiddenZoneCenter).Magnitude
        
                    if distance > forbiddenRadius then
                        for _, child in pairs(item:GetChildren()) do
                            if child:IsA("ProximityPrompt") then
                                for _, targetName in pairs(targetItems) do
                                    if child.ObjectText == targetName then
                                        foundItem = true
                                        child.RequiresLineOfSight = false
                                        child.HoldDuration = 0
                                        humanoid:Move(Vector3.new(1, 0, 0))
                                        HumanoidRootPart.CFrame = item.CFrame * CFrame.new(0, 2, 0)
                                        fireproximityprompt(child)
                                        
                                        local startTime = tick()
                                        local timeout = 5
                                        local connection
                                        connection = game:GetService("RunService").Heartbeat:Connect(function()
                                            if not item or not item.Parent then
                                                connection:Disconnect()
                                                return
                                            end
                                            
                                            if tick() - startTime >= timeout then
                                                item:Destroy()
                                                connection:Disconnect()
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if not foundItem then
            ShowNotification("没有可拾取物品，准备抢劫银行")
            return true
        end
    end
end

local function AutoFarmBank()
    ShowNotification("正在抢劫银行...")

    local BankDoor = workspace.BankRobbery.VaultDoor
    local BankCashs = workspace.BankRobbery.BankCash

    while task.wait(0.1) do
        if checkTimeout() then
            TPServer()
            return
        end

        if BankDoor.Door.Attachment.ProximityPrompt.Enabled == true and BankCashs.Cash:FindFirstChild("Bundle") then
            HumanoidRootPart.CFrame = CFrame.new(1078.08093, 6.24685, -343.95758)
            BankDoor.Door.Attachment.ProximityPrompt.HoldDuration = 0
            fireproximityprompt(BankDoor.Door.Attachment.ProximityPrompt)
            task.wait(0.5)
        elseif not BankDoor.Door.Attachment.ProximityPrompt.Enabled and BankCashs.Cash:FindFirstChild("Bundle") then
            local targetPos = BankCashs.Cash:FindFirstChild("Bundle"):GetPivot().Position
            local basePosition = Vector3.new(targetPos.X, targetPos.Y - 5, targetPos.Z)
            local lookVector = (targetPos - basePosition).Unit
            HumanoidRootPart.CFrame = CFrame.new(basePosition, basePosition + lookVector)
            BankCashs.Main.Attachment.ProximityPrompt.RequiresLineOfSight = false
            BankCashs.Main.Attachment.ProximityPrompt.HoldDuration = 0
            fireproximityprompt(BankCashs.Main.Attachment.ProximityPrompt)
            task.wait(0.5)
        else
            ShowNotification("抢劫银行完成，1秒后换服")
            task.wait(1)
            TPServer()
            return
        end
    end
end

ShowNotification("启动 - 优先物品拾取")

local itemsFinished = AutoPickItem()

if itemsFinished then
    AutoFarmBank()
end