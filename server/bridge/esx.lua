local ESX = GetResourceState('es_extended'):find('start') and exports['es_extended']:getSharedObject() or nil

if not ESX then return end

function getPlayer(target)
    local xPlayer = ESX.GetPlayerFromId(target)
    return xPlayer
end

function RemovePlayerMoney(Player,account,TotalBill)
    if account == 'bank' then
        Player.removeAccountMoney('bank', TotalBill)
    elseif account == 'money' then
        Player.removeAccountMoney('money', TotalBill)
    end
end

function GetPlayerAccountMoney(Player,account,TotalBill)
    if account == 'bank' then
        if Player.getAccount('bank').money >= TotalBill then
            return true
        else
            return false
        end
    elseif account == 'money' then
        if Player.getAccount('money').money >= TotalBill then
            return true
        else
            return false
        end
    end
    return false
end

function HasItem(playerSource)
    local xPlayer = ESX.GetPlayerFromId(playerSource)
    if not xPlayer then return false end

    local item = xPlayer.getInventoryItem(Config.ItemName)
    if item and item.count >= 1 then
        return true
    else
        return false
    end
end

