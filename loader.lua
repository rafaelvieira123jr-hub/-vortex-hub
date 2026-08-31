--[[
    VORTEX HUB - LOADER MODULE (MÓDULO 5 REVISADO)
    Arquivo: loader.lua
--]]

local GitHubUser = "rafaelvieira123jr-hub"
local Repository = "-vortex-hub"
local Branch = "main"

local BaseURL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", GitHubUser, Repository, Branch)

getgenv().VortexHub = getgenv().VortexHub or {
    Loaded = false,
    Modules = {},
    Connections = {}
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
        warn("[Vortex Hub Error] Não foi possível baixar o módulo: " .. moduleName)
        return nil
    end

    local codeFunction, compileErr = loadstring(response)
    if not codeFunction then
        warn(string.format("[Vortex Hub Error] Erro de sintaxe no módulo '%s': %s", moduleName, tostring(compileErr)))
        return nil
    end

    local execSuccess, resultModule = pcall(codeFunction)
    if not execSuccess then
        warn(string.format("[Vortex Hub Error] Erro ao executar o módulo '%s': %s", moduleName, tostring(resultModule)))
        return nil
    end

    print(string.format("[Vortex Hub] Módulo '%s' carregado com sucesso!", moduleName))
    return resultModule
end

local function InitializeVortexHub()
    print("[Vortex Hub] Baixando módulos do GitHub...")

    local bypassModule = LoadModule("bypass.lua")
    getgenv().VortexHub.Modules.Bypass = bypassModule

    local farmModule = LoadModule("farm.lua")
    getgenv().VortexHub.Modules.Farm = farmModule

    local combatModule = LoadModule("combat.lua")
    getgenv().VortexHub.Modules.Combat = combatModule

    local mainModule = LoadModule("main.lua")
    getgenv().VortexHub.Modules.Main = mainModule

    if mainModule and type(mainModule.Init) == "function" then
        mainModule.Init({
            Farm = farmModule,
            Combat = combatModule,
            Bypass = bypassModule
        })
    end

    getgenv().VortexHub.Loaded = true
    print("[Vortex Hub] Inicialização concluída!")
end

pcall(InitializeVortexHub)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not response or response == "404: Not Found" then
        error(string.format("[Vortex Hub Error] Falha ao baixar o módulo '%s' na URL: %s", moduleName, url))
        return nil
    end

    local loadSuccess, codeFunction = pcall(function()
        return loadstring(response)
    end)

    if not loadSuccess or type(codeFunction) ~= "function" then
        error(string.format("[Vortex Hub Error] Erro de compilação Luau no módulo '%s'", moduleName))
        return nil
    end

    local executeSuccess, resultModule = pcall(codeFunction)
    if not executeSuccess then
        error(string.format("[Vortex Hub Error] Erro ao executar o módulo '%s'", moduleName))
        return nil
    end

    print(string.format("[Vortex Hub] Módulo '%s' carregado com sucesso!", moduleName))
    return resultModule
end

--========================================================--
-- 3. SEQUÊNCIA DE INICIALIZAÇÃO E CARREGAMENTO
--========================================================--

local function InitializeVortexHub()
    print("[Vortex Hub] Iniciando o carregamento dos módulos do GitHub...")

    -- Step 1: Módulo de Proteção/Bypass (Deve rodar antes de qualquer outro)
    local bypassModule = LoadModule("bypass.lua")
    getgenv().VortexHub.Modules.Bypass = bypassModule

    -- Step 2: Módulo de Lógica de Farm e Movimentação
    local farmModule = LoadModule("farm.lua")
    getgenv().VortexHub.Modules.Farm = farmModule

    -- Step 3: Módulo de Lógica de Combate e Habilidades
    local combatModule = LoadModule("combat.lua")
    getgenv().VortexHub.Modules.Combat = combatModule

    -- Step 4: Interface Gráfica / Main
    local mainModule = LoadModule("main.lua")
    getgenv().VortexHub.Modules.Main = mainModule

    -- Conecta as pontas da Interface Visual (Main) com os Módulos de Lógica
    if mainModule and type(mainModule.Init) == "function" then
        mainModule.Init({
            Farm = farmModule,
            Combat = combatModule,
            Bypass = bypassModule
        })
    end

    getgenv().VortexHub.Loaded = true
    print("[Vortex Hub] Inicializado e pronto para uso!")
end

-- Executa a inicialização de forma segura
local initSuccess, initError = pcall(InitializeVortexHub)
if not initSuccess then
    warn("[Vortex Hub] Falha na inicialização: " .. tostring(initError))
    getgenv().VortexHub.Loaded = false
end
