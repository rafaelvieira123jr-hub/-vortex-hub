--[[
    VORTEX HUB - INTERFACE FRAMEWORK
    Arquivo: main.lua

    Interface responsiva Mobile/PC
    e ponte de comunicação com os módulos.
--]]

--========================================================--
-- 1. SERVIÇOS / LIMPEZA
--========================================================--

if _G.VortexCleanUp then
    pcall(_G.VortexCleanUp)
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local OldUI = PlayerGui:FindFirstChild("VortexHub")
if OldUI then
    OldUI:Destroy()
end

local Connections = {}

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

_G.VortexCleanUp = function()
    for _, connection in ipairs(Connections) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    table.clear(Connections)
end

--========================================================--
-- 2. MÓDULO PRINCIPAL
--========================================================--

local MainModule = {}

local LoadedModules = {
    Farm = nil,
    Combat = nil,
    Bypass = nil
}

--========================================================--
-- 3. CONFIGURAÇÃO
--========================================================--

local Config = {
    Name = "VORTEX HUB",
    SubTitle = "Meme Sea Edition",
    Version = "v1.0.3",

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
-- 4. UTILITÁRIOS
--========================================================--

local function Tween(object, duration, properties, style, direction)
    if not object then
        return nil
    end

    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(
        object,
        tweenInfo,
        properties
    )

    tween:Play()

    return tween
end

local function Corner(object, radius)
    local corner = Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(
            0,
            radius or Config.Radius
        )

    corner.Parent = object

    return corner
end

local function Stroke(object, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")

    stroke.Color =
        color or Config.Accent

    stroke.Transparency =
        transparency or 0.7

    stroke.Thickness =
        thickness or 1

    stroke.ApplyStrokeMode =
        Enum.ApplyStrokeMode.Border

    stroke.Parent = object

    return stroke
end

--========================================================--
-- 5. DRAG
--========================================================--

local function MakeDraggable(handle, object)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    Connect(handle.InputBegan, function(input)
        if input.UserInputType
            ~= Enum.UserInputType.MouseButton1
            and input.UserInputType
            ~= Enum.UserInputType.Touch then

            return
        end

        dragging = true
        dragStart = input.Position
        startPos = object.Position

        local changedConnection

        changedConnection = input.Changed:Connect(function()
            if input.UserInputState
                == Enum.UserInputState.End then

                dragging = false

                if changedConnection then
                    changedConnection:Disconnect()
                end
            end
        end)
    end)

    Connect(UserInputService.InputChanged, function(input)
        if not dragging then
            return
        end

        if input.UserInputType
            ~= Enum.UserInputType.MouseMovement
            and input.UserInputType
            ~= Enum.UserInputType.Touch then

            return
        end

        local delta =
            input.Position - dragStart

        local camera =
            workspace.CurrentCamera

        local viewport =
            camera
            and camera.ViewportSize
            or Vector2.new(800, 600)

        local size =
            object.AbsoluteSize

        local x =
            math.clamp(
                startPos.X.Offset + delta.X,
                5,
                math.max(
                    5,
                    viewport.X - size.X - 5
                )
            )

        local y =
            math.clamp(
                startPos.Y.Offset + delta.Y,
                5,
                math.max(
                    5,
                    viewport.Y - size.Y - 5
                )
            )

        object.Position =
            UDim2.fromOffset(x, y)
    end)
end

--========================================================--
-- 6. SCREEN GUI
--========================================================--

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "VortexHub"

ScreenGui.ResetOnSpawn =
    false

ScreenGui.IgnoreGuiInset =
    true

ScreenGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.ScreenInsets =
        Enum.ScreenInsets.None
end)

ScreenGui.Parent =
    PlayerGui

local UIScale =
    Instance.new("UIScale")

UIScale.Parent =
    ScreenGui

local function UpdateScale()
    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport =
        camera.ViewportSize

    if viewport.X <= 600 then

        UIScale.Scale =
            math.clamp(
                viewport.X / 640,
                0.65,
                0.85
            )

    elseif viewport.X <= 1024 then

        UIScale.Scale = 0.9

    else

        UIScale.Scale = 1

    end
end

Connect(
    RunService.RenderStepped,
    UpdateScale
)

UpdateScale()

--========================================================--
-- 7. BOTÃO FLUTUANTE
--========================================================--

local FloatingButton =
    Instance.new("TextButton")

FloatingButton.Name =
    "FloatingButton"

FloatingButton.Size =
    UDim2.fromOffset(50, 50)

FloatingButton.Position =
    UDim2.new(0, 15, 0.4, 0)

FloatingButton.BackgroundColor3 =
    Config.CardColor

FloatingButton.Text = ""

FloatingButton.AutoButtonColor =
    false

FloatingButton.Parent =
    ScreenGui

Corner(FloatingButton, 16)

Stroke(
    FloatingButton,
    Config.Accent,
    0.3,
    1.5
)

local FloatingIcon =
    Instance.new("TextLabel")

FloatingIcon.Size =
    UDim2.new(1, 0, 1, 0)

FloatingIcon.BackgroundTransparency =
    1

FloatingIcon.Text =
    "V"

FloatingIcon.TextColor3 =
    Config.AccentGlow

FloatingIcon.TextSize =
    22

FloatingIcon.Font =
    Enum.Font.GothamBold

FloatingIcon.Parent =
    FloatingButton

MakeDraggable(
    FloatingButton,
    FloatingButton
)

--========================================================--
-- 8. JANELA PRINCIPAL
--========================================================--

local Main =
    Instance.new("Frame")

Main.Name =
    "Main"

Main.Size =
    UDim2.fromOffset(
        Config.Width,
        Config.Height
    )

Main.Position =
    UDim2.new(
        0.5,
        -Config.Width / 2,
        0.5,
        -Config.Height / 2
    )

Main.BackgroundColor3 =
    Config.Background

Main.BackgroundTransparency =
    Config.BackgroundTransparency

Main.ClipsDescendants =
    true

Main.Parent =
    ScreenGui

Corner(Main, Config.Radius)

Stroke(
    Main,
    Config.Accent,
    0.5,
    1.5
)

--========================================================--
-- 9. TOPBAR
--========================================================--

local Topbar =
    Instance.new("Frame")

Topbar.Name =
    "Topbar"

Topbar.Size =
    UDim2.new(1, 0, 0, 50)

Topbar.BackgroundColor3 =
    Config.SidebarColor

Topbar.BorderSizePixel =
    0

Topbar.Parent =
    Main

local Title =
    Instance.new("TextLabel")

Title.Position =
    UDim2.fromOffset(16, 7)

Title.Size =
    UDim2.fromOffset(250, 22)

Title.Text =
    Config.Name

Title.TextColor3 =
    Config.Text

Title.TextSize =
    16

Title.Font =
    Enum.Font.GothamBold

Title.TextXAlignment =
    Enum.TextXAlignment.Left

Title.BackgroundTransparency =
    1

Title.Parent =
    Topbar

local SubTitle =
    Instance.new("TextLabel")

SubTitle.Position =
    UDim2.fromOffset(16, 28)

SubTitle.Size =
    UDim2.fromOffset(300, 14)

SubTitle.Text =
    Config.SubTitle
    .. " | "
    .. Config.Version

SubTitle.TextColor3 =
    Config.SubText

SubTitle.TextSize =
    10

SubTitle.Font =
    Enum.Font.Gotham

SubTitle.TextXAlignment =
    Enum.TextXAlignment.Left

SubTitle.BackgroundTransparency =
    1

SubTitle.Parent =
    Topbar

local CloseBtn =
    Instance.new("TextButton")

CloseBtn.Size =
    UDim2.fromOffset(36, 36)

CloseBtn.Position =
    UDim2.new(1, -43, 0, 7)

CloseBtn.BackgroundColor3 =
    Config.CardColor

CloseBtn.Text =
    "×"

CloseBtn.TextColor3 =
    Config.Text

CloseBtn.TextSize =
    20

CloseBtn.Font =
    Enum.Font.GothamBold

CloseBtn.AutoButtonColor =
    false

CloseBtn.Parent =
    Topbar

Corner(CloseBtn, 8)

local MinimizeBtn =
    Instance.new("TextButton")

MinimizeBtn.Size =
    UDim2.fromOffset(36, 36)

MinimizeBtn.Position =
    UDim2.new(1, -84, 0, 7)

MinimizeBtn.BackgroundColor3 =
    Config.CardColor

MinimizeBtn.Text =
    "—"

MinimizeBtn.TextColor3 =
    Config.Text

MinimizeBtn.TextSize =
    14

MinimizeBtn.Font =
    Enum.Font.GothamBold

MinimizeBtn.AutoButtonColor =
    false

MinimizeBtn.Parent =
    Topbar

Corner(MinimizeBtn, 8)

MakeDraggable(
    Topbar,
    Main
)

--========================================================--
-- 10. BODY
--========================================================--

local Body =
    Instance.new("Frame")

Body.Name =
    "Body"

Body.Size =
    UDim2.new(1, 0, 1, -50)

Body.Position =
    UDim2.fromOffset(0, 50)

Body.BackgroundTransparency =
    1

Body.Parent =
    Main

--========================================================--
-- 11. SIDEBAR
--========================================================--

local Sidebar =
    Instance.new("ScrollingFrame")

Sidebar.Name =
    "Sidebar"

Sidebar.Size =
    UDim2.new(0, 140, 1, 0)

Sidebar.BackgroundColor3 =
    Config.SidebarColor

Sidebar.BorderSizePixel =
    0

Sidebar.ScrollBarThickness =
    0

Sidebar.AutomaticCanvasSize =
    Enum.AutomaticSize.Y

Sidebar.CanvasSize =
    UDim2.new()

Sidebar.Parent =
    Body

local SidebarLayout =
    Instance.new("UIListLayout")

SidebarLayout.Padding =
    UDim.new(0, 6)

SidebarLayout.SortOrder =
    Enum.SortOrder.LayoutOrder

SidebarLayout.Parent =
    Sidebar

local SidebarPadding =
    Instance.new("UIPadding")

SidebarPadding.PaddingTop =
    UDim.new(0, 10)

SidebarPadding.PaddingLeft =
    UDim.new(0, 8)

SidebarPadding.PaddingRight =
    UDim.new(0, 8)

SidebarPadding.PaddingBottom =
    UDim.new(0, 10)

SidebarPadding.Parent =
    Sidebar

--========================================================--
-- 12. CONTENT
--========================================================--

local Content =
    Instance.new("Frame")

Content.Name =
    "Content"

Content.Size =
    UDim2.new(1, -140, 1, 0)

Content.Position =
    UDim2.fromOffset(140, 0)

Content.BackgroundTransparency =
    1

Content.Parent =
    Body

--========================================================--
-- 13. SEARCH
--========================================================--

local Search =
    Instance.new("TextBox")

Search.Name =
    "Search"

Search.Size =
    UDim2.new(1, -20, 0, 36)

Search.Position =
    UDim2.fromOffset(10, 10)

Search.BackgroundColor3 =
    Config.CardColor

Search.PlaceholderText =
    "🔍 Pesquisar funcionalidade..."

Search.PlaceholderColor3 =
    Config.SubText

Search.Text = ""

Search.TextColor3 =
    Config.Text

Search.TextSize =
    11

Search.Font =
    Enum.Font.Gotham

Search.ClearTextOnFocus =
    false

Search.Parent =
    Content

Corner(Search, 8)

Stroke(
    Search,
    Config.Accent,
    0.8,
    1
)

local SearchPadding =
    Instance.new("UIPadding")

SearchPadding.PaddingLeft =
    UDim.new(0, 12)

SearchPadding.Parent =
    Search

--========================================================--
-- 14. PÁGINAS
--========================================================--

local Pages = {}
local Tabs = {}
local Elements = {}

local function CreatePage(name)
    local page =
        Instance.new("ScrollingFrame")

    page.Name =
        name .. "Page"

    page.Size =
        UDim2.new(1, -20, 1, -56)

    page.Position =
        UDim2.fromOffset(10, 52)

    page.BackgroundTransparency =
        1

    page.BorderSizePixel =
        0

    page.ScrollBarThickness =
        2

    page.ScrollBarImageColor3 =
        Config.Accent

    page.AutomaticCanvasSize =
        Enum.AutomaticSize.Y

    page.CanvasSize =
        UDim2.new()

    page.Visible = false

    page.Parent =
        Content

    local layout =
        Instance.new("UIListLayout")

    layout.Padding =
        UDim.new(0, 8)

    layout.SortOrder =
        Enum.SortOrder.LayoutOrder

    layout.Parent =
        page

    local padding =
        Instance.new("UIPadding")

    padding.PaddingTop =
        UDim.new(0, 4)

    padding.PaddingBottom =
        UDim.new(0, 12)

    padding.PaddingRight =
        UDim.new(0, 4)

    padding.Parent =
        page

    Pages[name] =
        page

    return page
end

local function SelectPage(name)
    if not Pages[name] then
        return
    end

    State.CurrentPage =
        name

    for pageName, page in pairs(Pages) do
        page.Visible =
            pageName == name
    end

    for tabName, tab in pairs(Tabs) do

        local selected =
            tabName == name

        Tween(
            tab,
            0.15,
            {
                BackgroundColor3 =
                    selected
                    and Config.Accent
                    or Config.CardColor,

                TextColor3 =
                    selected
                    and Config.Text
                    or Config.SubText
            }
        )
    end

    Search.Text = ""
end

local function CreateTab(name, icon)
    local tab =
        Instance.new("TextButton")

    tab.Name =
        name

    tab.Size =
        UDim2.new(1, 0, 0, 36)

    tab.BackgroundColor3 =
        Config.CardColor

    tab.Text =
        (icon and icon .. "  " or "")
        .. name

    tab.TextColor3 =
        Config.SubText

    tab.TextSize =
        11

    tab.Font =
        Enum.Font.GothamMedium

    tab.TextXAlignment =
        Enum.TextXAlignment.Left

    tab.AutoButtonColor =
        false

    tab.Parent =
        Sidebar

    Corner(tab, 8)

    local padding =
        Instance.new("UIPadding")

    padding.PaddingLeft =
        UDim.new(0, 10)

    padding.Parent =
        tab

    Tabs[name] =
        tab

    Connect(
        tab.Activated,
        function()
            SelectPage(name)
        end
    )

    return tab
end

local function RegisterElement(
    pageName,
    instance,
    displayName
)
    table.insert(
        Elements,
        {
            Page = pageName,
            Instance = instance,
            Name = tostring(displayName):lower()
        }
    )
end

--========================================================--
-- 15. COMPONENTES
--========================================================--

local function CreateSection(parent, title)
    local label =
        Instance.new("TextLabel")

    label.Size =
        UDim2.new(1, 0, 0, 22)

    label.Text =
        tostring(title):upper()

    label.TextColor3 =
        Config.AccentGlow

    label.TextSize =
        10

    label.Font =
        Enum.Font.GothamBold

    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.BackgroundTransparency =
        1

    label.Parent =
        parent

    return label
end

local function CreateButton(
    parent,
    pageName,
    text,
    callback
)
    local button =
        Instance.new("TextButton")

    button.Size =
        UDim2.new(1, 0, 0, 40)

    button.BackgroundColor3 =
        Config.CardColor

    button.Text =
        text

    button.TextColor3 =
        Config.Text

    button.TextSize =
        11

    button.Font =
        Enum.Font.GothamMedium

    button.AutoButtonColor =
        false

    button.Parent =
        parent

    Corner(button, 8)

    Stroke(
        button,
        Config.CardHover,
        0.5,
        1
    )

    RegisterElement(
        pageName,
        button,
        text
    )

    Connect(
        button.Activated,
        function()

            local tween =
                Tween(
                    button,
                    0.08,
                    {
                        BackgroundColor3 =
                            Config.AccentDark
                    }
                )

            task.spawn(function()
                if tween then
                    pcall(function()
                        tween.Completed:Wait()
                    end)
                end

                if button.Parent then
                    Tween(
                        button,
                        0.12,
                        {
                            BackgroundColor3 =
                                Config.CardColor
                        }
                    )
                end
            end)

            if callback then
                task.spawn(callback)
            end
        end
    )

    return button
end

local function CreateToggle(
    parent,
    pageName,
    text,
    default,
    callback
)
    local enabled =
        default == true

    local frame =
        Instance.new("Frame")

    frame.Size =
        UDim2.new(1, 0, 0, 42)

    frame.BackgroundColor3 =
        Config.CardColor

    frame.Parent =
        parent

    Corner(frame, 8)

    local label =
        Instance.new("TextLabel")

    label.Position =
        UDim2.fromOffset(12, 0)

    label.Size =
        UDim2.new(1, -65, 1, 0)

    label.Text =
        text

    label.TextColor3 =
        Config.Text

    label.TextSize =
        11

    label.Font =
        Enum.Font.GothamMedium

    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.BackgroundTransparency =
        1

    label.Parent =
        frame

    local switch =
        Instance.new("TextButton")

    switch.Size =
        UDim2.fromOffset(42, 22)

    switch.Position =
        UDim2.new(1, -50, 0.5, -11)

    switch.BackgroundColor3 =
        enabled
        and Config.Accent
        or Color3.fromRGB(40, 42, 54)

    switch.Text = ""

    switch.AutoButtonColor =
        false

    switch.Parent =
        frame

    Corner(switch, 12)

    local knob =
        Instance.new("Frame")

    knob.Size =
        UDim2.fromOffset(16, 16)

    knob.Position =
        enabled
        and UDim2.fromOffset(22, 3)
        or UDim2.fromOffset(3, 3)

    knob.BackgroundColor3 =
        Config.Text

    knob.Parent =
        switch

    Corner(knob, 10)

    RegisterElement(
        pageName,
        frame,
        text
    )

    local function SetState(newState)
        enabled =
            newState == true

        State.Toggles[text] =
            enabled

        Tween(
            switch,
            0.15,
            {
                BackgroundColor3 =
                    enabled
                    and Config.Accent
                    or Color3.fromRGB(40, 42, 54)
            }
        )

        Tween(
            knob,
            0.15,
            {
                Position =
                    enabled
                    and UDim2.fromOffset(22, 3)
                    or UDim2.fromOffset(3, 3)
            }
        )

        if callback then
            task.spawn(
                callback,
                enabled
            )
        end
    end

    Connect(
        switch.Activated,
        function()
            SetState(not enabled)
        end
    )

    return {
        Set = SetState,

        Get = function()
            return enabled
        end
    }
end

local function CreateSlider(
    parent,
    pageName,
    text,
    min,
    max,
    default,
    callback
)
    min = tonumber(min) or 0
    max = tonumber(max) or 100

    if max <= min then
        max = min + 1
    end

    local value =
        math.clamp(
            tonumber(default) or min,
            min,
            max
        )

    local frame =
        Instance.new("Frame")

    frame.Size =
        UDim2.new(1, 0, 0, 52)

    frame.BackgroundColor3 =
        Config.CardColor

    frame.Parent =
        parent

    Corner(frame, 8)

    local label =
        Instance.new("TextLabel")

    label.Position =
        UDim2.fromOffset(12, 6)

    label.Size =
        UDim2.new(0.6, 0, 0, 18)

    label.Text =
        text

    label.TextColor3 =
        Config.Text

    label.TextSize =
        11

    label.Font =
        Enum.Font.GothamMedium

    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.BackgroundTransparency =
        1

    label.Parent =
        frame

    local valueLabel =
        Instance.new("TextLabel")

    valueLabel.Position =
        UDim2.new(1, -62, 0, 6)

    valueLabel.Size =
        UDim2.fromOffset(50, 18)

    valueLabel.Text =
        tostring(value)

    valueLabel.TextColor3 =
        Config.AccentGlow

    valueLabel.TextSize =
        11

    valueLabel.Font =
        Enum.Font.GothamBold

    valueLabel.TextXAlignment =
        Enum.TextXAlignment.Right

    valueLabel.BackgroundTransparency =
        1

    valueLabel.Parent =
        frame

    local track =
        Instance.new("Frame")

    track.Size =
        UDim2.new(1, -24, 0, 6)

    track.Position =
        UDim2.fromOffset(12, 34)

    track.BackgroundColor3 =
        Color3.fromRGB(35, 37, 50)

    track.Parent =
        frame

    Corner(track, 4)

    local fill =
        Instance.new("Frame")

    fill.Size =
        UDim2.new(
            (value - min) / (max - min),
            0,
            1,
            0
        )

    fill.BackgroundColor3 =
        Config.Accent

    fill.Parent =
        track

    Corner(fill, 4)

    local dragButton =
        Instance.new("TextButton")

    dragButton.Size =
        UDim2.new(1, 0, 1, 10)

    dragButton.Position =
        UDim2.fromOffset(0, -5)

    dragButton.BackgroundTransparency =
        1

    dragButton.Text = ""

    dragButton.Parent =
        track

    RegisterElement(
        pageName,
        frame,
        text
    )

    local dragging = false

    local function UpdateInput(input)
        local trackWidth =
            track.AbsoluteSize.X

        if trackWidth <= 0 then
            return
        end

        local x =
            input.Position.X
            - track.AbsolutePosition.X

        local alpha =
            math.clamp(
                x / trackWidth,
                0,
                1
            )

        value =
            math.floor(
                min
                + (max - min) * alpha
            )

        fill.Size =
            UDim2.new(
                alpha,
                0,
                1,
                0
            )

        valueLabel.Text =
            tostring(value)

        State.Values[text] =
            value

        if callback then
            task.spawn(
                callback,
                value
            )
        end
    end

    Connect(
        dragButton.InputBegan,
        function(input)

            if input.UserInputType
                ~= Enum.UserInputType.MouseButton1
                and input.UserInputType
                ~= Enum.UserInputType.Touch then

                return
            end

            dragging = true
            UpdateInput(input)
        end
    )

    Connect(
        UserInputService.InputChanged,
        function(input)

            if not dragging then
                return
            end

            if input.UserInputType
                ~= Enum.UserInputType.MouseMovement
                and input.UserInputType
                ~= Enum.UserInputType.Touch then

                return
            end

            UpdateInput(input)
        end
    )

    Connect(
        UserInputService.InputEnded,
        function(input)

            if input.UserInputType
                == Enum.UserInputType.MouseButton1
                or input.UserInputType
                == Enum.UserInputType.Touch then

                dragging = false
            end
        end
    )

    return {
        Set = function(newValue)
            value =
                math.clamp(
                    tonumber(newValue)
                        or min,
                    min,
                    max
                )

            local alpha =
                (value - min)
                / (max - min)

            fill.Size =
                UDim2.new(
                    alpha,
                    0,
                    1,
                    0
                )

            valueLabel.Text =
                tostring(value)

            State.Values[text] =
                value

            if callback then
                task.spawn(
                    callback,
                    value
                )
            end
        end,

        Get = function()
            return value
        end
    }
end

--========================================================--
-- 16. PÁGINAS / TABS
--========================================================--

local HomePage =
    CreatePage("Home")

local FarmPage =
    CreatePage("Farm")

local CombatPage =
    CreatePage("Combat")

local TeleportPage =
    CreatePage("Teleport")

local SettingsPage =
    CreatePage("Settings")

CreateTab("Home", "🏠")
CreateTab("Farm", "🌾")
CreateTab("Combat", "⚔️")
CreateTab("Teleport", "🌀")
CreateTab("Settings", "⚙️")

--========================================================--
-- 17. HOME
--========================================================--

CreateSection(
    HomePage,
    "Informações"
)

CreateButton(
    HomePage,
    "Home",
    "Checar FPS",
    function()

        local fps = 0

        pcall(function()
            fps =
                math.floor(
                    workspace:GetRealPhysicsFPS()
                )
        end)

        print(
            "[Vortex Hub] FPS:",
            fps
        )
    end
)

CreateButton(
    HomePage,
    "Home",
    "Copiar Link do Jogo",
    function()

        local url =
            "https://www.roblox.com/games/"
            .. tostring(game.PlaceId)

        if type(setclipboard) == "function" then
            pcall(function()
                setclipboard(url)
            end)

            print(
                "[Vortex Hub] Link copiado."
            )
        else
            print(
                "[Vortex Hub] setclipboard não disponível."
            )
        end
    end
)

CreateButton(
    HomePage,
    "Home",
    "Reentrar no Servidor",
    function()

        pcall(function()
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                game.JobId,
                LocalPlayer
            )
        end)
    end
)

