if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
end
local resourceName = 'pl_printer'
lib.versionCheck('pulsepk/pl_printer')

RegisterServerEvent('pl_printer:insertImageData')
AddEventHandler('pl_printer:insertImageData', function(imageId, mimeType, imageData, amount, originalName)
    local Player = getPlayer(source)
    local account = Config.Print.Account

    if not Player then
        TriggerClientEvent('pl_printer:notification', source, Locale("invalid_image_item"), 'error')
        return
    end

    if type(imageId) ~= 'string' or imageId == '' then
        TriggerClientEvent('pl_printer:notification', source, Locale("invalid_file_data"), 'error')
        return
    end

    if type(imageData) ~= 'string' or imageData == '' then
        TriggerClientEvent('pl_printer:notification', source, Locale("invalid_file_data"), 'error')
        return
    end

    if type(mimeType) ~= 'string' or mimeType == '' then
        TriggerClientEvent('pl_printer:notification', source, Locale("invalid_file_type"), 'error')
        return
    end

    if type(amount) ~= 'number' then
        TriggerClientEvent('pl_printer:notification', source, Locale("invalid_copies"), 'error')
        return
    end

    amount = math.floor(amount)

    if amount < 1 then
        TriggerClientEvent('pl_printer:notification', source, Locale("invalid_copies"), 'error')
        return
    end

    local TotalBill = Config.Print.Price * amount

    if GetPlayerAccountMoney(Player, account, TotalBill) then
        AddItem(source, amount, imageId, originalName)

        MySQL.Async.execute('INSERT INTO printer (image_name, mime_type, image_data) VALUES (@image_name, @mime_type, @image_data)', {
            ['@image_name'] = tostring(imageId),
            ['@mime_type'] = mimeType,
            ['@image_data'] = imageData
        })

        RemovePlayerMoney(Player, account, TotalBill)
        TriggerClientEvent('pl_printer:notification', source, Locale("Money_Removed") .. TotalBill, 'success')
    else
        TriggerClientEvent('pl_printer:notification', source, Locale("not_enough"), 'error')
    end
end)


RegisterServerEvent('pl_printer:fetchImageLink')
AddEventHandler('pl_printer:fetchImageLink', function(imageName,playerSource)
    local hasItem = HasItem(playerSource)
    if not hasItem then return end

    if not imageName or imageName == '' then
        TriggerClientEvent('pl_printer:notification', playerSource, Locale("invalid_image_item"), 'error')
        return
    end

    MySQL.Async.fetchAll('SELECT mime_type, image_data FROM printer WHERE image_name = @imageName LIMIT 1', {
        ['@imageName'] = imageName
    }, function(result)
        local row = result and result[1]

        if row and row.image_data then
            local mimeType = row.mime_type or 'image/png'
            local dataUri = ('data:%s;base64,%s'):format(mimeType, row.image_data)
            TriggerClientEvent('pl_printer:showImage', playerSource, dataUri)
        else
            TriggerClientEvent('pl_printer:notification', playerSource, Locale("image_missing"), 'error')
        end
    end)
end)

function AddItem(source, amount, imageId, originalName)
    local src = source
    local info = {
        id = imageId,
        imageId = imageId,
        name = originalName,
        version = 2
    }
    if GetResourceState('qb-inventory') == 'started' then
        if lib.checkDependency('qb-inventory', '2.0.0') then
            exports['qb-inventory']:AddItem(src, Config.ItemName, amount, false, info)
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[Config.ItemName], 'add', amount)
        else
            local Player = getPlayer(src)
            Player.Functions.AddItem(Config.ItemName, amount, false, info)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.ItemName], "add")
        end
    elseif GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:AddItem(src, Config.ItemName, amount, {
            imageId = imageId,
            name = originalName,
            version = 2
        }, false)
    end
end

AddEventHandler('onServerResourceStart', function()
    if GetResourceState('ox_inventory') == 'started' then
        exports(Config.ItemName,function (event,item,inventory,slot,data)
            if event == 'usingItem' then
                local item_metadata = exports.ox_inventory:GetSlot(inventory.id, slot)
                local metadata = item_metadata and item_metadata.metadata or {}
                local imageId = metadata.imageId or metadata.id or metadata.type
                if imageId then
                    TriggerEvent('pl_printer:fetchImageLink', imageId, inventory.id)
                else
                    TriggerClientEvent('pl_printer:notification', inventory.id, Locale("invalid_image_item"), 'error')
                end
            end
        end)
    end
end)

local WaterMark = function()
    SetTimeout(1500, function()
        print('^1['..resourceName..'] ^2Thank you for Downloading the Script^0')
        print('^1['..resourceName..'] ^2If you encounter any issues please Join the discord https://discord.gg/c6gXmtEf3H to get support..^0')
        print('^1['..resourceName..'] ^2Enjoy a secret 20% OFF any script of your choice on https://pulsescripts.com/^0')
        print('^1['..resourceName..'] ^2Using the coupon code: SPECIAL20 (one-time use coupon, choose wisely)^0')
    
    end)
end

WaterMark()





