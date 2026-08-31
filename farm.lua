--[[
    VORTEX HUB - FARM MODULE
    Arquivo: farm.lua

    Responsabilidades:
    - Encontrar inimigos
    - Selecionar alvo
    - Movimentar o personagem até o alvo
    - Integrar com o módulo de combate
    - Controlar o loop do farm
    - Lidar com respawn e alvos inválidos

    IMPORTANTE:
    O módulo de combate deve fornecer:
        Combat.PerformAttack()
--]]

local FarmModule = {}

--========================================================--
-- SERVIÇOS
--========================================================--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- ESTADO
--========================================================--

local Character = LocalPlayer.Character
local FarmThread = nil
local CurrentTween = nil
local CombatModule = nil

local function UpdateCharacter(character)
    Character = character
end

if not Character then
    Character = LocalPlayer.CharacterAdded:Wait()
end

LocalPlayer.CharacterAdded:Connect(UpdateCharacter)

--========================================================--
-- CONFIGURAÇÃO
--========================================================--

FarmModule.Config = {
    Enabled = false,

    AutoQuest = false,
    FarmBosses = false,

    Distance = 9,
    TweenSpeed = 300,

    AttackInterval = 0.15,
    TargetRefreshInterval = 0.15,

    TargetMob = nil,
    CurrentQuest = nil,
}

--========================================================--
-- INTEGRAÇÃO COM COMBAT
--========================================================--

function FarmModule.SetCombatModule(module)
    CombatModule = module

    if CombatModule then
        print("[Vortex Farm] Combat module conectado.")
    else
        warn("[Vortex Farm] Combat module não disponível.")
    end
end

--========================================================--
-- UTILITÁRIOS
--========================================================--

local function GetRoot()
    if not Character then
        return nil
    end

    return Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    if not Character then
        return nil
    end

    return Character:FindFirstChildOfClass("Humanoid")
end

local function IsCharacterAlive()
    local humanoid = GetHumanoid()
    local root = GetRoot()

    return humanoid
        and humanoid.Health > 0
        and root ~= nil
end

--========================================================--
-- NOCLIP
--========================================================--