--========================================================--
-- 18. FARM
--========================================================--

CreateSection(
    FarmPage,
    "Farm"
)

CreateToggle(
    FarmPage,
    "Farm",
    "Auto Farm",
    false,
    function(enabled)

        if LoadedModules.Farm
            and type(
                LoadedModules.Farm.SetFarmState
            ) == "function" then

            local success, err =
                pcall(function()
                    LoadedModules.Farm.SetFarmState(
                        enabled
                    )
                end)

            if not success then
                warn(
                    "[Vortex Hub] Auto Farm: "
                    .. tostring(err)
                )
            end
        end
    end
)

CreateToggle(
    FarmPage,
    "Farm",
    "Auto Quest",
    false,
    function(enabled)

        if LoadedModules.Farm
            and LoadedModules.Farm.Config then

            LoadedModules.Farm.Config.AutoQuest =
                enabled
        end
    end
)

CreateToggle(
    FarmPage,
    "Farm",
    "Farm Bosses",
    false,
    function(enabled)

        if LoadedModules.Farm
            and LoadedModules.Farm.Config then

            LoadedModules.Farm.Config.FarmBosses =
                enabled
        end
    end
)

CreateSlider(
    FarmPage,
    "Farm",
    "Distância do Alvo",
    3,
    20,
    9,
    function(value)

        if LoadedModules.Farm
            and LoadedModules.Farm.Config then

            LoadedModules.Farm.Config.Distance =
                value
        end
    end
)

