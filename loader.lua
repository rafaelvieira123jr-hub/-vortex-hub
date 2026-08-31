--[[
    VORTEX HUB - LOADER
    Arquivo: loader.lua
]]

local GitHubUser = "rafaelvieira123jr-hub"
local Repository = "-vortex-hub"
local Branch = "main"

local BaseURL =
    "https://raw.githubusercontent.com/"
    .. GitHubUser .. "/"
    .. Repository .. "/"
    .. Branch .. "/"

--========================================================--
-- ESTADO GLOBAL
--========================================================--

local Global = getgenv()

Global.VortexHub = Global.VortexHub or {
    Loaded = false,
    Modules = {}
}

if Global.VortexHub.Loaded then
    warn("[Vortex Hub] O script já está em execução!")
    return
end

--========================================================--
-- CARREGAMENTO DOS MÓDULOS
--========================================================--

local function LoadModule(moduleName)
    print("[Vortex Hub] Baixando: " .. moduleName .. "...")

    local url =
        BaseURL
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

    if type(response) ~= "string" then
        warn(
            "[Vortex Hub Error] Resposta inválida para "
            .. moduleName
        )
        return nil
    end

    if #response <= 10 or response == "404: Not Found" then
        warn(
            "[Vortex Hub Error] Arquivo não encontrado: "
            .. moduleName
        )
        return nil
    end

    local codeFunction, compileErr =
        loadstring(response)

    if not codeFunction then
        warn(
            "[Vortex Hub Error] Erro de compilação em "
            .. moduleName
            .. ": "
            .. tostring(compileErr)
        )
        return nil
    end

    local execSuccess, resultModule =
        pcall(codeFunction)

    if not execSuccess then
        warn(
            "[Vortex Hub Error] Erro de execução em "
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

    Global.VortexHub.Modules[moduleName] =
        resultModule

    return resultModule
end

--========================================================--
-- INICIALIZAÇÃO
--========================================================--

print("[Vortex Hub] Iniciando ecossistema...")

local bypassModule =
    LoadModule("bypass.lua")

local farmModule =
    LoadModule("farm.lua")

local combatModule =
    LoadModule("combat.lua")

--========================================================--
-- INTEGRAÇÃO FARM + COMBAT
--========================================================--

if farmModule
    and combatModule
    and type(farmModule.SetCombatModule) == "function" then

    local success, err = pcall(function()
        farmModule.SetCombatModule(combatModule)
    end)

    if not success then
        warn(
            "[Vortex Hub Error] Falha ao conectar Farm + Combat: "
            .. tostring(err)
        )
    else
        print("[Vortex Hub] Farm + Combat conectados!")
    end
end

--========================================================--
-- INTERFACE
--========================================================--

local mainModule =
    LoadModule("main.lua")

--========================================================--
-- FALLBACK MOBILE
--========================================================--

local function CreateMobileUI()
    warn(
        "[Vortex Hub] main.lua não pôde ser carregado."
    )

    local Players =
        game:GetService("Players")

    local LocalPlayer =
        Players.LocalPlayer

    local PlayerGui =
        LocalPlayer:WaitForChild("PlayerGui")

    local oldUI =
        PlayerGui:FindFirstChild("VortexHubUI")

    if oldUI then
        oldUI:Destroy()
    end

    --====================================================--
    -- SCREEN GUI
    --====================================================--

    local ScreenGui =
        Instance.new("ScreenGui")

    ScreenGui.Name =
        "VortexHubUI"

    ScreenGui.ResetOnSpawn =
        false

    ScreenGui.Parent =
        PlayerGui

    --====================================================--
    -- BOTÃO FLUTUANTE
    --====================================================--

    local OpenBtn =
        Instance.new("TextButton")

    OpenBtn.Name =
        "OpenButton"

    OpenBtn.Size =
        UDim2.fromOffset(45, 45)

    OpenBtn.Position =
        UDim2.new(0, 15, 0.4, 0)

    OpenBtn.BackgroundColor3 =
        Color3.fromRGB(138, 92, 255)

    OpenBtn.Text =
        "V"

    OpenBtn.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    OpenBtn.TextSize =
        22

    OpenBtn.Font =
        Enum.Font.GothamBold

    OpenBtn.Active =
        true

    OpenBtn.Draggable =
        true

    OpenBtn.Parent =
        ScreenGui

    local BtnCorner =
        Instance.new("UICorner")

    BtnCorner.CornerRadius =
        UDim.new(1, 0)

    BtnCorner.Parent =
        OpenBtn

    --====================================================--
    -- PAINEL
    --====================================================--

    local Frame =
        Instance.new("Frame")

    Frame.Name =
        "MainFrame"

    Frame.Size =
        UDim2.fromOffset(280, 180)

    Frame.Position =
        UDim2.new(0.5, -140, 0.5, -90)

    Frame.BackgroundColor3 =
        Color3.fromRGB(20, 20, 28)

    Frame.Visible =
        true

    Frame.Active =
        true

    Frame.Draggable =
        true

    Frame.Parent =
        ScreenGui

    local FrameCorner =
        Instance.new("UICorner")

    FrameCorner.CornerRadius =
        UDim.new(0, 10)

    FrameCorner.Parent =
        Frame

    --====================================================--
    -- TÍTULO
    --====================================================--

    local Title =
        Instance.new("TextLabel")

    Title.Size =
        UDim2.new(1, 0, 0, 35)

    Title.BackgroundTransparency =
        1

    Title.Text =
        "VORTEX HUB - MEME SEA"

    Title.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    Title.TextSize =
        13

    Title.Font =
        Enum.Font.GothamBold

    Title.Parent =
        Frame

    --====================================================--
    -- AUTO FARM
    --====================================================--

    local ToggleFarm =
        Instance.new("TextButton")

    ToggleFarm.Name =
        "ToggleFarm"

    ToggleFarm.Size =
        UDim2.new(0.85, 0, 0, 40)

    ToggleFarm.Position =
        UDim2.new(0.075, 0, 0.35, 0)

    ToggleFarm.BackgroundColor3 =
        Color3.fromRGB(138, 92, 255)

    ToggleFarm.Text =
        "Auto Farm: OFF"

    ToggleFarm.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    ToggleFarm.Font =
        Enum.Font.GothamMedium

    ToggleFarm.TextSize =
        14

    ToggleFarm.Parent =
        Frame

    local ToggleCorner =
        Instance.new("UICorner")

    ToggleCorner.CornerRadius =
        UDim.new(0, 6)

    ToggleCorner.Parent =
        ToggleFarm

    local farmActive =
        false

    ToggleFarm.MouseButton1Click:Connect(function()

        farmActive =
            not farmActive

        if farmModule
            and type(farmModule.SetFarmState) == "function" then

            local success, err =
                pcall(function()
                    farmModule.SetFarmState(
                        farmActive
                    )
                end)

            if not success then
                warn(
                    "[Vortex Hub Error] Auto Farm: "
                    .. tostring(err)
                )
                farmActive = false
            end

        else
            warn(
                "[Vortex Hub Error] "
                .. "SetFarmState não encontrado."
            )

            farmActive = false
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

    --====================================================--
    -- ABRIR / FECHAR
    --====================================================--

    OpenBtn.MouseButton1Click:Connect(function()

        Frame.Visible =
            not Frame.Visible

    end)

    print(
        "[Vortex Hub] Interface mobile pronta!"
    )
end

--========================================================--
-- MAIN.LUA
--========================================================--

if mainModule then

    if type(mainModule) == "table"
        and type(mainModule.Init) == "function" then

        local success, err =
            pcall(function()

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
        else
            print(
                "[Vortex Hub] Interface principal carregada!"
            )
        end

    else

        warn(
            "[Vortex Hub Error] main.lua foi carregado, "
            .. "mas não possui Init()."
        )

        CreateMobileUI()
    end

else

    CreateMobileUI()

end

--========================================================--
-- FINALIZAÇÃO
--========================================================--

Global.VortexHub.Loaded = true

print(
    "[Vortex Hub] Inicialização concluída com sucesso!"
)
