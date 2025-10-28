
local spawnedObjects = {}

local imageDisplayed = false
local formOpen = false

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

RegisterNetEvent("pl_printer:showImage")
AddEventHandler("pl_printer:showImage", function(imageData)
    if not imageDisplayed then
        formOpen = false
        imageDisplayed = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "show",
            imageData = imageData
        })
        disableControls()
    end
end)

RegisterNUICallback('hideFrame', function(data, cb)
    imageDisplayed = false
    formOpen = false
    SetNuiFocus(false, false)
    enableControls()
    cb({})
end)

RegisterNUICallback('submitPrint', function(data, cb)
    local imageData = data and data.imageData
    local copies = tonumber(data and data.copies)
    local fileName = data and data.fileName

    if type(imageData) == 'string' and imageData:find('^data:image') then
        copies = copies and math.floor(copies)
        if copies and copies > 0 then
            TriggerServerEvent('pl_printer:insertImageData', imageData, copies, fileName)
        else
            _debug('[DEBUG] Invalid copy amount provided')
        end
    else
        _debug('[DEBUG] Invalid image data provided')
    end

    cb({})
end)

RegisterNetEvent("pl_printer:openprinter", function()
    if formOpen or imageDisplayed then return end

    formOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openUpload",
        locale = {
            title = Locale("print_menu"),
            imageLabel = Locale("upload_image"),
            imageHelper = Locale("select_image"),
            copiesLabel = Locale("copies"),
            copiesHelper = Locale("enter_copies"),
            submit = Locale("print_button"),
            cancel = Locale("cancel"),
            imageRequired = Locale("image_required"),
            uploadFailed = Locale("upload_failed")
        }
    })
    disableControls()
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
    elseif GetResourceState('qtarget') == 'started' or GetResourceState('ox_target') == 'started' then
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
