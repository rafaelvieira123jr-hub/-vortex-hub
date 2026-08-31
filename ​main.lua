--[[
    VORTEX HUB - INTERFACE FRAMEWORK (MÓDULO 1: MAIN COMPLETO E INTEGRADO)
    Arquivo: main.lua
    Descrição: Framework de interface responsiva (Mobile/PC) e ponte de comunicação com os módulos de lógica.
--]]

--========================================================--
-- 1. LIMPEZA E SERVIÇOS
--========================================================--

if _G.VortexCleanUp then
    pcall(_G.VortexCleanUp)
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PreviousUI = PlayerGui:FindFirstChild("VortexHub")
if PreviousUI then
    PreviousUI:Destroy()
end

local Connections = {}

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

_G.VortexCleanUp = function()
    for _, conn in ipairs(Connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(Connections)
end

-- Tabela principal que será retornada para o loader
local MainModule = {}
local LoadedModules = {
    Farm = nil,
    Combat = nil,
    Bypass = nil
}

--========================================================--
-- 2. CONFIGURAÇÃO DE TEMA E ESTADO
--========================================================--

local Config = {
    Name = "VORTEX HUB",
    SubTitle = "Meme Sea Edition",
    Version = "v1.0.3 Mobile",

    Width = 580,
    Height = 360,

    Background = Color3.fromRGB(10, 11, 16),
    BackgroundTransparency = 0.05,
    SidebarColor = Color3.fromRGB(15, 16, 24),
    CardColor = Color3.fromRGB(20, 22, 32),
    CardHover = Color3.fromRGB(28, 30, 44),

    Accent = Color3.fromRGB(138, 92, 255),
    AccentGlow = Color3.fromRGB(170, 130, 255),
    AccentDark = Color3.fromRGB(85, 50, 190),

    Text = Color3.fromRGB(250, 250, 255),
    SubText = Color3.fromRGB(140, 142, 160),

    Radius = 12
}

local State = {
    Open = true,
    Minimized = false,
    CurrentPage = "Home",
    Toggles = {},
    Values = {}
}

--========================================================--
-- 3. UTILITÁRIOS DA INTERFACE
--========================================================--

local function Tween(object, time, properties, style, direction)
    local info = TweenInfo.new(
        time or 0.2,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function Corner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Config.Radius)
    corner.Parent = object
    return corner
end

local function Stroke(object, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.Accent
    stroke.Transparency = transparency or 0.7
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = object
    return stroke
end

local function MakeDraggable(handle, object)
    local dragging, dragStart, startPos = false, nil, nil

    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position

            local endedConn
            endedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if endedConn then endedConn:Disconnect() end
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
            local objSize = object.AbsoluteSize

            local newX = math.clamp(startPos.X.Offset + delta.X, 5, viewport.X - objSize.X - 5)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 5, viewport.Y - objSize.Y - 5)

            object.Position = UDim2.fromOffset(newX, newY)
        end
    end)
end

--========================================================--
-- 4. ESTRUTURA BASE DA TELA E JANELA
--========================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VortexHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.ScreenInsets = Enum.ScreenInsets.None end)
ScreenGui.Parent = PlayerGui

local UIScale = Instance.new("UIScale")
UIScale.Parent = ScreenGui

local function UpdateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize

    if viewport.X <= 600 then
        UIScale.Scale = math.clamp(viewport.X / 640, 0.65, 0.85)
    elseif viewport.X <= 1024 then
        UIScale.Scale = 0.9
    else
        UIScale.Scale = 1
    end
end

Connect(RunService.RenderStepped, UpdateScale)
UpdateScale()

-- Botão Flutuante (Mobile)
local FloatingButton = Instance.new("TextButton")
FloatingButton.Name = "FloatingButton"
FloatingButton.Size = UDim2.fromOffset(50, 50)
FloatingButton.Position = UDim2.new(0, 15, 0.4, 0)
FloatingButton.BackgroundColor3 = Config.CardColor
FloatingButton.Text = ""
FloatingButton.AutoButtonColor = false
FloatingButton.Parent = ScreenGui

Corner(FloatingButton, 16)
Stroke(FloatingButton, Config.Accent, 0.3, 1.5)

