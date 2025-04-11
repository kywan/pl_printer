
local resourceName = 'pl_printer'
lib.versionCheck('pulsepk/pl_printer')

RegisterServerEvent('pl_printer:insertImageData')
AddEventHandler('pl_printer:insertImageData', function(imageUrl, amount)
    local Player = getPlayer(source)
    local account = Config.Print.Account
    local TotalBill = Config.Print.Price*amount
    if GetPlayerAccountMoney(Player,account,TotalBill) then
        local imageName = imageUrl:match(".*/(.*)$")
        AddItem(Player,amount, imageName)
        if imageUrl and amount then
            MySQL.Async.execute('INSERT INTO printer (image_name, image_link) VALUES (@image_name, @image_link)', {
                ['@image_name'] = tostring(imageName),
                ['@image_link'] = imageUrl
            }, function(rowsChanged)
                
            end)
            RemovePlayerMoney(Player,account,TotalBill)
            TriggerClientEvent('pl_printer:notification',source,'Money removed from bank: $' .. TotalBill,'success')
        else
            _debug('[DEBUG] '..' Invalid data received for image. '..'')
        end
    else
        TriggerClientEvent('pl_printer:notification',source,'Not enough money','error')
    end
end)


RegisterServerEvent('pl_printer:fetchImageLink')
AddEventHandler('pl_printer:fetchImageLink', function(imageName,playerSource)
    local hasItem = HasItem(playerSource)
    if not hasItem then return end
    MySQL.Async.fetchScalar('SELECT image_link FROM printer WHERE image_name = @imageName', {
        ['@imageName'] = imageName
    }, function(imageLink)
        if imageLink then
            TriggerClientEvent('pl_printer:showImage',playerSource,imageLink)
        else
            _debug('[DEBUG] '..' No Image Link Found for '..imageName..'')
        end
    end)
end)

function AddItem(Player, amount, imageName)
    local src = Player.source
    if GetResourceState('qb-inventory') == 'started' then
        AddItemQB(Player,amount, imageName)
    elseif GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:AddItem(src,Config.ItemName,amount,imageName,false)
    elseif GetResourceState('qs-inventory') == 'started' then
    local itemMetadata ={ id = imageName }
        exports['qs-inventory']:AddItem(source,Config.ItemName,amount,false,itemMetadata)
    end
end

AddEventHandler('onServerResourceStart', function()
    if GetResourceState('ox_inventory') == 'started' then
        exports(Config.ItemName,function (event,item,inventory,slot,data)
            if event == 'usingItem' then
                local item_metadata = exports.ox_inventory:GetSlot(inventory.id, slot)
                TriggerEvent('pl_printer:fetchImageLink', item_metadata.metadata.type, inventory.id)
            end
        end)
    end
end)

local WaterMark = function()
    SetTimeout(1500, function()
        print('^1['..resourceName..'] ^2Thank you for Downloading the Script^0')
        print('^1['..resourceName..'] ^2If you encounter any issues please Join the discord https://discord.gg/c6gXmtEf3H to get support..^0')
        print('^1['..resourceName..'] ^2Enjoy a secret 20% OFF any script of your choice on https://pulsescripts.tebex.io/freescript^0')
        print('^1['..resourceName..'] ^2Using the coupon code: SPECIAL20 (one-time use coupon, choose wisely)^0')
    
    end)
end

WaterMark()





