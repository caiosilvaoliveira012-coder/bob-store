
-- BOB AUTO JOINER V3.0
-- Server Finder + Auto Load
-- PlaceId: 107778070777162

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

local PLACE_ID = 107778070777162
local RAW_URL = "https://raw.githubusercontent.com/caiosilvaoliveira012-coder/bob-store/main/BobAutoJoiner.lua"

local Busy = false
local AutoLoad = true
local Minimized = false

-- HTTP compatível com ambientes que oferecem request
local function Request(url)
    local req = request or http_request

    if not req and syn then
        req = syn.request
    end

    if req then
        local response = req({
            Url = url,
            Method = "GET"
        })

        if response.StatusCode ~= 200 then
            error("HTTP " .. tostring(response.StatusCode))
        end

        return response.Body
    end

    return game:HttpGet(url)
end

-- Interface
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("BobAutoJoinerV3"):Destroy()
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "BobAutoJoinerV3"
Gui.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(300, 205)
Main.Position = UDim2.new(0.5, -150, 0.5, -102)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Main.BorderSizePixel = 0
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local function Button(parent, text, pos, size, color)
    local b = Instance.new("TextButton")
    b.Text = text
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    return b
end

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 38)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "BOB AUTO JOINER V3.0"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Minimize = Button(
    Main, "−",
    UDim2.new(1,-40,0,5),
    UDim2.fromOffset(30,28),
    Color3.fromRGB(55,55,70)
)

local Join = Button(
    Main, "AUTO JOINER",
    UDim2.fromOffset(12,45),
    UDim2.new(1,-24,0,43),
    Color3.fromRGB(105,70,255)
)

local Load = Button(
    Main, "AUTO LOAD: ON",
    UDim2.fromOffset(12,97),
    UDim2.new(1,-24,0,35),
    Color3.fromRGB(35,135,85)
)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1,-24,0,35)
Status.Position = UDim2.fromOffset(12,145)
Status.BackgroundTransparency = 1
Status.Text = "Pronto para procurar"
Status.TextColor3 = Color3.fromRGB(190,190,205)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.TextWrapped = true
Status.Parent = Main

local Icon = Button(
    Gui, "BOB",
    UDim2.new(1,-58,0.5,-24),
    UDim2.fromOffset(48,48),
    Color3.fromRGB(105,70,255)
)
Icon.Visible = false
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1,0)

local function SetStatus(msg)
    Status.Text = msg
end

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Icon.Visible = true
end)

Icon.MouseButton1Click:Connect(function()
    Main.Visible = true
    Icon.Visible = false
end)

Load.MouseButton1Click:Connect(function()
    AutoLoad = not AutoLoad

    Load.Text = "AUTO LOAD: " .. (AutoLoad and "ON" or "OFF")
    Load.BackgroundColor3 = AutoLoad
        and Color3.fromRGB(35,135,85)
        or Color3.fromRGB(130,55,55)
end)

-- Buscar servidores públicos
local function FindServer()
    local cursor = nil
    local empty = {}
    local available = {}
    local seen = {}

    for page = 1, 5 do
        SetStatus("Buscando servidores... página " .. page)

        local url = "https://games.roblox.com/v1/games/"
            .. PLACE_ID
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local body = Request(url)
        local data = HttpService:JSONDecode(body)

        if type(data.data) ~= "table" then
            error("Resposta inválida da API")
        end

        for _, server in ipairs(data.data) do
            if server.id
                and server.id ~= game.JobId
                and not seen[server.id]
                and server.playing < server.maxPlayers then

                seen[server.id] = true

                if server.playing == 0 then
                    table.insert(empty, server)
                else
                    table.insert(available, server)
                end
            end
        end

        cursor = data.nextPageCursor

        if not cursor then
            break
        end
    end

    if #empty > 0 then
        return empty[math.random(1, #empty)]
    end

    table.sort(available, function(a,b)
        return a.playing < b.playing
    end)

    return available[1]
end

-- Preparar recarga após teleporte iniciado pelo script
local function PrepareAutoLoad()
    if not AutoLoad then
        return
    end

    local queue = queue_on_teleport
        or queueonteleport
        or (syn and syn.queue_on_teleport)

    if queue then
        pcall(function()
            queue('loadstring(game:HttpGet("' .. RAW_URL .. '"))()')
        end)
    else
        SetStatus("Executor sem suporte a Auto Load")
    end
end

-- Teleporte
Join.MouseButton1Click:Connect(function()
    if Busy then return end

    Busy = true
    Join.Text = "PROCURANDO..."

    task.spawn(function()
        local success, server = pcall(FindServer)

        if not success then
            SetStatus("Erro na busca: " .. tostring(server))
            Join.Text = "TENTAR NOVAMENTE"
            Busy = false
            return
        end

        if not server then
            SetStatus("Nenhum servidor disponível")
            Join.Text = "TENTAR NOVAMENTE"
            Busy = false
            return
        end

        SetStatus("Encontrado: " .. server.playing .. " jogadores")
        Join.Text = "CONECTANDO..."

        PrepareAutoLoad()

        local teleported, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                PLACE_ID,
                server.id,
                Player
            )
        end)

        if not teleported then
            SetStatus("Erro no teleporte: " .. tostring(err))
            Join.Text = "TENTAR NOVAMENTE"
            Busy = false
            return
        end

        SetStatus("Solicitação de teleporte enviada")
    end)
end)

TeleportService.TeleportInitFailed:Connect(function(player, result, message)
    if player == Player then
        Busy = false
        Join.Text = "TENTAR NOVAMENTE"
        SetStatus("Falha no teleporte: " .. tostring(message))
    end
end)

local parented = pcall(function()
    Gui.Parent = game:GetService("CoreGui")
end)

if not parented or not Gui.Parent then
    Gui.Parent = Player:WaitForChild("PlayerGui")
end
