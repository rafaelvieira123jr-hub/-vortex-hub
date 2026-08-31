--[[
    VORTEX HUB - FARM MODULE v2
    Arquivo: farm.lua
    
    Auto Farm para Meme Sea
    - Auto Pick items/código
    - Auto Clip (atravessar paredes)
    - Attack inimigos automático
    - Teleporte entre ilhas
    - Auto Quest completion
]]

local FarmModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

--========================================================--
-- CONFIGURAÇÃO
--========================================================--

local Config = {
    FarmActive = false,
    AutoPickActive = false,
    AutoClipActive = false,
    AttackRange = 40,
    AttackCooldown = 0.3,
    PickRange = 35,
    TargetDistance = 60,
    AutoEquip = true,
    CurrentIsland = "Spawn"
}

local State = {
    LastAttackTime = 0,
    CurrentTarget = nil,
    IsEquipped = false,
    FarmingActive = false,
    AutoPickActive = false,
    CollectedItems = 0,
    ClipMode = false
}

--========================================================--
-- COORDENADAS DAS ILHAS
--========================================================--

local IslandCoordinates = {
    ["Floppa Island"] = CFrame.new(-611, 15, -2174),
    ["Popcat Island"] = CFrame.new(-1230, 15, -3150),
    ["Cheems Island"] = CFrame.new(1850, 15, -1120),
    ["Gigachad Island"] = CFrame.new(-3200, 15, 1450),
    ["Snow Island"] = CFrame.new(100, 50, 100),
    ["Sand Island"] = CFrame.new(-1500, 50, -500),
    ["Gorilla Island"] = CFrame.new(2000, 50, 2000),
    ["Moai Island"] = CFrame.new(-2500, 50, -1500),
    ["Pumpkin Island"] = CFrame.new(500, 50, -2000),
    ["Sus Island"] = CFrame.new(-3500, 50, 500),
    ["PvP Arena"] = CFrame.new(1000, 50, 1500),
    ["MrBeast Island"] = CFrame.new(2500, 50, -2500),
    ["Spawn"] = CFrame.new(0, 50, 0)
}

--========================================================--
-- FUNÇÃO: AUTO PICK (PEGAR ITEMS/CÓDIGO)
--========================================================--

local function AutoPickItems()
    if not HRP then return end

    local pickRadius = Config.PickRange
    
    -- Procura por items no workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if not obj:IsDescendantOf(Character) and obj:IsA("BasePart") then
            local distance = (obj.Position - HRP.Position).Magnitude
            
            if distance < pickRadius then
                -- Verifica se é item por nome
                if obj.Name:match("Code") or obj.Name:match("Coin") or 
                   obj.Name:match("Item") or obj.Name:match("Drop") then
                    
                    pcall(function()
                        -- Move para perto do item
                        HRP.CFrame = obj.CFrame + obj.CFrame.LookVector * 3
                        task.wait(0.1)
                        
                        -- Tenta usar ClickDetector se existir
                        if obj:FindFirstChild("ClickDetector") then
                            obj.ClickDetector:FireServer()
                        end
                        
                        State.CollectedItems = State.CollectedItems + 1
                    end)
                end
            end
        end
    end
end

--========================================================--
-- FUNÇÃO: AUTO CLIP (ATRAVESSAR PAREDES)
--========================================================--

local function EnableAutoClip(enabled)
    State.ClipMode = enabled
    
    if enabled then
        print("[Vortex Hub Farm] Auto Clip ativado!")
        
        -- Desabilita colisão com partes
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.CanCollide = false
                end)
            end
        end
    else
        print("[Vortex Hub Farm] Auto Clip desativado!")
        
        -- Re-habilita colisão
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.CanCollide = true
                end)
            end
        end
    end
end

--========================================================--
-- FUNÇÃO: ENCONTRAR INIMIGOS (DO WORKSPACE)
--========================================================--

local function FindNearestEnemy()
    if not HRP then return nil end

    local nearestEnemy = nil
    local nearestDistance = Config.TargetDistance

    -- Procura na pasta Monster
    local monsterFolder = workspace:FindFirstChild("Monster")
    if monsterFolder then
        for _, monster in pairs(monsterFolder:GetChildren()) do
            if monster:FindFirstChild("Humanoid") and monster:FindFirstChild("HumanoidRootPart") then
                local humanoid = monster:FindFirstChild("Humanoid")
                local enemyHRP = monster:FindFirstChild("HumanoidRootPart")
                
                if humanoid.Health > 0 and enemyHRP then
                    local distance = (enemyHRP.Position - HRP.Position).Magnitude
                    
                    if distance < nearestDistance then
                        nearestEnemy = monster
                        nearestDistance = distance
                    end
                end
            end
        end
    end

    return nearestEnemy
end

--========================================================--
-- FUNÇÃO: ATACAR INIMIGO
--========================================================--