local FloatingIcon = Instance.new("TextLabel")
FloatingIcon.Size = UDim2.new(1, 0, 1, 0)
FloatingIcon.BackgroundTransparency = 1
FloatingIcon.Text = "V"
FloatingIcon.TextColor3 = Config.AccentGlow
FloatingIcon.TextSize = 22
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.Parent = FloatingButton

MakeDraggable(FloatingButton, FloatingButton)

-- Janela Principal
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(Config.Width, Config.Height)
Main.Position = UDim2.new(0.5, -Config.Width/2, 0.5, -Config.Height/2)
Main.BackgroundColor3 = Config.Background
Main.BackgroundTransparency = Config.BackgroundTransparency
Main.ClipsDescendants = true
Main.Parent = ScreenGui

Corner(Main, Config.Radius)
Stroke(Main, Config.Accent, 0.5, 1.5)

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 50)
Topbar.BackgroundColor3 = Config.SidebarColor
Topbar.BorderSizePixel = 0
Topbar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Position = UDim2.fromOffset(16, 8)
Title.Size = UDim2.fromOffset(200, 20)
Title.Text = Config.Name
Title.TextColor3 = Config.Text
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Topbar

local SubTitle = Instance.new("TextLabel")
SubTitle.Position = UDim2.fromOffset(16, 28)
SubTitle.Size = UDim2.fromOffset(200, 14)
SubTitle.Text = Config.SubTitle .. " | " .. Config.Version
SubTitle.TextColor3 = Config.SubText
SubTitle.TextSize = 10
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.BackgroundTransparency = 1
SubTitle.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(36, 36)
CloseBtn.Position = UDim2.new(1, -43, 0, 7)
CloseBtn.BackgroundColor3 = Config.CardColor
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Config.Text
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Topbar
Corner(CloseBtn, 8)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.fromOffset(36, 36)
MinimizeBtn.Position = UDim2.new(1, -84, 0, 7)
MinimizeBtn.BackgroundColor3 = Config.CardColor
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Config.Text
MinimizeBtn.TextSize = 14
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = Topbar
Corner(MinimizeBtn, 8)

MakeDraggable(Topbar, Main)

-- Corpo e Navegação
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -50)
Body.Position = UDim2.fromOffset(0, 50)
Body.BackgroundTransparency = 1
Body.Parent = Main

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Config.SidebarColor
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 0
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.CanvasSize = UDim2.new()
Sidebar.Parent = Body

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.PaddingBottom = UDim.new(0, 10)
SidebarPadding.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -140, 1, 0)
Content.Position = UDim2.fromOffset(140, 0)
Content.BackgroundTransparency = 1
Content.Parent = Body

local Search = Instance.new("TextBox")
Search.Name = "Search"
Search.Size = UDim2.new(1, -20, 0, 36)
Search.Position = UDim2.fromOffset(10, 10)
Search.BackgroundColor3 = Config.CardColor
Search.PlaceholderText = "🔍 Pesquisar funcionalidade..."
Search.PlaceholderColor3 = Config.SubText
Search.Text = ""
Search.TextColor3 = Config.Text
Search.TextSize = 11
Search.Font = Enum.Font.Gotham
Search.ClearTextOnFocus = false
Search.Parent = Content
Corner(Search, 8)
Stroke(Search, Config.Accent, 0.8, 1)

local SearchPadding = Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 12)
SearchPadding.Parent = Search

--========================================================--
-- 5. GERENCIADOR DE PÁGINAS E ELEMENTOS
--========================================================--

local Pages = {}
local Tabs = {}
local Elements = {}

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name
    Page.Size = UDim2.new(1, -20, 1, -56)
    Page.Position = UDim2.fromOffset(10, 52)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Config.Accent
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new()
    Page.Visible = false
    Page.Parent = Content

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Parent = Page

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingTop = UDim.new(0, 4)
    PagePadding.PaddingBottom = UDim.new(0, 12)
    PagePadding.PaddingRight = UDim.new(0, 4)
    PagePadding.Parent = Page

    Pages[name] = Page
    return Page
end

local function SelectPage(name)
    State.CurrentPage = name
    for pName, page in pairs(Pages) do
        page.Visible = (pName == name)
    end
    for tName, tab in pairs(Tabs) do
        local selected = (tName == name)
        Tween(tab, 0.15, {
            BackgroundColor3 = selected and Config.Accent or Config.CardColor,
            TextColor3 = selected and Config.Text or Config.SubText
        })
    end
    Search.Text = ""