--========================================================--
-- 19. COMBAT
--========================================================--

CreateSection(
    CombatPage,
    "Combate"
)

CreateToggle(
    CombatPage,
    "Combat",
    "Auto Click / Attack",
    false,
    function(enabled)

        if LoadedModules.Combat
            and type(
                LoadedModules.Combat.SetAutoClick
            ) == "function" then

            LoadedModules.Combat.SetAutoClick(
                enabled
            )
        end
    end
)

CreateToggle(
    CombatPage,
    "Combat",
    "Auto Equipar Arma",
    false,
    function(enabled)

        if LoadedModules.Combat
            and type(
                LoadedModules.Combat.SetAutoEquip
            ) == "function" then

            LoadedModules.Combat.SetAutoEquip(
                enabled
            )
        end
    end
)

local Skills = {
    {"Z", "Usar Skill [Z]"},
    {"X", "Usar Skill [X]"},
    {"C", "Usar Skill [C]"},
    {"V", "Usar Skill [V]"}
}

CreateSection(
    CombatPage,
    "Habilidades"
)

for _, skill in ipairs(Skills) do

    local key =
        skill[1]

    local text =
        skill[2]

    CreateToggle(
        CombatPage,
        "Combat",
        text,
        false,
        function(enabled)

            if LoadedModules.Combat
                and type(
                    LoadedModules.Combat.SetSkillState
                ) == "function" then

                LoadedModules.Combat.SetSkillState(
                    key,
                    enabled
                )
            end
        end
    )
