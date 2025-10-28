
local spawnedObjects = {}

local imageDisplayed = false
local uploadOpen = false

local MAX_UPLOAD_SIZE = 2 * 1024 * 1024 -- 2MB default limit
local ALLOWED_MIME_TYPES = {
    ['image/png'] = true,
    ['image/jpeg'] = true,
    ['image/jpg'] = true,
    ['image/webp'] = true
}

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
    cb({ success = true })
end)

RegisterNetEvent("pl_printer:openprinter", function()
    if uploadOpen then return end

    uploadOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openUpload"
    })
    disableControls()
end)


RegisterNUICallback('closeUpload', function(_, cb)
    uploadOpen = false
    SetNuiFocus(false, false)
    enableControls()
    SendNUIMessage({ action = "closeUpload" })
    cb({ success = true })
end)

RegisterNUICallback('uploadImage', function(data, cb)
    if type(data) ~= 'table' then
        cb({ success = false, error = 'invalid_payload' })
        return
    end

    local copies = tonumber(data.copies or 0) or 0
    copies = math.floor(copies)
    local mimeType = tostring(data.mimeType or '')
    local base64Data = tostring(data.base64Data or '')
    local fileSize = tonumber(data.fileSize or 0) or 0
    local fileName = tostring(data.fileName or '')

    if copies < 1 then
        TriggerEvent('pl_printer:notification', Locale("invalid_copies"), 'error')
        cb({ success = false, error = 'invalid_copies' })
        return
    end

    if fileSize <= 0 or fileSize > MAX_UPLOAD_SIZE then
        TriggerEvent('pl_printer:notification', Locale("file_too_large"), 'error')
        cb({ success = false, error = 'invalid_size' })
        return
    end

    if not ALLOWED_MIME_TYPES[mimeType] then
        TriggerEvent('pl_printer:notification', Locale("invalid_file_type"), 'error')
        cb({ success = false, error = 'invalid_type' })
        return
    end

    if base64Data == '' then
        TriggerEvent('pl_printer:notification', Locale("invalid_file_data"), 'error')
        cb({ success = false, error = 'invalid_data' })
        return
    end

    local imageId = ('pl_img_%s_%s'):format(os.time(), math.random(1000, 9999))

    TriggerServerEvent('pl_printer:insertImageData', imageId, mimeType, base64Data, copies, fileName)

    uploadOpen = false
    SetNuiFocus(false, false)
    enableControls()
    SendNUIMessage({ action = "closeUpload" })

    cb({ success = true })
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
