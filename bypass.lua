--[[
    VORTEX HUB - CLIENT SAFETY MODULE
    Arquivo: bypass.lua

    Mantém apenas funcionalidades locais e compatíveis
    com a API normal do Roblox.
--]]

local BypassModule = {}

--========================================================--
-- SERVIÇOS
--========================================================--

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONFIGURAÇÃO
--========================================================--

BypassModule.Config = {
    NoFallStates = true,
    DisableRagdollStates = true
}

--========================================================--
-- PERSONAGEM
--========================================================--

local Character = LocalPlayer.Character

local function UpdateCharacter(character)
    Character = character
end

if not Character then
    Character = LocalPlayer.CharacterAdded:Wait()
end

LocalPlayer.CharacterAdded:Connect(UpdateCharacter)

--========================================================--
-- HUMANOID
--========================================================--

local function GetHumanoid()
    if not Character then
        return nil
    end

    return Character:FindFirstChildOfClass("Humanoid")
end

--========================================================--
-- ESTADOS DE MOVIMENTO
--========================================================--

function BypassModule.ApplyCharacterSafety()
    local humanoid = GetHumanoid()

    if not humanoid then
        return false
    end

    if BypassModule.Config.NoFallStates then
        pcall(function()
            humanoid:SetStateEnabled(
                Enum.HumanoidStateType.FallingDown,
                false
            )
        end)
    end

    if BypassModule.Config.DisableRagdollStates then
        pcall(function()
            humanoid:SetStateEnabled(
                Enum.HumanoidStateType.Ragdoll,
                false
            )
        end)
    end

    return true
end

--========================================================--
-- REAPLICAR APÓS RESPAWN
--========================================================--

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    BypassModule.ApplyCharacterSafety()
end)

--========================================================--
-- INICIALIZAÇÃO
--========================================================--

function BypassModule.ApplyAll()
    local success = BypassModule.ApplyCharacterSafety()

    if success then
        print("[Vortex Client] Proteções locais aplicadas.")
    else
        warn("[Vortex Client] Humanoid não encontrado.")
    end
end

BypassModule.ApplyAll()

return BypassModule