end

--========================================================--
-- 20. TELEPORTE
--========================================================--

CreateSection(
    TeleportPage,
    "Teleporte"
)

local function TeleportToCFrame(cframe)
    local character =
        LocalPlayer.Character

    local root =
        character
        and character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root then
        return
    end

    root.CFrame =
        cframe
end

CreateButton(
    TeleportPage,
    "Teleport",
    "Ilha Iniciar (Floppa Island)",
    function()
        TeleportToCFrame(
            CFrame.new(
                -611,
                15,
                -2174
            )
        )
    end
)

CreateButton(
    TeleportPage,
    "Teleport",
    "Ilha Popcat",
    function()
        TeleportToCFrame(
            CFrame.new(
                -1230,
                15,
                -3150
            )
        )
    end
)

CreateButton(
    TeleportPage,
    "Teleport",
    "Ilha Cheems",
    function()
        TeleportToCFrame(
            CFrame.new(
                1850,
                15,
                -1120
            )
        )
    end
)

CreateButton(
    TeleportPage,
    "Teleport",
    "Ilha Gigachad",
    function()
        TeleportToCFrame(
            CFrame.new(
                -3200,
                15,
                1450
            )
        )
    end
)

--========================================================--
-- 21. SETTINGS
--========================================================--

CreateSection(
    SettingsPage,
    "Interface"
)

