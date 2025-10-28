if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
end
local resourceName = 'pl_printer'
lib.versionCheck('pulsepk/pl_printer')

math.randomseed(os.time())

local function generateImageName(src, originalName)
    local sanitized = 'print'

    if type(originalName) == 'string' then
        local baseName = originalName:gsub('%.%w+$', '')
        baseName = baseName:gsub('%W+', '_'):gsub('_+', '_')
        baseName = baseName:gsub('^_', ''):gsub('_$', '')
        if baseName ~= '' then
            sanitized = baseName
        end
    end

    local unique = string.format('%s_%d_%d_%d', sanitized, src or 0, os.time(), math.random(1000, 9999))
    if #unique > 120 then
        unique = unique:sub(1, 120)
    end
    return unique
end

RegisterServerEvent('pl_printer:insertImageData')
AddEventHandler('pl_printer:insertImageData', function(imageData, amount, originalName)
    local src = source
    local Player = getPlayer(src)
    if not Player then
        print(('[%s] Unable to locate player for source %s when saving image'):format(resourceName, tostring(src)))
        return
    end
    local account = Config.Print.Account
    local copies = tonumber(amount)
    copies = copies and math.floor(copies) or nil

    if not copies or copies <= 0 then
        TriggerClientEvent('pl_printer:notification', src, Locale("invalid_copies"), 'error')
        return
    end

    if type(imageData) ~= 'string' or not imageData:find('^data:image') then
        TriggerClientEvent('pl_printer:notification', src, Locale("invalid_image_data"), 'error')
        return
    end

    local TotalBill = Config.Print.Price * copies
    if GetPlayerAccountMoney(Player, account, TotalBill) then
        local imageName = generateImageName(src, originalName)
        AddItem(src, copies, imageName)
        MySQL.Async.execute('INSERT INTO printer (image_name, image_data) VALUES (@image_name, @image_data)', {
            ['@image_name'] = tostring(imageName),
            ['@image_data'] = imageData
        })
        RemovePlayerMoney(Player, account, TotalBill)
        TriggerClientEvent('pl_printer:notification', src, Locale("Money_Removed") .. TotalBill, 'success')
    else
        TriggerClientEvent('pl_printer:notification', src, Locale("not_enough"), 'error')
    end
end)


RegisterServerEvent('pl_printer:fetchImageLink')
AddEventHandler('pl_printer:fetchImageLink', function(imageName,playerSource)
    local hasItem = HasItem(playerSource)
    if not hasItem then return end
    MySQL.Async.fetchScalar('SELECT image_data FROM printer WHERE image_name = @imageName', {
        ['@imageName'] = imageName
    }, function(imageData)
        if imageData then
            TriggerClientEvent('pl_printer:showImage', playerSource, imageData)
        else
            _debug('[DEBUG] '..' No Image Link Found for '..imageName..'')
        end
    end)
end)

function AddItem(source, amount, imageName)
    local src = source
    local info = {
        id = imageName
    }
    if GetResourceState('qb-inventory') == 'started' then
        if lib.checkDependency('qb-inventory', '2.0.0') then
            exports['qb-inventory']:AddItem(src,Config.ItemName,amount,false,info)
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[Config.ItemName], 'add', amount)
        else
            local Player = getPlayer(src)
            Player.Functions.AddItem(Config.ItemName, amount,false, info)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.ItemName], "add")
        end
    elseif GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:AddItem(src, Config.ItemName, amount, { type = imageName }, false)
    end
end

AddEventHandler('onServerResourceStart', function()
    if GetResourceState('ox_inventory') == 'started' then
        exports(Config.ItemName,function (event,item,inventory,slot,data)
            if event == 'usingItem' then
                local item_metadata = exports.ox_inventory:GetSlot(inventory.id, slot)
                local metadata = item_metadata and item_metadata.metadata
                local imageId

                if type(metadata) == 'table' then
                    imageId = metadata.type or metadata.id or metadata.image_name
                elseif type(metadata) == 'string' then
                    imageId = metadata
                end

                if imageId then
                    TriggerEvent('pl_printer:fetchImageLink', imageId, inventory.id)
                else
                    print(('[%s] Unable to determine image id for ox_inventory item'):format(resourceName))
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





