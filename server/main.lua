local Bridge = require("bridge/loader")
local Framework = Bridge.Load()
local machineStates = {}

local function Debug(msg)
    if Config.Debug then
        print("^3[sw-moneywash]^7 " .. msg)
    end
end

local function InitializeMachineStates()
    for i, _ in ipairs(Config.MachineLocations) do
        machineStates[i] = {
            inUse = false,
            cooldown = false,
            cooldownEnd = 0,
            userId = nil
        }
    end
end

RegisterNetEvent("sw-moneywash:server:removeCard", function(cardItem)
    local src = source
    Framework.RemoveItem(src, cardItem, 1)
end)

RegisterNetEvent("sw-moneywash:server:returnCard", function(cardItem)
    local src = source
    Framework.AddItem(src, cardItem, 1)
end)

RegisterNetEvent("sw-moneywash:server:removeBlackMoney", function(amount)
    local src = source
    Framework.RemoveItem(src, "black_money", amount)
end)

RegisterNetEvent("sw-moneywash:server:collectCleanMoney", function(amount)
    local src = source
    if Framework.AddMoney(src, amount) then
        local shouldReturn = math.random(1, 100) > Config.CardLossChance
        if shouldReturn then
            Framework.AddItem(src, Config.RequiredItem, 1)
            Bridge.Notify(_L("received_money_card_returned", amount), "success", _L("money_collected"))
        else
            Bridge.Notify(_L("received_money_card_damaged", amount), "info", _L("money_collected"))
        end
    end
end)

RegisterNetEvent("sw-moneywash:server:registerActiveMachine", function(machineId)
    local src = source
    machineStates[machineId] = { inUse = true, userId = src }
    TriggerClientEvent("sw-moneywash:client:updateMachineState", -1, machineId, "inUse", src)
end)

RegisterNetEvent("sw-moneywash:server:setMachineCooldown", function(machineId, cooldownSeconds)
    local src = source
    local cooldownEnd = os.time() + cooldownSeconds
    machineStates[machineId] = { inUse = false, cooldown = true, cooldownEnd = cooldownEnd }
    TriggerClientEvent("sw-moneywash:client:updateMachineState", -1, machineId, "cooldown", nil, cooldownEnd)
    
    SetTimeout(cooldownSeconds * 1000, function()
        machineStates[machineId] = { inUse = false, cooldown = false }
        TriggerClientEvent("sw-moneywash:client:updateMachineState", -1, machineId, "available")
    end)
end)

RegisterNetEvent("sw-moneywash:server:requestMachineStates", function()
    TriggerClientEvent("sw-moneywash:client:receiveMachineStates", source, machineStates)
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    InitializeMachineStates()
end)

AddEventHandler("playerDropped", function()
    local src = source
    for i, state in pairs(machineStates) do
        if state.userId == src then
            machineStates[i] = { inUse = false }
            TriggerClientEvent("sw-moneywash:client:updateMachineState", -1, i, "available")
        end
    end
end)