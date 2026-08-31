--[[
    VORTEX HUB - LOADER ROBUSTO (HTTP TIMEOUT FIX PARA ARQUIVOS GRANDES)
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

-- Função de download com retentativas para evitar timeout em arquivos grandes
local function SafeHttpGet(url, maxTries)
    maxTries = maxTries or 3
    for i = 1, maxTries do
        local success, response = pcall(function()
            return game:HttpGet(url .. "?cache=" .. tostring(os.time()) .. "_" .. tostring(i))
        end)
        if success and response and #response > 20 and response ~= "404: Not Found" then
            return response
        end
        task.wait(0.5)
    end
    return nil
end

local function LoadModule(moduleName)
    print("[Vortex Hub] Baixando: " .. moduleName .. "...")
    local code = SafeHttpGet(BaseURL .. moduleName)

    if not code then
        warn("[Vortex Hub Error] Falha de conexão ou timeout ao baixar: " .. moduleName)
        return nil
    end

    local codeFunction, compileErr = loadstring(code)
    if not codeFunction then
        warn("[Vortex Hub Error] Erro de compilação em " .. moduleName .. ": " .. tostring(compileErr))
        return nil
    end

    local execSuccess, resultModule = pcall(codeFunction)
    if not execSuccess then
        warn("[Vortex Hub Error] Erro de execução em " .. moduleName .. ": " .. tostring(resultModule))
        return nil
    end

    print("[Vortex Hub] Módulo '" .. moduleName .. "' carregado com sucesso!")
    return resultModule
end

print("[Vortex Hub] Iniciando carregamento do ecossistema...")

task.spawn(function()
    local bypassModule = LoadModule("bypass.lua")
    local farmModule = LoadModule("farm.lua")
    local combatModule = LoadModule("combat.lua")
    local mainModule = LoadModule("main.lua")

    if mainModule then
        if type(mainModule) == "table" and type(mainModule.Init) == "function" then
            mainModule.Init({
                Farm = farmModule,
                Combat = combatModule,
                Bypass = bypassModule
            })
        end
        getgenv().VortexHub.Loaded = true
        print("[Vortex Hub] Inicialização completa com sucesso!")
    else
        warn("[Vortex Hub Error] Não foi possível carregar a interface (main.lua).")
    end
end)