end

local function CreateTab(name, icon, page)
    local Tab = Instance.new("TextButton")
    Tab.Name = name
    Tab.Size = UDim2.new(1, 0, 0, 36)
    Tab.BackgroundColor3 = Config.CardColor
    Tab.Text = (icon and icon .. "  " or "") .. name
    Tab.TextColor3 = Config.SubText
    Tab.TextSize = 11
    Tab.Font = Enum.Font.GothamMedium
    Tab.TextXAlignment = Enum.TextXAlignment.Left
    Tab.AutoButtonColor = false
    Tab.Parent = Sidebar
    Corner(Tab, 8)

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingLeft = UDim.new(0, 10)
    TabPadding.Parent = Tab

    Tabs[name] = Tab
    Connect(Tab.Activated, function() SelectPage(name) end)
    return Tab
end

local function RegisterElement(pageName, instance, displayName)
    table.insert(Elements, {
        Page = pageName,
        Instance = instance,
        Name = displayName:lower()
    })
end

local function CreateSection(parent, title)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 22)
    Label.Text = title:upper()
    Label.TextColor3 = Config.AccentGlow
    Label.TextSize = 10
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = parent
    return Label
end

local function CreateButton(parent, pageName, text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 40)
    Button.BackgroundColor3 = Config.CardColor
    Button.Text = text
    Button.TextColor3 = Config.Text
    Button.TextSize = 11
    Button.Font = Enum.Font.GothamMedium
    Button.AutoButtonColor = false
    Button.Parent = parent
    Corner(Button, 8)
    Stroke(Button, Config.CardHover, 0.5, 1)

    RegisterElement(pageName, Button, text)

    Connect(Button.Activated, function()
        Tween(Button, 0.08, {BackgroundColor3 = Config.AccentDark}):Completed():Connect(function()
            Tween(Button, 0.12, {BackgroundColor3 = Config.CardColor})
        end)
        if callback then task.spawn(callback) end
    end)

    return Button
end

local function CreateToggle(parent, pageName, text, default, callback)
    local enabled = default or false

    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
    ToggleFrame.BackgroundColor3 = Config.CardColor
    ToggleFrame.Parent = parent
    Corner(ToggleFrame, 8)

    local Label = Instance.new("TextLabel")
    Label.Position = UDim2.fromOffset(12, 0)
    Label.Size = UDim2.new(1, -65, 1, 0)
    Label.Text = text
    Label.TextColor3 = Config.Text
    Label.TextSize = 11
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = ToggleFrame

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.fromOffset(42, 22)
    Switch.Position = UDim2.new(1, -50, 0.5, -11)
    Switch.BackgroundColor3 = enabled and Config.Accent or Color3.fromRGB(40, 42, 54)
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = ToggleFrame
    Corner(Switch, 12)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(16, 16)
    Knob.Position = enabled and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3)
    Knob.BackgroundColor3 = Config.Text
    Knob.Parent = Switch
    Corner(Knob, 10)

    RegisterElement(pageName, ToggleFrame, text)

    local function ToggleState(newState)
        enabled = newState
        State.Toggles[text] = enabled
        Tween(Switch, 0.15, {BackgroundColor3 = enabled and Config.Accent or Color3.fromRGB(40, 42, 54)})
        Tween(Knob, 0.15, {Position = enabled and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3)})
        if callback then task.spawn(callback, enabled) end
    end

    Connect(Switch.Activated, function() ToggleState(not enabled) end)
    return {Set = ToggleState, Get = function() return enabled end}
end

