--[[
    VORTEX HUB - LOADER OPTIMIZED (MOBILE HTTP FIX)
    Arquivo: loader.lua
--]]

local GitHubUser = "rafaelvieira123jr-hub"
local Repository = "-vortex-hub"
local Branch = "main"

local BaseURL =
    "https://raw.githubusercontent.com/"
    .. GitHubUser .. "/"
    .. Repository .. "/"
    .. Branch .. "/"

getgenv().VortexHub = getgenv().VortexHub or {
    Loaded = false,
    Modules = {}
}

-- Evita executar duas vezes
if getgenv().VortexHub.Loaded then
    warn("[Vortex Hub] O script já está em execução!")
    return
end

-- =========================================================
-- CARREGADOR DE MÓDULOS
-- =========================================================

local function LoadModule(moduleName)
    print("[Vortex Hub] Baixando: " .. moduleName .. "...")

    local url = BaseURL
        .. moduleName
        .. "?nocache="
        .. tostring(os.time())

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn(
            "[Vortex Hub Error] Falha ao acessar "
            .. moduleName
            .. ": "
            .. tostring(response)
        )
        return nil
    end

    if not response
        or #response <= 10
        or response == "404: Not Found" then

        warn(
            "[Vortex Hub Error] Falha de conexão ao baixar: "
            .. moduleName
        )
        return nil
    end

    local codeFunction, compileErr = loadstring(response)

    if not codeFunction then
        warn(
            "[Vortex Hub Error] Erro de sintaxe em "
            .. moduleName
            .. ": "
            .. tostring(compileErr)
        )
        return nil
    end

    local execSuccess, resultModule = pcall(codeFunction)

    if not execSuccess then
        warn(
            "[Vortex Hub Error] Erro ao executar "
            .. moduleName
            .. ": "
            .. tostring(resultModule)
        )
        return nil
    end

    print(
        "[Vortex Hub] Módulo '"
        .. moduleName
        .. "' carregado com sucesso!"
    )

    getgenv().VortexHub.Modules[moduleName] = resultModule

    return resultModule
end

-- =========================================================
-- INICIALIZAÇÃO
-- =========================================================

print("[Vortex Hub] Iniciando ecossistema Vortex Hub...")

local bypassModule = LoadModule("bypass.lua")
local farmModule = LoadModule("farm.lua")
local combatModule = LoadModule("combat.lua")

-- =========================================================
-- CARREGAMENTO DA INTERFACE
-- =========================================================

local mainModule = LoadModule("main.lua")

