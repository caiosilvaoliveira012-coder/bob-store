
--[[
    BOB AUTO JOINER V1.0
    Roblox Public Server Finder
    PlaceId: 107778070777162
]]

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PlaceId = 107778070777162
local MaxPages = 5

local gui = Instance.new("ScreenGui")
gui.Name = "BobAutoJoiner"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(340, 390)
frame.Position = UDim2.new(0.5, -170, 0.5, -195)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "BOB AUTO JOINER V1.0"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = frame

local search = Instance.new("TextButton")
search.Size = UDim2.new(1, -30, 0, 38)
search.Position = UDim2.fromOffset(15, 55)
search.BackgroundColor3 = Color3.fromRGB(110, 70, 255)
search.Text = "BUSCAR SERVIDORES"
search.TextColor3 = Color3.new(1, 1, 1)
search.Font = Enum.Font.GothamBold
search.TextSize = 13
search.Parent = frame

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -30, 1, -115)
list.Position = UDim2.fromOffset(15, 105)
list.BackgroundColor3 = Color3.fromRGB(29, 29, 38)
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.Parent = list

local function clearList()
    for _, item in ipairs(list:GetChildren()) do
        if item:IsA("TextButton") then
            item:Destroy()
        end
    end
end

local function addServer(server)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 48)
    button.BackgroundColor3 = Color3.fromRGB(43, 43, 56)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.Gotham
    button.Text = "Jogadores: " .. server.playing ..
        "/" .. server.maxPlayers
    button.Parent = list

    button.MouseButton1Click:Connect(function()
        TeleportService:TeleportToPlaceInstance(
            PlaceId,
            server.id,
            Players.LocalPlayer
        )
    end)
end

search.MouseButton1Click:Connect(function()
    clearList()
    search.Text = "BUSCANDO..."

    task.spawn(function()
        local cursor = ""
        local servers = {}

        for page = 1, MaxPages do
            local url = "https://games.roblox.com/v1/games/"
                .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

            if cursor ~= "" then
                url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
            end

            local success, response = pcall(function()
                return HttpService:JSONDecode(
                    game:HttpGet(url)
                )
            end)

            if not success or not response then
                break
            end

            for _, server in ipairs(response.data or {}) do
                if server.playing < server.maxPlayers
                and server.id ~= game.JobId then
                    table.insert(servers, server)
                end
            end

            cursor = response.nextPageCursor or ""

            if cursor == "" then
                break
            end
        end

        table.sort(servers, function(a, b)
            return a.playing < b.playing
        end)

        for _, server in ipairs(servers) do
            addServer(server)
        end

        list.CanvasSize = UDim2.new(
            0, 0, 0, layout.AbsoluteContentSize.Y + 10
        )

        search.Text = "BUSCAR NOVAMENTE"
    end)
end)

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