CreateButton(
    SettingsPage,
    "Settings",
    "Ocultar Interface",
    function()
        State.Open = false
        Main.Visible = false
    end
)

CreateButton(
    SettingsPage,
    "Settings",
    "Destruir Interface",
    function()

        if LoadedModules.Farm
            and type(
                LoadedModules.Farm.SetFarmState
            ) == "function" then

            pcall(function()
                LoadedModules.Farm.SetFarmState(false)
            end)
        end

        if LoadedModules.Combat
            and type(
                LoadedModules.Combat.Stop
            ) == "function" then

            pcall(function()
                LoadedModules.Combat.Stop()
            end)

        elseif LoadedModules.Combat
            and type(
                LoadedModules.Combat.SetAutoClick
            ) == "function" then

            pcall(function()
                LoadedModules.Combat.SetAutoClick(false)
            end)
        end

        if _G.VortexCleanUp then
            pcall(_G.VortexCleanUp)
        end

        if ScreenGui then
            ScreenGui:Destroy()
        end

        print(
            "[Vortex Hub] Interface encerrada."
        )
    end
)

--========================================================--
-- 22. PESQUISA
--========================================================--

Connect(
    Search:GetPropertyChangedSignal("Text"),
    function()

        local query =
            Search.Text:lower():gsub(
                "%s+",
                ""
            )

        if query == "" then
            for _, element in ipairs(Elements) do
                element.Instance.Visible =
                    element.Page
                    == State.CurrentPage
            end

            return
        end

        for _, element in ipairs(Elements) do

            local matches =
                element.Name:find(
                    query,
                    1,
                    true
                ) ~= nil

            local samePage =
                element.Page
                == State.CurrentPage

            element.Instance.Visible =
                matches and samePage
        end
    end
)