if not mainModule then

    warn("[Vortex Hub] Carregando interface otimizada para mobile...")

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Remove interface anterior
    local oldUI = PlayerGui:FindFirstChild("VortexHubUI")

    if oldUI then
        oldUI:Destroy()
    end

    -- =====================================================
    -- SCREEN GUI
    -- =====================================================

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VortexHubUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    -- =====================================================
    -- BOTÃO FLUTUANTE
    -- =====================================================

    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Name = "OpenButton"
    OpenBtn.Size = UDim2.fromOffset(45, 45)
    OpenBtn.Position = UDim2.new(0, 15, 0.4, 0)

    OpenBtn.BackgroundColor3 =
        Color3.fromRGB(138, 92, 255)

    OpenBtn.Text = "V"
    OpenBtn.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    OpenBtn.TextSize = 22
    OpenBtn.Font = Enum.Font.GothamBold

    OpenBtn.Active = true
    OpenBtn.Draggable = true

    OpenBtn.Parent = ScreenGui

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(1, 0)
    BtnCorner.Parent = OpenBtn

    -- =====================================================
    -- PAINEL PRINCIPAL
    -- =====================================================

    local Frame = Instance.new("Frame")
    Frame.Name = "MainFrame"

    Frame.Size =
        UDim2.fromOffset(280, 180)

    Frame.Position =
        UDim2.new(0.5, -140, 0.5, -90)

    Frame.BackgroundColor3 =
        Color3.fromRGB(20, 20, 28)

    Frame.Visible = true
    Frame.Active = true
    Frame.Draggable = true

    Frame.Parent = ScreenGui

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius =
        UDim.new(0, 10)

    FrameCorner.Parent = Frame

    -- =====================================================
    -- TÍTULO
    -- =====================================================

    local Title = Instance.new("TextLabel")

    Title.Size =
        UDim2.new(1, 0, 0, 35)

    Title.BackgroundTransparency = 1

    Title.Text = "VORTEX HUB - MEME SEA"

    Title.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold

    Title.Parent = Frame

    -- =====================================================
    -- BOTÃO AUTO FARM
    -- =====================================================

    local ToggleFarm = Instance.new("TextButton")

    ToggleFarm.Name = "ToggleFarm"

    ToggleFarm.Size =
        UDim2.new(0.85, 0, 0, 40)

    ToggleFarm.Position =
        UDim2.new(0.075, 0, 0.35, 0)

    ToggleFarm.BackgroundColor3 =
        Color3.fromRGB(138, 92, 255)

    ToggleFarm.Text = "Auto Farm: OFF"

    ToggleFarm.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    ToggleFarm.Font =
        Enum.Font.GothamMedium

    ToggleFarm.TextSize = 14

    ToggleFarm.Parent = Frame

    local ToggleCorner = Instance.new("UICorner")

    ToggleCorner.CornerRadius =
        UDim.new(0, 6)

    ToggleCorner.Parent = ToggleFarm

    -- =====================================================
    -- ESTADO DO FARM
    -- =====================================================

    local farmActive = false

    ToggleFarm.MouseButton1Click:Connect(function()

        farmActive = not farmActive

        if farmModule
            and type(farmModule.SetFarmState) == "function" then

            local success, err = pcall(function()
                farmModule.SetFarmState(farmActive)
            end)

            if not success then
                warn(
                    "[Vortex Hub] Erro ao alterar Auto Farm: "
                    .. tostring(err)
                )
            end
        else
            warn(
                "[Vortex Hub] SetFarmState não encontrado em farm.lua"
            )
        end

        ToggleFarm.Text =
            farmActive
            and "Auto Farm: ON"
            or "Auto Farm: OFF"

        ToggleFarm.BackgroundColor3 =
            farmActive
            and Color3.fromRGB(46, 204, 113)
            or Color3.fromRGB(138, 92, 255)
    end)

    -- =====================================================
    -- ABRIR / FECHAR PAINEL
    -- =====================================================

    OpenBtn.MouseButton1Click:Connect(function()

        Frame.Visible = not Frame.Visible

    end)

    print(
        "[Vortex Hub] Interface mobile pronta e operacional!"
    )

else

    -- =====================================================
    -- MAIN.LUA
    -- =====================================================

    if type(mainModule) == "table"
        and type(mainModule.Init) == "function" then

        local success, err = pcall(function()

            mainModule.Init({
                Farm = farmModule,
                Combat = combatModule,
                Bypass = bypassModule
            })

        end)

        if not success then
            warn(
                "[Vortex Hub Error] Erro ao inicializar main.lua: "
                .. tostring(err)
            )
        end

    else

        warn(
            "[Vortex Hub Error] main.lua foi carregado, "
            .. "mas não possui Init()."
        )

    end

end

-- =========================================================
-- FINALIZAÇÃO
-- =========================================================

getgenv().VortexHub.Loaded = true

print(
    "[Vortex Hub] Inicialização concluída com sucesso!"
)            else
                warn("[Vortex Hub Error] Erro ao executar " .. moduleName .. ": " .. tostring(resultModule))
            end
        else
            warn("[Vortex Hub Error] Erro de sintaxe em " .. moduleName .. ": " .. tostring(compileErr))
        end
    else
        warn("[Vortex Hub Error] Falha de conexão ao baixar: " .. moduleName)
    end
    return nil
end

print("[Vortex Hub] Iniciando ecossistema Vortex Hub...")

local bypassModule = LoadModule("bypass.lua")
local farmModule = LoadModule("farm.lua")
local combatModule = LoadModule("combat.lua")

-- Tenta carregar main.lua do GitHub
local mainModule = LoadModule("main.lua")

