--[[
    VORTEX HUB - FARM MODULE
    Arquivo: farm.lua
    
    Auto Farm com Floppa Sword
    Sistema de resgate de código
    Teleporte entre ilhas
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
    AttackRange = 30,
    AttackCooldown = 0.5,
    SwordName = "Auto Floppa",
    TargetDistance = 50,
    AutoEquip = true,
    AutoResgate = false,
    CurrentIsland = "Start"
}

local State = {
    LastAttackTime = 0,
    CurrentTarget = nil,
    IsEquipped = false,
    FarmingActive = false,
    CollectedItems = 0
}

--========================================================--
-- COORDENADAS DAS ILHAS
--========================================================--

local IslandCoordinates = {
    ["Floppa Island"] = CFrame.new(-611, 15, -2174),
    ["Popcat Island"] = CFrame.new(-1230, 15, -3150),
    ["Cheems Island"] = CFrame.new(1850, 15, -1120),
    ["Gigachad Island"] = CFrame.new(-3200, 15, 1450),
    ["Start"] = CFrame.new(0, 50, 0)
}

--========================================================--
-- FUNCÃO: EQUIPAR FLOPPA SWORD
--========================================================--

local function EquipFloppaSword()
    if State.IsEquipped then
        return true
    end

    local backpack = LocalPlayer:WaitForChild("Backpack")
    local sword = backpack:FindFirstChild(Config.SwordName)
    
    if not sword then
        print("[Vortex Hub Farm] Floppa Sword não encontrada no inventário")
        return false
    end

    pcall(function()
        sword.Parent = Character
        State.IsEquipped = true
        print("[Vortex Hub Farm] Floppa Sword equipada!")
    end)

    return State.IsEquipped
end

--========================================================--
-- FUNÇÃO: ENCONTRAR INIMIGOS PRÓXIMOS
--========================================================--

local function FindNearestEnemy()
    if not HRP then return nil end

    local nearestEnemy = nil
    local nearestDistance = Config.TargetDistance

    for _, enemy in pairs(workspace:FindPartiesInRegion3(
        Region3.new(HRP.Position - Vector3.new(Config.TargetDistance, Config.TargetDistance, Config.TargetDistance),
                    HRP.Position + Vector3.new(Config.TargetDistance, Config.TargetDistance, Config.TargetDistance))
            :ExpandToGrid(4),
        nil,
        100
    )) do
        local character = enemy.Parent
        
        if character and character ~= Character and character:FindFirstChild("Humanoid") then
            local distance = (character:FindFirstChild("HumanoidRootPart").Position - HRP.Position).Magnitude
            
            if distance < nearestDistance and character:FindFirstChild("Humanoid").Health > 0 then
                nearestEnemy = character
                nearestDistance = distance
            end
        end
    end

    return nearestEnemy
end

--========================================================--
-- FUNÇÃO: ATACAR INIMIGO
--========================================================--

local function AttackEnemy(enemy)
    if not enemy or not enemy:FindFirstChild("Humanoid") then
        return
    end

    local currentTime = tick()
    
    if currentTime - State.LastAttackTime >= Config.AttackCooldown then
        -- Simula ataque (muda CFrame para perto do inimigo)
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        
        if enemyHRP and (enemyHRP.Position - HRP.Position).Magnitude <= Config.AttackRange then
            HRP.CFrame = enemyHRP.CFrame + enemyHRP.CFrame.LookVector * 5
            
            -- Tenta usar ferramenta para atacar
            local tool = Character:FindFirstChild(Config.SwordName)
            if tool and tool:FindFirstChild("Handle") then
                -- Simula swing da espada
                pcall(function()
                    if tool:FindFirstChild("Activated") then
                        tool.Activated:Fire()
                    end
                end)
            end
            
            State.LastAttackTime = currentTime
            print("[Vortex Hub Farm] Atacando: " .. enemy.Name)
        end
    end
end

--========================================================--
-- FUNÇÃO: COLETAR ITEMS/CÓDIGO
--========================================================--

local function CollectDrops()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")

    -- Procura por drops/coins/itens na área
    for _, item in pairs(workspace:FindPartiesInRegion3(
        Region3.new(hrp.Position - Vector3.new(20, 20, 20),
                    hrp.Position + Vector3.new(20, 20, 20))
            :ExpandToGrid(4),
        nil,
        100
    )) do
        if item.Name:match("Drop") or item.Name:match("Coin") or item.Name:match("Code") then
            pcall(function()
                item.Parent = character or character.Backpack
                State.CollectedItems = State.CollectedItems + 1
            end)
        end
    end
end

--========================================================--
-- FUNÇÃO: TELEPORTAR PARA ILHA
--========================================================--

local function TeleportToIsland(islandName)
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
        return true
    end)

    return true
end

--========================================================--
-- FUNÇÃO: AUTO RESGATE DE CÓDIGO
--========================================================--

local function AutoResgate()
    if not Config.AutoResgate then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Procura por chests, NPCs ou áreas de resgate
    for _, obj in pairs(workspace:FindPartiesInRegion3(
        Region3.new(humanoidRootPart.Position - Vector3.new(25, 25, 25),
                    humanoidRootPart.Position + Vector3.new(25, 25, 25))
            :ExpandToGrid(4),
        nil,
        100
    )) do
        if obj.Name:match("Chest") or obj.Name:match("Quest") or obj.Name:match("Code") then
            pcall(function()
                -- Tenta interagir com o objeto
                humanoidRootPart.CFrame = obj.CFrame + obj.CFrame.LookVector * 3
                
                -- Se tiver ClickDetector, clica
                if obj:FindFirstChild("ClickDetector") then
                    obj.ClickDetector:FireServer()
                end
            end)
        end
    end
end

--========================================================--
-- FUNÇÃO: AUTO FARM LOOP
--========================================================--

local function AutoFarmLoop()
    while State.FarmingActive do
        task.wait(0.1)

        if not LocalPlayer or not LocalPlayer.Character then break end

        local character = LocalPlayer.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not hrp or humanoid.Health <= 0 then break end

        -- Equipar espada se necessário
        if Config.AutoEquip and not State.IsEquipped then
            EquipFloppaSword()
        end

        -- Encontrar e atacar inimigo
        local target = FindNearestEnemy()
        if target then
            AttackEnemy(target)
        end

        -- Coletar drops
        CollectDrops()

        -- Auto resgate
        AutoResgate()
    end
end

--========================================================--
-- FUNÇÃO: INICIAR FARM
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

--========================================================--
-- FUNÇÃO: CONFIGURAR MODULE DE COMBATE
--========================================================--

function FarmModule.SetCombatModule(combatModule)
    FarmModule.CombatModule = combatModule
    print("[Vortex Hub Farm] Combat Module conectado!")
end

--========================================================--
-- FUNÇÕES AUXILIARES
--========================================================--

function FarmModule.TeleportToIsland(islandName)
    return TeleportToIsland(islandName)
end

function FarmModule.EquipSword()
    return EquipFloppaSword()
end

function FarmModule.SetAutoEquip(enabled)
    Config.AutoEquip = enabled
    print("[Vortex Hub Farm] Auto Equip: " .. (enabled and "ON" or "OFF"))
end

function FarmModule.SetAutoResgate(enabled)
    Config.AutoResgate = enabled
    print("[Vortex Hub Farm] Auto Resgate: " .. (enabled and "ON" or "OFF"))
end

function FarmModule.GetCollectedItems()
    return State.CollectedItems
end

function FarmModule.Config()
    return Config
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

print("[Vortex Hub] Farm Module carregado com sucesso!")

return FarmModule