local function CreateSlider(parent, pageName, text, min, max, default, callback)
    local value = math.clamp(default or min, min, max)

    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, 0, 0, 52)
    SliderFrame.BackgroundColor3 = Config.CardColor
    SliderFrame.Parent = parent
    Corner(SliderFrame, 8)

    local Label = Instance.new("TextLabel")
    Label.Position = UDim2.fromOffset(12, 6)
    Label.Size = UDim2.new(0.6, 0, 0, 18)
    Label.Text = text
    Label.TextColor3 = Config.Text
    Label.TextSize = 11
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = SliderFrame

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Position = UDim2.new(1, -62, 0, 6)
    ValueLabel.Size = UDim2.fromOffset(50, 18)
    ValueLabel.Text = tostring(value)
    ValueLabel.TextColor3 = Config.AccentGlow
    ValueLabel.TextSize = 11
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Parent = SliderFrame

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.fromOffset(12, 34)
    Track.BackgroundColor3 = Color3.fromRGB(35, 37, 50)
    Track.Parent = SliderFrame
    Corner(Track, 4)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Config.Accent
    Fill.Parent = Track
    Corner(Fill, 4)

    local DragBtn = Instance.new("TextButton")
    DragBtn.Size = UDim2.new(1, 0, 1, 10)
    DragBtn.Position = UDim2.fromOffset(0, -5)
    DragBtn.BackgroundTransparency = 1
    DragBtn.Text = ""
    DragBtn.Parent = Track

    RegisterElement(pageName, SliderFrame, text)

    local dragging = false
    local function UpdateInput(input)
        local posX = input.Position.X - Track.AbsolutePosition.X
        local alpha = math.clamp(posX / Track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * alpha)
        Fill.Size = UDim2.new(alpha, 0, 1, 0)
        ValueLabel.Text = tostring(value)
        State.Values[text] = value
        if callback then task.spawn(callback, value) end
    end

    Connect(DragBtn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateInput(input)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateInput(input)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--========================================================--
-- 6. TODAS AS ABAS E COMPONENTES MAPEADOS (COM CONEXÃO DIRETA DE LÓGICA)
--========================================================--

local HomePage = CreatePage("Home")
local FarmPage = CreatePage("Farm")
local CombatPage = CreatePage("Combat")
local TeleportPage = CreatePage("Teleport")
local SettingsPage = CreatePage("Settings")

CreateTab("Home", "🏠", HomePage)
CreateTab("Farm", "🌾", FarmPage)
CreateTab("Combat", "⚔️", CombatPage)
CreateTab("Teleport", "🌀", TeleportPage)
CreateTab("Settings", "⚙️", SettingsPage)

--- ABA: HOME ---
CreateSection(HomePage, "Informações do Servidor")
CreateButton(HomePage, "Home", "Checar Ping & FPS", function()
    local fps = math.floor(workspace:GetRealPhysicsFPS())
    print("[Vortex Hub] Desempenho Atual - FPS:", fps)
end)
CreateButton(HomePage, "Home", "Copiar Link do Servidor", function()
    if setclipboard then
        setclipboard("https://www.roblox.com/games/" .. tostring(game.PlaceId))
        print("[Vortex Hub] Link copiado para a área de transferência!")
    end
end)
CreateButton(HomePage, "Home", "Reentrar no Servidor (Rejoin)", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

--- ABA: FARM ---
CreateSection(FarmPage, "Automação de Level e Quests")
CreateToggle(FarmPage, "Farm", "Auto Farm Quest", false, function(v)
    if LoadedModules.Farm then
        LoadedModules.Farm.SetFarmState(v)
    end
end)
CreateToggle(FarmPage, "Farm", "Auto Aceitar Quest", false, function(v)
    if LoadedModules.Farm then
        LoadedModules.Farm.Config.AutoQuest = v
    end
end)
CreateSlider(FarmPage, "Farm", "Distância do Alvo", 3, 20, 9, function(v)
    if LoadedModules.Farm then
        LoadedModules.Farm.Config.Distance = v
    end
end)

CreateSection(FarmPage, "Automação de Chefes e Eventos")
CreateToggle(FarmPage, "Farm", "Auto Farm Bosses", false, function(v)
    if LoadedModules.Farm then
        LoadedModules.Farm.Config.FarmBosses = v
    end
end)

--- ABA: COMBAT ---
CreateSection(CombatPage, "Combate Automático")
CreateToggle(CombatPage, "Combat", "Auto Click / Attack", false, function(v)
    if LoadedModules.Combat then
        LoadedModules.Combat.SetAutoClick(v)
    end
end)
CreateToggle(CombatPage, "Combat", "Auto Equipar Arma", false, function(v)
    if LoadedModules.Combat then
        LoadedModules.Combat.SetAutoEquip(v)
    end
end)

CreateSection(CombatPage, "Habilidades Automáticas")
CreateToggle(CombatPage, "Combat", "Usar Skill [Z]", false, function(v)
    if LoadedModules.Combat then
        LoadedModules.Combat.SetSkillState("Z", v)
    end
end)
CreateToggle(CombatPage, "Combat", "Usar Skill [X]", false, function(v)
    if LoadedModules.Combat then
        LoadedModules.Combat.SetSkillState("X", v)
    end
end)
CreateToggle(CombatPage, "Combat", "Usar Skill [C]", false, function(v)
    if LoadedModules.Combat then
        LoadedModules.Combat.SetSkillState("C", v)
    end
end)
CreateToggle(CombatPage, "Combat", "Usar Skill [V]", false, function(v)
    if LoadedModules.Combat then
        LoadedModules.Combat.SetSkillState("V", v)
    end
end)

--- ABA: TELEPORT ---
CreateSection(TeleportPage, "Teleporte de Ilhas")
local function TeleportToCFrame(cf)
    if LoadedModules.Farm then
        LoadedModules.Farm.MoveToCFrame(cf)
    else
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = cf end
    end
end

CreateButton(TeleportPage, "Teleport", "Ilha Iniciar (Floppa Island)", function()
    TeleportToCFrame(CFrame.new(-611, 15, -2174))
end)
CreateButton(TeleportPage, "Teleport", "Ilha Popcat", function()
    TeleportToCFrame(CFrame.new(-1230, 15, -3150))
end)
CreateButton(TeleportPage, "Teleport", "Ilha Cheems", function()
    TeleportToCFrame(CFrame.new(1850, 15, -1120))
end)
CreateButton(TeleportPage, "Teleport", "Ilha Gigachad", function()
    TeleportToCFrame(CFrame.new(-3200, 15, 1450))
end)

--- ABA: SETTINGS ---
CreateSection(SettingsPage, "Configurações da Interface")
CreateButton(SettingsPage, "Settings", "Destruir UI e Desconectar Script", function()
    if LoadedModules.Farm then
        LoadedModules.Farm.SetFarmState(false)
    end
    if LoadedModules.Combat then
        LoadedModules.Combat.SetAutoClick(false)
    end
    if _G.VortexCleanUp then
        _G.VortexCleanUp()
    end
    if ScreenGui then
        ScreenGui:Destroy()
    end
    print("[Vortex Hub] Encerramento completo concluído.")
end)

--========================================================--
-- 7. EVENTOS E NAVEGAÇÃO
--========================================================--

Connect(Search:GetPropertyChangedSignal("Text"), function()
    local query = Search.Text:lower():gsub("%s+", "")
    for _, elem in ipairs(Elements) do
        if query ~= "" then
            elem.Instance.Visible = (elem.Name:find(query, 1, true) ~= nil)
        else
            elem.Instance.Visible = (elem.Page == State.CurrentPage)
        end
    end
end)

local function ToggleUI()
    State.Open = not State.Open
    if State.Open then
        Main.Visible = true
        Tween(Main, 0.25, {Size = UDim2.fromOffset(Config.Width, Config.Height)}, Enum.EasingStyle.Back)
    else
        Tween(Main, 0.18, {Size = UDim2.fromOffset(0, 0)}):Completed():Connect(function()
            if not State.Open then Main.Visible = false end
        end)
    end
end

Connect(FloatingButton.Activated, ToggleUI)
Connect(CloseBtn.Activated, ToggleUI)

Connect(MinimizeBtn.Activated, function()
    State.Minimized = not State.Minimized
    Tween(Body, 0.2, {Size = State.Minimized and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 1, -50)})
    MinimizeBtn.Text = State.Minimized and "+" or "—"
end)

SelectPage("Home")

--========================================================--
-- 8. INTEGRAÇÃO E INICIALIZAÇÃO VIA LOADER
--========================================================--

function MainModule.Init(Modules)
    if type(Modules) == "table" then
        LoadedModules.Farm = Modules.Farm
        LoadedModules.Combat = Modules.Combat
        LoadedModules.Bypass = Modules.Bypass
    end
    print("[Vortex Hub] Módulo 1 (Main) conectado com os módulos de lógica!")
end

print("[Vortex Hub] Módulo 1 (Interface Completa) carregado!")

return MainModule
