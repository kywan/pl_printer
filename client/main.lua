
local spawnedObjects = {}

local imageDisplayed = false

RegisterNetEvent('pl_printer:notification')
AddEventHandler('pl_printer:notification', function(message, type)

    if Config.Notify == 'ox' then
        TriggerEvent('ox_lib:notify', {description = message, type = type or "success"})
    elseif Config.Notify == 'esx' then
        Notification(message)
    elseif Config.Notify == 'okok' then
        TriggerEvent('okokNotify:Alert', message, 6000, type)
    elseif Config.Notify == 'qb' then
        Notification(message, type)
    elseif Config.Notify == 'wasabi' then
        exports.wasabi_notify:notify('Printer', message, 6000, type, false, 'fas fa-ghost')
    elseif Config.Notify == 'custom' then
        -- Add your custom notifications here
    end
end)

function disableControls()
    SetEntityInvincible(PlayerPedId(), true) 
    FreezeEntityPosition(PlayerPedId(), true)
end

function enableControls()
    SetEntityInvincible(PlayerPedId(), false) 
    FreezeEntityPosition(PlayerPedId(), false)
end

RegisterNetEvent("pl_printer:showImageQB")
AddEventHandler("pl_printer:showImageQB", function(imageName)
    TriggerServerEvent('pl_printer:fetchImageLink',imageName)
end)

RegisterNetEvent("pl_printer:showImage")
AddEventHandler("pl_printer:showImage", function(imageName)
    if not imageDisplayed then
        imageDisplayed = true
        SetNuiFocus(true, true) 
        SendNUIMessage({
            action = "show",
            imageUrl = imageName
        })
        disableControls()
    end
end) 

RegisterNUICallback('hideFrame', function(data, cb)
    imageDisplayed = false
    SetNuiFocus(false, false)
    enableControls()
end)

function showInputDialog(title, options, submitText)
    if Config.InputDialog == 'ox_lib' then
        return lib.inputDialog(title, options)
    elseif Config.InputDialog == 'lation_ui' then
        return exports.lation_ui:input({
            title = title,
            submitText = submitText,
            options = options
        })
    end
end

RegisterNetEvent("pl_printer:openprinter", function()
    local input = showInputDialog(Locale("print_menu"), {
        {
            type = 'input',
            label = Locale("image_link"),
            description = Locale("image_url"),
            required = true
        },
        {
            type = 'number',
            label = Locale("copies"),
            description = Locale("enter_copies"),
            required = true,
            placeholder = '1',
            icon = 'hashtag'
        }
    }, Locale("submit"))

    if not input then
        _debug('[DEBUG] No input received')
        return
    end

    local imageLink, copies = input[1], input[2]

    if imageLink and copies then
        TriggerServerEvent('pl_printer:insertImageData', imageLink, copies)
    else
        _debug('[DEBUG] Invalid input values')
    end
end)


for _, model in ipairs(Config.PrinterModel) do
    if GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetModel(model, {
            options = {
                {
                    icon = 'fa-solid fa-print',
                    label = Locale("prints"),
                    action = function(data)
                        TriggerEvent('pl_printer:openprinter')
                    end,
                },
            },
            distance = 2
        })
    elseif GetResourceState('qtarget') == 'started' or GetResourceState('ox_target') == 'started'then
        exports.ox_target:addModel(model, {
            {
                name = 'printer_interaction',
                label = Locale("prints"),
                icon = 'fa-solid fa-print',
                onSelect = function(data)
                    TriggerEvent('pl_printer:openprinter')
                end,
                distance = 2,
            }
        })
    end
end


local function spawnObject(object, coords, heading)
    lib.requestModel(object)

    if not HasModelLoaded(object) then
        _debug('[DEBUG] '..object..' failed to load.'..'')
        return
    end
    local entity = CreateObject(object, coords.x, coords.y, coords.z, true, true, true)

    if DoesEntityExist(entity) then
        SetEntityHeading(entity, heading)
        FreezeEntityPosition(entity, true)
        table.insert(spawnedObjects, entity)
    else
        _debug('[DEBUG] '..' Failed to spawn object: '..object..'')
    end
end


local function deleteSpawnedObjects()
    for _, obj in ipairs(spawnedObjects) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end
    spawnedObjects = {}
end


AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, location in ipairs(Config.Locations) do
        spawnObject(location.object, location.coords, location.heading)
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    deleteSpawnedObjects()
end)

function onPlayerLoaded()
    Wait(3000)
    for _, location in ipairs(Config.Locations) do
        spawnObject(location.object, location.coords, location.heading)
    end
end

function _debug(...)
    if Config.Debug then
        print(...)
    end
end