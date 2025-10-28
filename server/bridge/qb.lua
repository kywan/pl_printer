local QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

if not QBCore then return end

function getPlayer(target)
    local Player = QBCore.Functions.GetPlayer(target)
    return Player
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

QBCore.Functions.CreateUseableItem(Config.ItemName, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local item = Player and Player.Functions.GetItemByName(Config.ItemName)

    if not item or not item.info then
        TriggerClientEvent('pl_printer:notification', source, Locale("invalid_image_item"), 'error')
        return
    end

    local imageId = item.info.imageId or item.info.id

    if not imageId then
        TriggerClientEvent('pl_printer:notification', source, Locale("invalid_image_item"), 'error')
        return
    end

    TriggerEvent('pl_printer:fetchImageLink', imageId, Player.PlayerData.source)
end)
