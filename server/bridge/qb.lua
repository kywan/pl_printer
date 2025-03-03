local QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

if not QBCore then return end

function getPlayer(target)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    return xPlayer
end

function RemovePlayerMoney(Player,account,TotalBill)
    if account == 'money' then
        Player.Functions.RemoveMoney('cash', TotalBill)
    elseif account == 'bank' then
        Player.Functions.RemoveMoney('bank', TotalBill)
    end
end

function GetPlayerAccountMoney(Player,account,TotalBill)
    if account == 'bank' then
        if Player.PlayerData.money.bank >= TotalBill then
            return true
        else
            return false
        end
    elseif account == 'money' then
        if Player.PlayerData.money.cash >= TotalBill then
            return true
        else
            return false
        end
    end
    return false
end

function HasItem(playerSource)
    if Config.CheckItem then
        return exports['qb-inventory']:HasItem(playerSource,Config.ItemName,1)
    else
        return true
    end
end

function AddItemQB(Player,amount, imageName)
    local source = Player.PlayerData.source
    local info = {
        id = imageName
    }
    if lib.checkDependency('qb-inventory', '2.0.0') then
        exports['qb-inventory']:AddItem(source,Config.ItemName,amount,false,info)
        TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[Config.ItemName], 'add', amount)
    else
        Player.Functions.AddItem(Config.ItemName, amount,false, info)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.ItemName], "add")
    end
end

QBCore.Functions.CreateUseableItem(Config.ItemName, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local item = Player.Functions.GetItemByName(Config.ItemName)
    TriggerEvent('pl_printer:fetchImageLink',item.info.id,Player.PlayerData.source)
end)
