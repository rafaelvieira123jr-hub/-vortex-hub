--[[
    VORTEX HUB - BYPASS MODULE (MÓDULO 4: ANTI-CHEAT & SEGURANÇA)
    Arquivo: bypass.lua
    Descrição:Hooks de metatable, bypassing de verificações de física/velocidade e desativação de logs locais.
--]]

local BypassModule = {}

--========================================================--
-- 1. SERVIÇOS E VARIÁVEIS LOCAIS
--========================================================--

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

BypassModule.Config = {
    AntiBanish = true,
    NoClipOverride = true,
    SpeedBypass = true
}

-- Safe table para armazenar metétodos originais
local RawMeta = getrawmetatable or debug.getmetatable or function() return {} end
local SetReadOnly = setreadonly or make_writeable or function() end

--========================================================--
-- 2. HOOKS DE METATABLE & ANULAÇÃO DE CHECAGENS
--========================================================--

function BypassModule.InitMetaHooks()
    local gmt = RawMeta(game)
    if not gmt then return end

    SetReadOnly(gmt, false)

    local oldNamecall = gmt.__namecall
    local oldIndex = gmt.__index

    -- Proteção contra detecções enviadas via RemoteEvent (Ban/Kick remotos maliciosos)
    if oldNamecall then
        gmt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if method == "FireServer" or method == "InvokeServer" then
                local remoteName = tostring(self.Name):lower()
                
                -- Intercepta remotes comuns de checagem do servidor
                if remoteName:find("ban") 
                   or remoteName:find("cheat") 
                   or remoteName:find("detection") 
                   or remoteName:find("kick") then
                    return nil
                end
            end

            return oldNamecall(self, ...)
        end)
    end

    SetReadOnly(gmt, true)
end

--========================================================--
-- 3. DESATIVAÇÃO DE SCRIPTS LOCAIS MALICIOSOS (ANTI-CHEATS LOCAIS)
--========================================================--

function BypassModule.DisableLocalAntiCheats()
    pcall(function()
        local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 3)
        if PlayerScripts then
            for _, script in ipairs(PlayerScripts:GetChildren()) do
                if script:IsA("LocalScript") then
                    local name = script.Name:lower()
                    if name:find("anticheat") or name:find("detector") or name:find("ac") then
                        script.Disabled = true
                    end
                end
            end
        end
    end)
end

--========================================================--
-- 4. BYPASS DE QUEDA E COLISÃO (NOCLIP PERMANENTE INTEGRADO)
--========================================================--

function BypassModule.EnableNoFallDamage()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if Humanoid then
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end
end

--========================================================--
-- 5. INICIALIZADOR DO MÓDULO
--========================================================--

function BypassModule.ApplyAll()
    BypassModule.InitMetaHooks()
    BypassModule.DisableLocalAntiCheats()
    BypassModule.EnableNoFallDamage()
    print("[Vortex Bypass] Proteções de Anti-Cheat aplicadas!")
end

BypassModule.ApplyAll()

return BypassModule
