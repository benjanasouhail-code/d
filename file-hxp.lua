--[[
    Blox Fruits Server Hop con Detección de Frutas (v1.0)
    Funcionalidad: Busca servidores con frutas del diablo y hace hop automáticamente.
    Creado para ser ejecutado con loadstring/game:HttpGet.
]]

-- Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Configuración
local Config = {
    -- Frutas que buscas prioritariamente. Los nombres deben ser exactos.
    -- Puedes encontrar los nombres exactos en la wiki de Blox Fruits o inspeccionando el juego.
    TargetFruits = {
        "Dragon Fruit",
        "Kitsune Fruit",
        "Leopard Fruit",
        "Spirit Fruit",
        "Venom Fruit",
        "Dough Fruit",
        "Control Fruit",
        "Shadow Fruit"
    },
    -- Si es true, buscará CUALQUIER fruta, no solo las de la lista.
    AnyFruit = false,
    -- Número máximo de servidores a revisar antes de rendirse y empezar de nuevo.
    MaxServersToCheck = 100,
    -- Tiempo de espera entre cada petición a la API de Roblox (para no ser limitado).
    ApiRequestDelay = 2
}

-- Variables
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local ServerHopCount = 0

-- Función para crear notificaciones visuales en el juego
function createNotification(text, duration)
    local starterGui = game:GetService("StarterGui")
    starterGui:SetCore("ChatMakeSystemMessage", {
        Color = Color3.new(1, 1, 0);
        Text = "[Fruit Hunter] " .. text;
    })
    wait(duration)
end

-- Función para obtener la lista de servidores
function getServerList(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", PlaceId)
    if cursor then
        url = url .. "&cursor=" .. cursor
    end
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and result then
        return result
    else
        createNotification("Error al obtener la lista de servidores.", 5)
        return nil
    end
end

-- Función principal para buscar servidores con frutas
function findServerWithFruit()
    createNotification("Iniciando búsqueda de servidores con frutas...", 3)
    local cursor = nil
    local serversChecked = 0
    
    while ServerHopCount < Config.MaxServersToCheck do
        ServerHopCount = ServerHopCount + 1
        local serverList = getServerList(cursor)
        
        if not serverList or not serverList.data then
            wait(Config.ApiRequestDelay)
            continue
        end
        
        for _, server in ipairs(serverList.data) do
            serversChecked = serversChecked + 1
            
            -- Revisa si el servidor tiene una fruta en su nombre o descripción (algunos servidores lo indican)
            -- Esta es una heurística simple, no es 100% fiable pero puede ayudar.
            local hasFruitHint = false
            if server.name then
                for _, fruitName in ipairs(Config.TargetFruits) do
                    if string.find(string.lower(server.name), string.lower(fruitName)) or 
                       string.find(string.lower(server.name), string.lower("fruit")) then
                        hasFruitHint = true
                        createNotification("Posible fruta '" .. fruitName .. "' encontrada en el servidor: " .. server.id, 5)
                        return server
                    end
                end
            end

            -- Si no hay pista, podemos hacer hop a servidores con baja población para tener más oportunidades
            -- Esta parte es opcional y se puede personalizar
            if server.playing < 10 and server.maxPlayers > server.playing then
                if Config.AnyFruit or hasFruitHint then
                    createNotification("Servidor con potencial encontrado (Jugadores: " .. server.playing .. "/" .. server.maxPlayers .. ")", 3)
                    return server
                end
            end
        end
        
        cursor = serverList.nextPageCursor
        if not cursor then
            createNotification("Se han revisado todos los servidores disponibles. Reiniciando búsqueda...", 5)
            ServerHopCount = 0
            wait(5)
            break
        end
        
        wait(Config.ApiRequestDelay)
    end
    
    return nil
end

-- Función para hacer hop a un servidor específico
function teleportToServer(server)
    if not server then
        createNotification("No se encontró un servidor adecuado. Reintentando en 10 segundos...", 5)
        wait(10)
        -- Llama a la función principal de nuevo para reiniciar el bucle
        startServerHopping()
        return
    end
    
    createNotification("Teletransportando al servidor " .. server.id .. "...", 3)
    
    local success, errorMsg = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
    end)
    
    if not success then
        createNotification("Error al teletransportarse: " .. tostring(errorMsg), 5)
        wait(5)
        startServerHopping() -- Reintentar
    end
end

-- Función principal que inicia el proceso
function startServerHopping()
    local targetServer = findServerWithFruit()
    teleportToServer(targetServer)
end

-- Iniciar el script
createNotification("Script de Server Hop para Frutas activado.", 3)
wait(2)
startServerHopping()