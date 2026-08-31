--[[
    VORTEX HUB - FARM MODULE (MÓDULO 2: LÓGICA DE FARM E MOBS)
    Arquivo: farm.lua
    Descrição: Gerenciamento de alvos, cálculo de distância, quests e movimentação suave.
--]]

local FarmModule = {}

--========================================================--
-- 1. SERVIÇOS E VARIÁVEIS LOCAIS
--========================================================--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
end)

-- Configurações internas de Farm
FarmModule.Config = {
    Enabled = false,
    AutoQuest = false,
    FarmBosses = false,
    Distance = 9, -- Distância mantida acima/ao lado do mob
    TweenSpeed = 300, -- Velocidade de movimentação suave
    TargetMob = nil,
    CurrentQuest = nil
}

local CurrentTween = nil
local BodyVelocityInstance = nil

--========================================================--
-- 2. UTILITÁRIOS DE PERSONAGEM E NOCLIP / VOO
--========================================================--

local function GetRootFrame()
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        return Character.HumanoidRootPart
    end
    return nil
end

local function GetHumanoid()
    if Character and Character:FindFirstChildOfClass("Humanoid") then
        return Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- Cancela qualquer movimentação ativa e limpa efeitos de física
function FarmModule.StopMovement()
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end
    if BodyVelocityInstance then
        BodyVelocityInstance:Destroy()
        BodyVelocityInstance = nil
    end
end

-- Desativa colisões temporariamente durante o voo de farm para não engatar no cenário
local function SetNoClip(active)
    if not Character then return end
    for _, part in ipairs(Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not active
        end
    end
end

-- Movimentação suave até uma posição de CFrame usando TweenService
function FarmModule.MoveToCFrame(targetCFrame)
    local root = GetRootFrame()
    if not root then return end

    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / FarmModule.Config.TweenSpeed

    SetNoClip(true)

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    CurrentTween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    CurrentTween:Play()

    return CurrentTween
end

--========================================================--
-- 3. SISTEMA DE DETECÇÃO DE MOBS E ALVOS
--========================================================--

-- Busca a pasta onde os Mobs do jogo spawnam
local function GetEnemiesFolder()
    return Workspace:FindFirstChild("Monsters") 
        or Workspace:FindFirstChild("Enemies") 
        or Workspace:FindFirstChild("NPCs") 
        or Workspace
end

-- Procura o mob mais próximo vivo (com opção de filtro por nome)
function FarmModule.GetClosestMob(mobName)
    local root = GetRootFrame()
    if not root then return nil end

    local closestMob = nil
    local shortestDistance = math.huge
    local enemiesFolder = GetEnemiesFolder()

    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")

        if mobRoot and mobHumanoid and mobHumanoid.Health > 0 then
            -- Se um nome específico foi passado, filtra por nome. Caso contrário, pega o mais próximo
            if not mobName or mob.Name:lower():find(mobName:lower()) then
                local dist = (root.Position - mobRoot.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestMob = mob
                end
            end
        end
    end

    return closestMob
end

--========================================================--
-- 4. AUTOMAÇÃO DE QUESTS
--========================================================--

function FarmModule.CheckAndTakeQuest()
    if not FarmModule.Config.AutoQuest then return end
    
    -- Leitura do nível do jogador no Meme Sea
    local playerLevel = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value or 1
    
    -- A integração com as Remotes de Quest do jogo é acionada aqui
end

--========================================================--
-- 5. LOOP PRINCIPAL DO FARM
--========================================================--

local FarmThread = nil

function FarmModule.StartFarmLoop()
    if FarmThread then return end

    FarmThread = task.spawn(function()
        while FarmModule.Config.Enabled do
            task.wait(0.1)

            local root = GetRootFrame()
            local humanoid = GetHumanoid()

            if root and humanoid and humanoid.Health > 0 then
                -- 1. Verifica/Aceita Quests se a opção estiver ligada na UI
                FarmModule.CheckAndTakeQuest()

                -- 2. Localiza o Mob mais próximo
                local target = FarmModule.GetClosestMob()
                FarmModule.Config.TargetMob = target

                if target and target:FindFirstChild("HumanoidRootPart") then
                    local targetRoot = target.HumanoidRootPart
                    local targetHumanoid = target:FindFirstChildOfClass("Humanoid")

                    -- 3. Mantém a posição travada acima do Mob usando a distância configurada na UI
                    while FarmModule.Config.Enabled 
                          and target 
                          and target.Parent 
                          and targetHumanoid 
                          and targetHumanoid.Health > 0 do

                        root.CFrame = targetRoot.CFrame * CFrame.new(0, FarmModule.Config.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        SetNoClip(true)
                        task.wait()
                    end
                else
                    SetNoClip(false)
                end
            end
        end

        FarmModule.StopMovement()
        SetNoClip(false)
        FarmThread = nil
    end)
end

function FarmModule.SetFarmState(state)
    FarmModule.Config.Enabled = state
    if state then
        FarmModule.StartFarmLoop()
    else
        FarmModule.StopMovement()
        SetNoClip(false)
    end
end

return FarmModule