local function AttackEnemy(enemy)
    if not enemy or not enemy:FindFirstChild("Humanoid") or not enemy:FindFirstChild("HumanoidRootPart") then
        return
    end

    local currentTime = tick()
    
    if currentTime - State.LastAttackTime >= Config.AttackCooldown then
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        local distance = (enemyHRP.Position - HRP.Position).Magnitude
        
        if distance <= Config.AttackRange then
            -- Move para perto do inimigo
            local attackPos = enemyHRP.Position + (HRP.Position - enemyHRP.Position).Unit * 5
            HRP.CFrame = CFrame.new(attackPos)
            
            -- Tenta usar skill/ataque
            pcall(function()
                -- Simula ataque por MouseButton1
                local mouse = LocalPlayer:GetMouse()
                mouse:Fire()
            end)
            
            State.LastAttackTime = currentTime
        end
    end
end

--========================================================--
-- FUNÇÃO: AUTO QUEST (COMPLETA QUESTS)
--========================================================--

local function AutoCompleteQuest()
    local questFolder = workspace:FindFirstChild("Location")
    if not questFolder then return end
    
    local questLocations = questFolder:FindFirstChild("QuestLocaion")
    if not questLocations then return end
    
    for _, questPart in pairs(questLocations:GetChildren()) do
        if questPart:IsA("BasePart") then
            local distance = (questPart.Position - HRP.Position).Magnitude
            
            if distance < 50 then
                pcall(function()
                    HRP.CFrame = questPart.CFrame + questPart.CFrame.LookVector * 3
                    task.wait(0.2)
                    
                    -- Tenta interagir se tiver ProximityPrompt
                    if questPart:FindFirstChild("ProximityPrompt") then
                        questPart.ProximityPrompt:InputBegan(Enum.UserInputType.Gamepad1, false)
                    end
                end)
            end
        end
    end
end

--========================================================--
-- FUNÇÃO: LOOP PRINCIPAL DO FARM
--========================================================--

local function AutoFarmLoop()
    while State.FarmingActive do
        task.wait(0.1)

        if not LocalPlayer or not LocalPlayer.Character then break end

        local character = LocalPlayer.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not hrp or humanoid.Health <= 0 then break end

        -- Auto Pick
        if State.AutoPickActive then
            AutoPickItems()
        end

        -- Auto Clip (mantém desabilitado)
        if State.ClipMode then
            EnableAutoClip(true)
        end

        -- Encontrar e atacar inimigo
        local target = FindNearestEnemy()
        if target then
            AttackEnemy(target)
        else
            -- Se não tem inimigo perto, tenta completar quest
            AutoCompleteQuest()
        end
    end
end

--========================================================--
-- FUNÇÕES PÚBLICAS
--========================================================--

function FarmModule.SetFarmState(enabled)
    Config.FarmActive = enabled
    State.FarmingActive = enabled

    if enabled then
        print("[Vortex Hub Farm] Auto Farm iniciado!")
        task.spawn(AutoFarmLoop)
    else
        print("[Vortex Hub Farm] Auto Farm parado!")
    end
end

function FarmModule.SetAutoPickState(enabled)
    State.AutoPickActive = enabled
    print("[Vortex Hub Farm] Auto Pick: " .. (enabled and "ON" or "OFF"))
end

function FarmModule.SetAutoClipState(enabled)
    State.ClipMode = enabled
    EnableAutoClip(enabled)
end

function FarmModule.SetCombatModule(combatModule)
    FarmModule.CombatModule = combatModule
    print("[Vortex Hub Farm] Combat Module conectado!")
end

function FarmModule.TeleportToIsland(islandName)
    if not IslandCoordinates[islandName] then
        warn("[Vortex Hub Farm] Ilha não encontrada: " .. islandName)
        return false
    end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end

    pcall(function()
        character:FindFirstChild("HumanoidRootPart").CFrame = IslandCoordinates[islandName]
        Config.CurrentIsland = islandName
        print("[Vortex Hub Farm] Teleportado para: " .. islandName)
    end)

    return true
end

function FarmModule.GetCollectedItems()
    return State.CollectedItems
end

function FarmModule.SetTargetDistance(distance)
    Config.TargetDistance = tonumber(distance) or 60
end

function FarmModule.SetAttackSpeed(speed)
    Config.AttackCooldown = 1 / (tonumber(speed) or 3)
end

--========================================================--
-- RECONECTAR PERSONAGEM
--========================================================--

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HRP = Character:WaitForChild("HumanoidRootPart")
    State.IsEquipped = false
    State.LastAttackTime = 0

    if Config.FarmActive then
        task.wait(1)
        task.spawn(AutoFarmLoop)
    end
end)

--========================================================--
-- PRINT DE INICIALIZAÇÃO
--========================================================--

print("[Vortex Hub] Farm Module v2 carregado com sucesso!")
print("[Vortex Hub] Recursos disponíveis:")
print("  - Auto Farm (Attack + Pick + Quest)")
print("  - Auto Clip (Atravessar paredes)")
print("  - Teleporte para 13 ilhas")
print("  - Auto Pick de itens/código")

return FarmModule
