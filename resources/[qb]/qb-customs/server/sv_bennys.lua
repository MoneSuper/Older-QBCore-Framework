-----------------------
----   Variables   ----
-----------------------
local QBCore = exports['qb-core']:GetCoreObject()
local RepairCosts = {}

-----------------------
----   Functions   ----
-----------------------

local function IsVehicleOwned(plate)
    local retval = false
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then retval = true end
    return retval
end

-----------------------
----   Threads     ----
-----------------------

-----------------------
---- Server Events ----
-----------------------

AddEventHandler("playerDropped", function()
	local source = source
    RepairCosts[source] = nil
end)

RegisterNetEvent('qb-customs:server:attemptPurchase', function(type, upgradeLevel)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    local moneyType = Config.MoneyType
    local balance = Player.Functions.GetMoney(moneyType)

    if type == "repair" then
        local repairCost = RepairCosts[source] or 600
        moneyType = Config.RepairMoneyType
        balance = Player.Functions.GetMoney(moneyType)
        if balance >= repairCost then
            Player.Functions.RemoveMoney(moneyType, repairCost, "bennys")
            TriggerClientEvent('qb-customs:client:purchaseSuccessful', source)
	exports['qb-management']:AddMoney("mechanic", repairCost)
        else
            TriggerClientEvent('qb-customs:client:purchaseFailed', source)
        end
    elseif type == "performance" or type == "turbo" then
        if balance >= vehicleCustomisationPrices[type].prices[upgradeLevel] then
            TriggerClientEvent('qb-customs:client:purchaseSuccessful', source)
            Player.Functions.RemoveMoney(moneyType, vehicleCustomisationPrices[type].prices[upgradeLevel], "bennys")
	exports['qb-management']:AddMoney("mechanic", vehicleCustomisationPrices[type].prices[upgradeLevel])
        else
            TriggerClientEvent('qb-customs:client:purchaseFailed', source)
        end
    else
        if balance >= vehicleCustomisationPrices[type].price then
            TriggerClientEvent('qb-customs:client:purchaseSuccessful', source)
            Player.Functions.RemoveMoney(moneyType, vehicleCustomisationPrices[type].price, "bennys")
	exports['qb-management']:AddMoney("mechanic", vehicleCustomisationPrices[type].price)
        else
            TriggerClientEvent('qb-customs:client:purchaseFailed', source)
        end
    end
end)

RegisterNetEvent('qb-customs:server:updateRepairCost', function(cost)
    local source = source
    RepairCosts[source] = cost
end)

RegisterNetEvent("qb-customs:server:updateVehicle", function(myCar)
    if IsVehicleOwned(myCar.plate) then
        MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {json.encode(myCar), myCar.plate})
    end
end)

-- Use somthing like this to dynamically enable/disable a location. Can be used to change anything at a location.
-- TriggerEvent('qb-customs:server:UpdateLocation', 'Hayes', 'settings', 'enabled', test)

RegisterNetEvent('qb-customs:server:UpdateLocation', function(location, type, key, value)
    Config.Locations[location][type][key] = value
    TriggerClientEvent('qb-customs:client:UpdateLocation', -1, location, type, key, value)
end)

QBCore.Functions.CreateCallback('qb-customs:server:GetLocations', function(_, cb)
	cb(Config.Locations)
end)
