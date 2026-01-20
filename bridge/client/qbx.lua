local Bridge = {}
local QBCore = nil

function Bridge.Init()
    QBCore = exports["qb-core"]:GetCoreObject()
    return true
end

function Bridge.GetPlayerData()
    return QBCore.Functions.GetPlayerData()
end

function Bridge.HasItem(itemName)
    return exports.ox_inventory:Search("count", itemName) > 0
end

function Bridge.HasBlackMoney(amount)
    return exports.ox_inventory:Search("count", "black_money") >= amount
end

function Bridge.RegisterEvents()
    RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
        TriggerEvent("sw-moneywash:playerLoaded")
    end)
end

return Bridge