-- Se o main.lua do GitHub der timeout por causa do tamanho no mobile, constrói a UI leve nativa
if not mainModule then
    warn("[Vortex Hub] Carregando interface otimizada para mobile...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    if PlayerGui:FindFirstChild("VortexHubUI") then
        PlayerGui.VortexHubUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VortexHubUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    -- Botão Flutuante (Móvel)
    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Size = UDim2.fromOffset(45, 45)
    OpenBtn.Position = UDim2.new(0, 15, 0.4, 0)
    OpenBtn.BackgroundColor3 = Color3.fromRGB(138, 92, 255)
    OpenBtn.Text = "V"
    OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenBtn.TextSize = 22
    OpenBtn.Font = Enum.Font.GothamBold
    OpenBtn.Active = true
    OpenBtn.Draggable = true
    OpenBtn.Parent = ScreenGui

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(1, 0)
    BtnCorner.Parent = OpenBtn

    -- Painel Principal
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.fromOffset(280, 180)
    Frame.Position = UDim2.new(0.5, -140, 0.5, -90)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Frame.Visible = true
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 10)
    FrameCorner.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Text = "VORTEX HUB - MEME SEA"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Frame

    local ToggleFarm = Instance.new("TextButton")
    ToggleFarm.Size = UDim2.new(0.85, 0, 0, 40)
    ToggleFarm.Position = UDim2.new(0.075, 0, 0.35, 0)
    ToggleFarm.BackgroundColor3 = Color3.fromRGB(138, 92, 255)
    ToggleFarm.Text = "Auto Farm: OFF"
    ToggleFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleFarm.Font = Enum.Font.GothamMedium
    ToggleFarm.TextSize = 14
    ToggleFarm.Parent = Frame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleFarm

    local farmActive = false
    ToggleFarm.MouseButton1Click:Connect(function()
        farmActive = not farmActive
        if farmModule and type(farmModule.SetFarmState) == "function" then
            farmModule.SetFarmState(farmActive)
        end
        ToggleFarm.Text = farmActive and "Auto Farm: ON" or "Auto Farm: OFF"
        ToggleFarm.BackgroundColor3 = farmActive and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(138, 92, 255)
    end)

    OpenBtn.MouseButton1Click:Connect(function()
        Frame.Visible = not Frame.Visible
    end)

    print("[Vortex Hub] Interface mobile pronta e operacional!")
else
    if type(mainModule.Init) == "function" then
        mainModule.Init({
            Farm = farmModule,
            Combat = combatModule,
            Bypass = bypassModule
        })
    end
end

getgenv().VortexHub.Loaded = true
print("[Vortex Hub] Inicialização concluída com sucesso!")
local function LoadModule(moduleName)
    print("[Vortex Hub] Baixando: " .. moduleName .. "...")
    local code = SafeHttpGet(BaseURL .. moduleName)

    if not code then
        warn("[Vortex Hub Error] Falha de conexão ou timeout ao baixar: " .. moduleName)
        return nil
    end

    local codeFunction, compileErr = loadstring(code)
    if not codeFunction then
        warn("[Vortex Hub Error] Erro de compilação em " .. moduleName .. ": " .. tostring(compileErr))
        return nil
    end

    local execSuccess, resultModule = pcall(codeFunction)
    if not execSuccess then
        warn("[Vortex Hub Error] Erro de execução em " .. moduleName .. ": " .. tostring(resultModule))
        return nil
    end

    print("[Vortex Hub] Módulo '" .. moduleName .. "' carregado com sucesso!")
    return resultModule
end

print("[Vortex Hub] Iniciando carregamento do ecossistema...")

task.spawn(function()
    local bypassModule = LoadModule("bypass.lua")
    local farmModule = LoadModule("farm.lua")
    local combatModule = LoadModule("combat.lua")
    local mainModule = LoadModule("main.lua")

    if mainModule then
        if type(mainModule) == "table" and type(mainModule.Init) == "function" then
            mainModule.Init({
                Farm = farmModule,
                Combat = combatModule,
                Bypass = bypassModule
            })
        end
        getgenv().VortexHub.Loaded = true
        print("[Vortex Hub] Inicialização completa com sucesso!")
    else
        warn("[Vortex Hub Error] Não foi possível carregar a interface (main.lua).")
    end
end)
