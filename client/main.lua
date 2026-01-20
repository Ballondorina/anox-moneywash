local Bridge = require("bridge/loader")
local Framework = Bridge.Load()
local machineObjects = {}
local activeMachines = {}
local globalMachineStates = {}
local activeZones = {}
local displayingCooldown = {}
local activeTextUI = nil

local function Debug(msg)
    if Config.Debug then
        print("^3[sw-moneywash]^7 " .. msg)
    end
end

local function SyncMachineStates()
    TriggerServerEvent("sw-moneywash:server:requestMachineStates")
end

local function CreateWashingMachines()
    for i, machine in ipairs(Config.MachineLocations) do
        local prop = CreateObject(GetHashKey(Config.MachineProps.idle), machine.coords.x, machine.coords.y, machine.coords.z - 1.0, false, false, false)
        SetEntityHeading(prop, machine.heading)
        FreezeEntityPosition(prop, true)
        machineObjects[i] = {
            object = prop,
            state = "idle",
            id = i
        }
    end
end

local function ChangeMachineState(machineId, state)
    if not machineObjects[machineId] then return end
    local machine = machineObjects[machineId]
    local coords = GetEntityCoords(machine.object)
    local heading = GetEntityHeading(machine.object)
    DeleteEntity(machine.object)
    local propName = Config.MachineProps.idle
    if state == "inserted" then
        propName = Config.MachineProps.inserted
    elseif state == "spinning" then
        propName = Config.MachineProps.spinning
    end
    local prop = CreateObject(GetHashKey(propName), coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(prop, heading)
    FreezeEntityPosition(prop, true)
    machineObjects[machineId].object = prop
    machineObjects[machineId].state = state
end

local function SetupTargetInteractions()
    for i, machine in ipairs(Config.MachineLocations) do
        local options = {
            {
                name = "sw_moneywash:useMachine_" .. i,
                icon = Config.UISystem.icon,
                label = _L("use_washing_machine"),
                distance = 2.0,
                onSelect = function()
                    UseMachine(i)
                end,
                canInteract = function()
                    if activeMachines[i] and (activeMachines[i].cooldown or activeMachines[i].processing or activeMachines[i].moneyReady) then
                        return false
                    end
                    return true
                end
            },
            {
                name = "sw_moneywash:collectMoney_" .. i,
                icon = "fa-solid fa-money-bill-wave",
                label = _L("collect_clean_money"),
                distance = 2.0,
                onSelect = function()
                    CollectCleanMoney(i)
                end,
                canInteract = function()
                    return activeMachines[i] and activeMachines[i].moneyReady
                end
            },
            {
                name = "sw_moneywash:retrieveCard_" .. i,
                icon = "fa-solid fa-credit-card",
                label = _L("retrieve_laundry_card"),
                distance = 2.0,
                onSelect = function()
                    RetrieveCard(i)
                end,
                canInteract = function()
                    return activeMachines[i] and activeMachines[i].cardInserted and not activeMachines[i].processing
                end
            }
        }
        local zoneId = Bridge.Target.AddBoxZone({
            name = "sw_moneywash:machine_" .. i,
            coords = machine.coords,
            size = vec3(1.5, 1.5, 2.0),
            rotation = machine.heading,
            debug = Config.Debug,
            options = options,
            distance = 2.0
        })
        activeZones[i] = zoneId
    end
end

function UseMachine(machineId)
    if activeMachines[machineId] then
        if activeMachines[machineId].cooldown then
            local remainingTime = math.floor((activeMachines[machineId].cooldownEnd - GetGameTimer()) / 1000)
            Bridge.Notify(_L("machine_cooldown", remainingTime), "error", _L("machine_unavailable"))
            return
        elseif activeMachines[machineId].processing or activeMachines[machineId].moneyReady then
            Bridge.Notify(_L("machine_already_in_use"), "error", _L("machine_in_use"))
            return
        elseif activeMachines[machineId].cardInserted then
            Bridge.Notify(_L("proceed_to_money_entry"), "info", _L("card_already_inserted"))
            ProceedToMoneyInput(machineId)
            return
        end
    end

    TriggerServerEvent("sw-moneywash:server:checkMachineStatus", machineId)
    Wait(200)

    if not Framework.HasItem(Config.RequiredItem) then
        Bridge.Notify(_L("no_laundry_card"), "error", _L("missing_item"))
        return
    end

    local alert = Bridge.AlertDialog(
        _L("money_washing"), 
        _L("money_wash_info", 
            Config.MinimumWashAmount, 
            Config.WashingFeePercentage, 
            Config.MachineLocations[machineId].washingTime,
            Config.MachineLocations[machineId].cooldown,
            Config.CollectionTimeWindow
        ), 
        "moneyWash"
    )
    if alert ~= "confirm" then return end

    TriggerServerEvent("sw-moneywash:server:removeCard", Config.RequiredItem)
    if not Bridge.ProgressBar(_L("inserting_card"), 2000, "cardInsert") then
        TriggerServerEvent("sw-moneywash:server:returnCard", Config.RequiredItem)
        return
    end

    activeMachines[machineId] = { cardInserted = true }
    TriggerServerEvent("sw-moneywash:server:registerActiveMachine", machineId)
    ChangeMachineState(machineId, "inserted")
    ProceedToMoneyInput(machineId)
end

function ProceedToMoneyInput(machineId)
    local input = Bridge.InputDialog(_L("enter_amount_header"), "moneyAmount")
    if not input or not input[1] then return end
    
    local amount = tonumber(input[1])
    if not Framework.HasBlackMoney(amount) then
        Bridge.Notify(_L("not_enough_money_card_remains"), "error", _L("not_enough_black_money"))
        return
    end

    local fee = math.floor(amount * (Config.WashingFeePercentage / 100))
    local finalAmount = amount - fee
    StartWashingProcess(machineId, amount, finalAmount)
end

function StartWashingProcess(machineId, dirtyAmount, cleanAmount)
    activeMachines[machineId].processing = true
    activeMachines[machineId].cardInserted = nil
    TriggerServerEvent("sw-moneywash:server:removeBlackMoney", dirtyAmount)
    Wait(1000)
    ChangeMachineState(machineId, "spinning")

    local washingTime = Config.MachineLocations[machineId].washingTime or 30
    activeMachines[machineId] = {
        dirtyAmount = dirtyAmount,
        cleanAmount = cleanAmount,
        endTime = GetGameTimer() + (washingTime * 1000),
        processing = true,
        moneyReady = false
    }

    StartMachineCountdown(machineId)
    Bridge.Notify(_L("machine_washing", dirtyAmount), "success", _L("washing_started"))

    CreateThread(function()
        while activeMachines[machineId] do
            local currentTime = GetGameTimer()
            if activeMachines[machineId].processing and not activeMachines[machineId].moneyReady and currentTime > activeMachines[machineId].endTime then
                Bridge.Notify(_L("money_ready_collection", Config.CollectionTimeWindow), "success", _L("washing_complete"))
                activeMachines[machineId].processing = false
                activeMachines[machineId].moneyReady = true
                activeMachines[machineId].collectionEndTime = currentTime + (Config.CollectionTimeWindow * 1000)
                StartCollectionCountdown(machineId)
            end

            if activeMachines[machineId].moneyReady and currentTime > activeMachines[machineId].collectionEndTime then
                Bridge.Notify(_L("failed_collect_time"), "error", _L("money_lost"))
                local cooldownTime = Config.MachineLocations[machineId].cooldown or 30
                TriggerServerEvent("sw-moneywash:server:setMachineCooldown", machineId, cooldownTime)
                activeMachines[machineId] = {
                    cooldown = true,
                    cooldownEnd = currentTime + (cooldownTime * 1000)
                }
                ChangeMachineState(machineId, "idle")
                return
            end
            Wait(1000)
        end
    end)
end

function CollectCleanMoney(machineId)
    if not activeMachines[machineId] or not activeMachines[machineId].moneyReady then return end
    if not Bridge.ProgressBar(_L("collecting_money"), 2000, "collectMoney") then return end

    TriggerServerEvent("sw-moneywash:server:collectCleanMoney", activeMachines[machineId].cleanAmount)
    local cooldownTime = Config.MachineLocations[machineId].cooldown or 30
    TriggerServerEvent("sw-moneywash:server:setMachineCooldown", machineId, cooldownTime)
    
    activeMachines[machineId] = {
        cooldown = true,
        cooldownEnd = GetGameTimer() + (cooldownTime * 1000)
    }
    ChangeMachineState(machineId, "idle")
end

RegisterNetEvent("sw-moneywash:client:receiveMachineStates", function(states)
    for machineId, state in pairs(states) do
        if state.cooldown then
            local remainingTime = state.cooldownEnd - os.time()
            if remainingTime > 0 then
                activeMachines[machineId] = {
                    cooldown = true,
                    cooldownEnd = GetGameTimer() + (remainingTime * 1000)
                }
            end
        end
    end
end)

RegisterNetEvent("sw-moneywash:client:updateMachineState", function(machineId, state, userId, cooldownEnd)
    if state == "inUse" and userId ~= GetPlayerServerId(PlayerId()) then
        activeMachines[machineId] = { externalUse = true }
    elseif state == "available" then
        activeMachines[machineId] = nil
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CreateWashingMachines()
    SetupTargetInteractions()
    SyncMachineStates()
end)