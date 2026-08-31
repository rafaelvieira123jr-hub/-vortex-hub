--[[
    VORTEX HUB - COMBAT MODULE
    Arquivo: combat.lua

    Responsabilidades:
    - Equipar Tool
    - Ativar ataque da Tool
    - Gerenciar AutoClick
    - Gerenciar estados das skills
    - Expor PerformAttack() para o farm.lua
--]]

local CombatModule = {}

--========================================================--
-- SERVIÇOS
--========================================================--

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character

--========================================================--
-- ESTADO
--========================================================--

local AttackThread = nil
local SkillsThread = nil

local function SetCharacter(character)
    Character = character
end

if not Character then
    Character = LocalPlayer.CharacterAdded:Wait()
end

LocalPlayer.CharacterAdded:Connect(SetCharacter)

--========================================================--
-- CONFIG
--========================================================--

CombatModule.Config = {
    AutoClick = false,
    AutoEquip = false,

    SelectedWeapon = nil,

    AttackDelay = 0.15,

    SkillDelay = 0.5,

    Skills = {
        Z = false,
        X = false,
        C = false,
        V = false
    }
}

--========================================================--
-- UTILITÁRIOS
--========================================================--

local function GetHumanoid()
    if not Character then
        return nil
    end

    return Character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive()
    local humanoid = GetHumanoid()

    return humanoid ~= nil
        and humanoid.Health > 0
end

local function GetBackpack()
    return LocalPlayer:FindFirstChildOfClass("Backpack")
end

--========================================================--
-- ARMAS
--========================================================--

function CombatModule.GetWeapon()
    if not Character then
        return nil
    end

    -- Primeiro verifica arma já equipada
    local equipped =
        Character:FindFirstChildOfClass("Tool")

    if equipped then
        if not CombatModule.Config.SelectedWeapon
            or equipped.Name == CombatModule.Config.SelectedWeapon then

            return equipped
        end
    end

    local backpack = GetBackpack()

    if not backpack then
        return nil
    end

    -- Arma selecionada
    local selected =
        CombatModule.Config.SelectedWeapon

    if selected then
        local tool =
            backpack:FindFirstChild(selected)

        if tool and tool:IsA("Tool") then
            return tool
        end
    end

    -- Qualquer Tool
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end

    return nil
end

function CombatModule.EquipWeapon()
    if not CombatModule.Config.AutoEquip then
        return false
    end

    if not IsAlive() then
        return false
    end

    local humanoid = GetHumanoid()

    if not humanoid then
        return false
    end

    local equipped =
        Character:FindFirstChildOfClass("Tool")

    if equipped then
        return true
    end

    local tool =
        CombatModule.GetWeapon()

    if not tool then
        return false
    end

    local success, err =
        pcall(function()
            humanoid:EquipTool(tool)
        end)

    if not success then
        warn(
            "[Vortex Combat] Falha ao equipar: "
            .. tostring(err)
        )

        return false
    end

    return true
end

--========================================================--
-- ATAQUE
--========================================================--

function CombatModule.PerformAttack()
    if not IsAlive() then
        return false
    end

    local tool =
        Character and Character:FindFirstChildOfClass("Tool")

    -- Se não houver ferramenta equipada,
    -- tenta equipar automaticamente.
    if not tool and CombatModule.Config.AutoEquip then
        CombatModule.EquipWeapon()
        tool =
            Character and Character:FindFirstChildOfClass("Tool")
    end

    if not tool then
        return false
    end

    local success, err =
        pcall(function()
            tool:Activate()
        end)

    if not success then
        warn(
            "[Vortex Combat] Erro ao ativar Tool: "
            .. tostring(err)
        )

        return false
    end

    return true
end

--========================================================--
-- AUTO CLICK
--========================================================--

function CombatModule.StartAttackLoop()
    if AttackThread then
        return
    end

    AttackThread = task.spawn(function()

        while CombatModule.Config.AutoClick do

            if IsAlive() then
                CombatModule.PerformAttack()
            end

            task.wait(
                math.max(
                    CombatModule.Config.AttackDelay,
                    0.03
                )
            )
        end

        AttackThread = nil
    end)