--========================================================--
-- 23. ABRIR / FECHAR
--========================================================--

local function ToggleUI()

    State.Open =
        not State.Open

    if State.Open then

        Main.Visible = true

        Tween(
            Main,
            0.25,
            {
                Size =
                    UDim2.fromOffset(
                        Config.Width,
                        Config.Height
                    )
            },
            Enum.EasingStyle.Back
        )

    else

        local tween =
            Tween(
                Main,
                0.18,
                {
                    Size =
                        UDim2.fromOffset(0, 0)
                }
            )

        if tween then
            task.spawn(function()
                pcall(function()
                    tween.Completed:Wait()
                end)

                if not State.Open
                    and Main.Parent then

                    Main.Visible = false
                end
            end)
        end
    end
end

Connect(
    FloatingButton.Activated,
    ToggleUI
)

Connect(
    CloseBtn.Activated,
    ToggleUI
)

--========================================================--
-- 24. MINIMIZAR
--========================================================--

Connect(
    MinimizeBtn.Activated,
    function()

        State.Minimized =
            not State.Minimized

        Tween(
            Body,
            0.2,
            {
                Size =
                    State.Minimized
                    and UDim2.new(
                        1,
                        0,
                        0,
                        0
                    )
                    or UDim2.new(
                        1,
                        0,
                        1,
                        -50
                    )
            }
        )

        MinimizeBtn.Text =
            State.Minimized
            and "+"
            or "—"
    end
)

--========================================================--
-- 25. PÁGINA INICIAL
--========================================================--

SelectPage("Home")

--========================================================--
-- 26. INTEGRAÇÃO COM LOADER
--========================================================--

function MainModule.Init(Modules)

    if type(Modules) ~= "table" then
        return false
    end

    LoadedModules.Farm =
        Modules.Farm

    LoadedModules.Combat =
        Modules.Combat

    LoadedModules.Bypass =
        Modules.Bypass

    -- Conecta Farm -> Combat quando disponível.
    if LoadedModules.Farm
        and LoadedModules.Combat
        and type(
            LoadedModules.Farm.SetCombatModule
        ) == "function" then

        pcall(function()
            LoadedModules.Farm.SetCombatModule(
                LoadedModules.Combat
            )
        end)
    end

    print(
        "[Vortex Hub] Módulos conectados."
    )

    return true
end

--========================================================--
-- 27. FINAL
--========================================================--

print(
    "[Vortex Hub] Interface carregada."
)

return MainModule
