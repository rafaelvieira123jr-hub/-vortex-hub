--[[
    VORTEX HUB - COMBAT MODULE (MÓDULO 3: LÓGICA DE COMBATE E SKILLS)
    Arquivo: combat.lua
    Descrição: Auto equip de armas, auto attack/click e execução automática de habilidades (Z, X, C, V).
--]]

local CombatModule = {}

--========================================================--
-- 1. SERVIÇOS E VARIÁVEIS LOCAIS
--========================================================--

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
end)

-- Configurações de Combate
CombatModule.Config = {
    AutoClick = false,
    AutoEquip = false,
    SelectedWeapon = nil, -- Nome da arma específica ou nil para qualquer uma
    Skills = {
        Z = false,
        X = false,
        C = false,
        V = false
    },
    AttackDelay = 0.1, -- Intervalo entre os cliques de ataque
    SkillDelay = 0.5   -- Intervalo entre checagens de habilidades
}

--========================================================--
-- 2. UTILITÁRIOS DE EQUIPAMENTO E FERRAMENTAS
--========================================================--

-- Retorna a Humanoid do personagem local
local function GetHumanoid()
    if Character and Character:FindFirstChildOfClass("Humanoid") then
        return Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- Busca a ferramenta equipada no momento ou no inventário (Backpack)
function CombatModule.GetWeapon()
    if not Character then return nil end

    -- Se já tiver uma ferramenta equipada na mão
    local currentTool = Character:FindFirstChildOfClass("Tool")
    if currentTool then
        return currentTool
    end

    -- Busca na mochila (Backpack)
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        if CombatModule.Config.SelectedWeapon then
            local specificTool = backpack:FindFirstChild(CombatModule.Config.SelectedWeapon)
            if specificTool then return specificTool end
        end

        -- Se não tiver arma específica selecionada, pega a primeira Tool disponível
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                return item
            end
        end
    end

    return nil
end

-- Equipa automaticamente a ferramenta encontrada
function CombatModule.EquipWeapon()
    if not CombatModule.Config.AutoEquip then return end

    local humanoid = GetHumanoid()
    if not humanoid then return end

    -- Se já existe uma arma equipada na mão, não precisa fazer nada
    if Character:FindFirstChildOfClass("Tool") then return end

    local tool = CombatModule.GetWeapon()
    if tool and tool.Parent ~= Character then
        humanoid:EquipTool(tool)
    end
end

--========================================================--
-- 3. AUTOMAÇÃO DE ATAQUE (AUTO CLICK)
--========================================================--

local AttackThread = nil

-- Executa o ataque via acionamento direto da Tool ou via VirtualUser
function CombatModule.PerformAttack()
    CombatModule.EquipWeapon()

    local tool = Character and Character:FindFirstChildOfClass("Tool")
    if tool then
        -- Tenta ativar diretamente o método do objeto Tool
        tool:Activate()
    end

    -- Simula o clique de mouse/toque de forma segura via VirtualUser
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(0, 0))
end

function CombatModule.StartAttackLoop()
    if AttackThread then return end

    AttackThread = task.spawn(function()
        while CombatModule.Config.AutoClick do
            task.wait(CombatModule.Config.AttackDelay)
            if Character and Character:FindFirstChildOfClass("Humanoid") and Character.Humanoid.Health > 0 then
                CombatModule.PerformAttack()
            end
        end
        AttackThread = nil
    end)
end

function CombatModule.SetAutoClick(state)
    CombatModule.Config.AutoClick = state
    if state then
        CombatModule.StartAttackLoop()
    end
end

--========================================================--
-- 4. AUTOMAÇÃO DE HABILIDADES (SKILLS Z, X, C, V)
--========================================================--

local SkillsThread = nil

-- Dispara o sinal de Remote / Tecla referente à habilidade solicitada
function CombatModule.UseSkill(key)
    local tool = Character and Character:FindFirstChildOfClass("Tool")
    
    -- Exemplo de envio via RemoteEvent padrão de jogos de combate em Luau
    -- A integração ajusta dinamicamente a chamada da Remote conforme o jogo (Meme Sea)
    if tool then
        local remote = tool:FindFirstChild("Remote") 
            or tool:FindFirstChild("Server") 
            or ReplicatedStorage:FindFirstChild("Remotes")
            
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(key)
        end
    end

    -- Pressionamento de tecla simulado (para suporte universal)
    VirtualUser:CaptureController()
    VirtualUser:SetKeyDown(key)
    task.wait(0.05)
    VirtualUser:SetKeyUp(key)
end

function CombatModule.StartSkillsLoop()
    if SkillsThread then return end

    SkillsThread = task.spawn(function()
        while CombatModule.Config.Skills.Z or CombatModule.Config.Skills.X or CombatModule.Config.Skills.C or CombatModule.Config.Skills.V do
            task.wait(CombatModule.Config.SkillDelay)

            if Character and Character:FindFirstChildOfClass("Humanoid") and Character.Humanoid.Health > 0 then
                CombatModule.EquipWeapon()

                if CombatModule.Config.Skills.Z then
                    CombatModule.UseSkill("z")
                    task.wait(0.1)
                end
                if CombatModule.Config.Skills.X then
                    CombatModule.UseSkill("x")
                    task.wait(0.1)
                end
                if CombatModule.Config.Skills.C then
                    CombatModule.UseSkill("c")
                    task.wait(0.1)
                end
                if CombatModule.Config.Skills.V then
                    CombatModule.UseSkill("v")
                    task.wait(0.1)
                end
            end
        end
        SkillsThread = nil
    end)
end

function CombatModule.SetSkillState(key, state)
    key = key:upper()
    if CombatModule.Config.Skills[key] ~= nil then
        CombatModule.Config.Skills[key] = state
        
        -- Se qualquer uma das habilidades estiver ativa, inicia o loop de habilidades
        if state then
            CombatModule.StartSkillsLoop()
        end
    end
end

function CombatModule.SetAutoEquip(state)
    CombatModule.Config.AutoEquip = state
    if state then
        CombatModule.EquipWeapon()
    end
end

return CombatModule