local function SetNoClip(enabled)
    if not Character then
        return
    end

    for _, obj in ipairs(Character:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = not enabled
        end
    end
end

--========================================================--
-- MOVIMENTO
--========================================================--

function FarmModule.StopMovement()
    if CurrentTween then
        pcall(function()
            CurrentTween:Cancel()
        end)

        CurrentTween = nil
    end
end

function FarmModule.MoveToCFrame(targetCFrame)
    local root = GetRoot()

    if not root then
        return nil
    end

    FarmModule.StopMovement()

    local distance =
        (root.Position - targetCFrame.Position).Magnitude

    local speed =
        math.max(FarmModule.Config.TweenSpeed, 1)

    local duration =
        math.max(distance / speed, 0.05)

    SetNoClip(true)

    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(
        root,
        tweenInfo,
        {
            CFrame = targetCFrame
        }
    )

    CurrentTween = tween
    tween:Play()

    return tween
end

--========================================================--
-- ENEMIES
--========================================================--

local function GetEnemiesFolder()
    return Workspace:FindFirstChild("Monsters")
        or Workspace:FindFirstChild("Enemies")
        or Workspace:FindFirstChild("NPCs")
end

local function IsValidEnemy(enemy)
    if not enemy then
        return false
    end

    local humanoid =
        enemy:FindFirstChildOfClass("Humanoid")

    local root =
        enemy:FindFirstChild("HumanoidRootPart")

    return humanoid
        and root
        and humanoid.Health > 0
end

function FarmModule.GetClosestMob(mobName)
    local playerRoot = GetRoot()

    if not playerRoot then
        return nil
    end

    local enemiesFolder = GetEnemiesFolder()

    if not enemiesFolder then
        return nil
    end

    local closest = nil
    local closestDistance = math.huge

    local wantedName =
        mobName and string.lower(mobName) or nil

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if IsValidEnemy(enemy) then

            local validName = true

            if wantedName then
                validName =
                    string.find(
                        string.lower(enemy.Name),
                        wantedName,
                        1,
                        true
                    ) ~= nil
            end

            if validName then
                local enemyRoot =
                    enemy:FindFirstChild("HumanoidRootPart")

                local distance =
                    (playerRoot.Position - enemyRoot.Position).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closest = enemy
                end
            end
        end
    end

    return closest
end

--========================================================--
-- QUEST
--========================================================--

function FarmModule.CheckAndTakeQuest()
    if not FarmModule.Config.AutoQuest then
        return false
    end

    local data =
        LocalPlayer:FindFirstChild("Data")

    local levelObject =
        data and data:FindFirstChild("Level")

    local level =
        levelObject and levelObject.Value or 1

    -- Mantido como ponto de integração.
    -- A estrutura exata das quests depende da implementação
    -- do jogo.

    FarmModule.Config.CurrentQuest = {
        Level = level
    }

    return true
end

--========================================================--
-- ATAQUE
--========================================================--

local function PerformAttack()
    if not CombatModule then
        return false
    end

    if type(CombatModule.PerformAttack) ~= "function" then
        return false
    end

    local success, result = pcall(function()
        return CombatModule.PerformAttack()
    end)

    if not success then
        warn(
            "[Vortex Farm] Erro no combate: "
            .. tostring(result)
        )

        return false
    end

    return true
end

--========================================================--
-- POSICIONAMENTO NO ALVO
--========================================================--

local function PositionAboveTarget(target)
    if not IsValidEnemy(target) then
        return false
    end

    local root = GetRoot()
    local targetRoot =
        target:FindFirstChild("HumanoidRootPart")

    if not root or not targetRoot then
        return false
    end

    local position =
        targetRoot.Position
        + Vector3.new(
            0,
            FarmModule.Config.Distance,
            0
        )

    root.CFrame =
        CFrame.new(position)
        * CFrame.Angles(
            math.rad(-90),
            0,
            0
        )

    return true
end

--========================================================--
-- CICLO DO ALVO
--========================================================--

local function FarmTarget(target)
    if not IsValidEnemy(target) then
        return
    end

    FarmModule.Config.TargetMob = target

    local humanoid =
        target:FindFirstChildOfClass("Humanoid")

    while FarmModule.Config.Enabled
        and target.Parent
        and humanoid
        and humanoid.Health > 0
        and IsCharacterAlive() do

        PositionAboveTarget(target)

        -- Integração com combat.lua
        PerformAttack()

        task.wait(
            FarmModule.Config.AttackInterval
        )
    end

    if FarmModule.Config.TargetMob == target then
        FarmModule.Config.TargetMob = nil
    end
end

--========================================================--
-- LOOP PRINCIPAL
--========================================================--

function FarmModule.StartFarmLoop()
    if FarmThread then
        return
    end

    FarmThread = task.spawn(function()

        print("[Vortex Farm] Loop iniciado.")

        while FarmModule.Config.Enabled do

            if not IsCharacterAlive() then
                task.wait(0.5)
                continue
            end

            -- Quest
            FarmModule.CheckAndTakeQuest()

            -- Procurar alvo
            local target =
                FarmModule.GetClosestMob()

            if target then

                FarmTarget(target)

            else
                SetNoClip(false)
                task.wait(
                    FarmModule.Config.TargetRefreshInterval
                )
            end
        end

        FarmModule.StopMovement()
        SetNoClip(false)

        FarmModule.Config.TargetMob = nil
        FarmThread = nil

        print("[Vortex Farm] Loop encerrado.")
    end)
end

--========================================================--
-- CONTROLE
--========================================================--

function FarmModule.SetFarmState(state)
    state = state == true

    FarmModule.Config.Enabled = state

    if state then
        print("[Vortex Farm] Auto Farm: ON")
        FarmModule.StartFarmLoop()
    else
        print("[Vortex Farm] Auto Farm: OFF")

        FarmModule.StopMovement()
        SetNoClip(false)

        FarmModule.Config.TargetMob = nil
    end
end

--========================================================--
-- EXPORTAÇÃO
--========================================================--

return FarmModulelocal BodyVelocityInstance = nil

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
