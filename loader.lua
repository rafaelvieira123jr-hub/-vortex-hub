--[[
    VORTEX HUB - LOADER MODULE
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
    local url = BaseURL .. moduleName
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not response or response == "404: Not Found" or response == "" then
        warn("[Vortex Hub] Falha ao baixar o arquivo: " .. moduleName)
        return nil
    end

    local codeFunction, compileErr = loadstring(response)
    if not codeFunction then
        warn("[Vortex Hub] Erro de sintaxe em " .. moduleName .. ": " .. tostring(compileErr))
        return nil
    end

    local execSuccess, resultModule = pcall(codeFunction)
    if not execSuccess then
        warn("[Vortex Hub] Erro ao executar " .. moduleName .. ": " .. tostring(resultModule))
        return nil
    end

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
    warn("[Vortex Hub] Falha ao inicializar o main.lua!")
end
