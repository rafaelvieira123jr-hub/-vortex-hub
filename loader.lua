--[[
    VORTEX HUB - LOADER INTEGRADO
    Arquivo: loader.lua
--]]

local GitHubUser = "rafaelvieira123jr-hub"
local Repository = "-vortex-hub"
local Branch = "main"

local BaseURL = "https://raw.githubusercontent.com/" .. GitHubUser .. "/" .. Repository .. "/" .. Branch .. "/"

getgenv().VortexHub = getgenv().VortexHub or {
    Loaded = false,
    Modules = {}
}

if getgenv().VortexHub.Loaded then
    warn("[Vortex Hub] O script já está em execução!")
    return
end

local function LoadModule(moduleName)
    local url = BaseURL .. moduleName .. "?nocache=" .. tostring(os.time())
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not response or response == "404: Not Found" or #response < 10 then
        warn("[Vortex Hub Error] Falha ao baixar: " .. moduleName)
        return nil
    end

    local codeFunction, compileErr = loadstring(response)
    if not codeFunction then
        warn("[Vortex Hub Error] Erro de sintaxe em " .. moduleName .. ": " .. tostring(compileErr))
        return nil
    end

    local execSuccess, resultModule = pcall(codeFunction)
    if not execSuccess then
        warn("[Vortex Hub Error] Erro ao executar " .. moduleName .. ": " .. tostring(resultModule))
        return nil
    end

    print("[Vortex Hub] Módulo '" .. moduleName .. "' carregado com sucesso!")
    return resultModule
end

print("[Vortex Hub] Iniciando carregamento dos módulos...")

local bypassModule = LoadModule("bypass.lua")
local farmModule = LoadModule("farm.lua")
local combatModule = LoadModule("combat.lua")

-- MÓDULO MAIN EMBUTIDO (INTERFACING & CONTROLE)
local MainModule = {}
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("VortexHubUI") then
    PlayerGui.VortexHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VortexHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(300, 200)
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "VORTEX HUB - MEME SEA"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local ToggleFarm = Instance.new("TextButton")
ToggleFarm.Size = UDim2.new(0.8, 0, 0, 40)
ToggleFarm.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleFarm.BackgroundColor3 = Color3.fromRGB(138, 92, 255)
ToggleFarm.Text = "Toggle Auto Farm"
ToggleFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleFarm.Font = Enum.Font.GothamMedium
ToggleFarm.Parent = Frame

local farmActive = false
ToggleFarm.MouseButton1Click:Connect(function()
    farmActive = not farmActive
    if farmModule and farmModule.SetFarmState then
        farmModule.SetFarmState(farmActive)
    end
    ToggleFarm.Text = farmActive and "Auto Farm: ON" or "Auto Farm: OFF"
end)

function MainModule.Init(Modules)
    print("[Vortex Hub] Interface inicializada!")
end

MainModule.Init({
    Farm = farmModule,
    Combat = combatModule,
    Bypass = bypassModule
})

getgenv().VortexHub.Loaded = true
print("[Vortex Hub] Carregado com sucesso!")
        warn("[Vortex Hub Error] Erro de sintaxe em " .. moduleName .. ": " .. tostring(compileErr))
        return nil
    end

    local execSuccess, resultModule = pcall(codeFunction)
    if not execSuccess then
        warn("[Vortex Hub Error] Erro ao executar " .. moduleName .. ": " .. tostring(resultModule))
        return nil
    end

    print("[Vortex Hub] Módulo '" .. moduleName .. "' carregado com sucesso!")
    return resultModule
end

print("[Vortex Hub] Iniciando carregamento dos módulos...")

local bypassModule = LoadModule("bypass.lua")
local farmModule = LoadModule("farm.lua")
local combatModule = LoadModule("combat.lua")
local mainModule = LoadModule("main.lua")

if mainModule and type(mainModule.Init) == "function" then
    mainModule.Init({
        Farm = farmModule,
        Combat = combatModule,
        Bypass = bypassModule
    })
    getgenv().VortexHub.Loaded = true
    print("[Vortex Hub] Carregado com sucesso!")
else
    warn("[Vortex Hub] Falha ao inicializar a interface (main.lua)!")
end