end

function CombatModule.StopAttackLoop()
    CombatModule.Config.AutoClick = false
    AttackThread = nil
end

function CombatModule.SetAutoClick(state)
    state = state == true

    CombatModule.Config.AutoClick = state

    if state then
        CombatModule.StartAttackLoop()
    end
end

--========================================================--
-- SKILLS
--========================================================--

function CombatModule.UseSkill(key)
    key = tostring(key):upper()

    if not IsAlive() then
        return false
    end

    local allowed = {
        Z = true,
        X = true,
        C = true,
        V = true
    }

    if not allowed[key] then
        return false
    end

    -- Procura uma API de skill fornecida pela própria Tool,
    -- caso exista.
    local tool =
        Character and Character:FindFirstChildOfClass("Tool")

    if not tool then
        if CombatModule.Config.AutoEquip then
            CombatModule.EquipWeapon()
            tool =
                Character and Character:FindFirstChildOfClass("Tool")
        end
    end

    if not tool then
        return false
    end

    -- Não assume RemoteEvent/RemoteFunction específico.
    -- O jogo precisa expor sua própria função de habilidade.
    local skillFunction =
        tool:FindFirstChild("UseSkill")

    if skillFunction
        and skillFunction:IsA("BindableFunction") then

        local success = pcall(function()
            skillFunction:Invoke(key)
        end)

        return success
    end

    -- Algumas Tools possuem BindableEvent.
    local skillEvent =
        tool:FindFirstChild("UseSkill")

    if skillEvent
        and skillEvent:IsA("BindableEvent") then

        local success = pcall(function()
            skillEvent:Fire(key)
        end)

        return success
    end

    return false
end

--========================================================--
-- LOOP DE SKILLS
--========================================================--

function CombatModule.StartSkillsLoop()
    if SkillsThread then
        return
    end

    SkillsThread = task.spawn(function()

        while
            CombatModule.Config.Skills.Z
            or CombatModule.Config.Skills.X
            or CombatModule.Config.Skills.C
            or CombatModule.Config.Skills.V
        do

            if IsAlive() then

                if CombatModule.Config.AutoEquip then
                    CombatModule.EquipWeapon()
                end

                if CombatModule.Config.Skills.Z then
                    CombatModule.UseSkill("Z")
                    task.wait(0.1)
                end

                if CombatModule.Config.Skills.X then
                    CombatModule.UseSkill("X")
                    task.wait(0.1)
                end

                if CombatModule.Config.Skills.C then
                    CombatModule.UseSkill("C")
                    task.wait(0.1)
                end

                if CombatModule.Config.Skills.V then
                    CombatModule.UseSkill("V")
                    task.wait(0.1)
                end
            end

            task.wait(
                math.max(
                    CombatModule.Config.SkillDelay,
                    0.1
                )
            )
        end

        SkillsThread = nil
    end)
end

function CombatModule.SetSkillState(key, state)
    key = tostring(key):upper()

    if CombatModule.Config.Skills[key] == nil then
        return
    end

    CombatModule.Config.Skills[key] =
        state == true

    if state then
        CombatModule.StartSkillsLoop()
    end
end

--========================================================--
-- AUTO EQUIP
--========================================================--

function CombatModule.SetAutoEquip(state)
    state = state == true

    CombatModule.Config.AutoEquip = state

    if state then
        CombatModule.EquipWeapon()
    end
end

--========================================================--
-- LIMPEZA
--========================================================--

function CombatModule.Stop()
    CombatModule.Config.AutoClick = false

    CombatModule.Config.Skills.Z = false
    CombatModule.Config.Skills.X = false
    CombatModule.Config.Skills.C = false
    CombatModule.Config.Skills.V = false

    AttackThread = nil
    SkillsThread = nil
end

return CombatModule    SkillDelay = 0.5   -- Intervalo entre checagens de habilidades
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
