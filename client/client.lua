local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

local spawnedPeds = {}
local points = {}

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    return hash
end

local function spawnDoctor(cfg)
    local hash = loadModel(cfg.model)
    if not hash then return end
	local npc = CreatePed(hash, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.coords.w, false, false, false, false)
    while not DoesEntityExist(npc) do Wait(0) end
    Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetEntityCanBeDamaged(npc, false)
    spawnedPeds[#spawnedPeds+1] = npc

    local pt = lib.points.new({
        coords = cfg.coords,
        distance = Config.DrawTextDistance,
    })

    function pt:onEnter()
        lib.showTextUI(locale('prompt'))
    end

    function pt:onExit()
        lib.hideTextUI()
    end

    function pt:nearby()
        if self.currentDistance and self.currentDistance <= Config.PointRadius then
            if IsControlJustReleased(0, Config.InteractKey) then
                OpenDoctorMenu()
            end
        end
    end

    points[#points+1] = pt
end

-- blips
CreateThread(function()
    for _, v in pairs(Config.Doctors) do
        local DoctorBlip = BlipAddForCoords(1664425300, v.coords)
        SetBlipSprite(DoctorBlip, `blip_shop_doctor`, true)
        SetBlipScale(DoctorBlip, 0.2)
         SetBlipName(DoctorBlip, locale('blip_name'))
    end
end)

-- Basic heal (client-side default). Override by listening to Config.Events.Heal
RegisterNetEvent('rex-npcdoctor:client:heal', function()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        lib.notify({ description = locale('you_are_dead'), type = 'error' })
        return
    end
    local success = lib.progressBar({
        duration = 3000,
        label = locale('healing'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
    })
    if not success then return end
    local max = GetEntityMaxHealth(ped)
    SetEntityHealth(ped, max)
    ClearPedBloodDamage(ped)
    lib.notify({ description = locale('healed'), type = 'success' })
end)

-- Basic revive (client-side default). Override by listening to Config.Events.Revive
RegisterNetEvent('rex-npcdoctor:client:revive', function()
    local ped = PlayerPedId()
    if not (IsEntityDead(ped) or IsPedFatallyInjured(ped)) then
        lib.notify({ description = locale('not_dead'), type = 'warning' })
        return
    end
    local success = lib.progressBar({
        duration = 5000,
        label = locale('reviving'),
        useWhileDead = true,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
    })
    if not success then return end
	TriggerEvent('rsg-medic:client:revive')
    TriggerServerEvent('rsg-medic:server:deathactions')
    lib.notify({ description = locale('revived'), type = 'success' })
end)

function OpenDoctorMenu()
     local ped = PlayerPedId()
     if not ped or not DoesEntityExist(ped) then return end -- Safety check

     local isDead = IsEntityDead(ped) or IsPedFatallyInjured(ped, false)
     local options = {}

     if isDead then
         table.insert(options, {
             title = locale('menu_revive_title'),
             description = Config.RevivePrice > 0 and (locale('cost_format'):format(Config.RevivePrice)) or locale('free'),
             icon = 'heart-pulse',
             iconColor = '#ff4444',
             onSelect = function()
                 -- Optional: add client-side price check before charging
                 if Config.ChargeOnServer and Config.RevivePrice > 0 then
                     TriggerServerEvent('rex-npcdoctor:server:charge', Config.RevivePrice, 'Revive')
                 else
                     TriggerEvent(Config.Events.Revive)
                 end
             end
         })
     else
         -- Calculate health percentage and dynamic cost
         local currentHealth = GetEntityHealth(ped)
         local maxHealth = GetEntityMaxHealth(ped)
         local healthPercentage = (currentHealth / maxHealth) * 100

         -- Check if player is already at full health
         if healthPercentage >= 100 then
             table.insert(options, {
                 title = locale('menu_heal_title'),
                 description = locale('already_healed'),
                 icon = 'bandage',
                 iconColor = '#888888',
                 disabled = true,
             })
         else
             -- Calculate damage percentage and charge proportionally
             local damagePercentage = 100 - healthPercentage
             local chargeCost = math.ceil((Config.HealPrice / 100) * damagePercentage)

             table.insert(options, {
                 title = locale('menu_heal_title'),
                 description = Config.HealPrice > 0 and (locale('cost_format'):format(chargeCost)) or locale('free'),
                 icon = 'bandage',
                 iconColor = '#44ff44',
                 onSelect = function()
                     if Config.ChargeOnServer and Config.HealPrice > 0 then
                         TriggerServerEvent('rex-npcdoctor:server:charge', chargeCost, 'Heal')
                     else
                         TriggerEvent(Config.Events.Heal)
                     end
                 end
             })
         end

        -- Medical shop
        table.insert(options, {
            title = locale('menu_shop_title'),
            description = locale('menu_shop_desc'),
            icon = 'shopping-bag',
            iconColor = '#44aaff',
            arrow = true, -- visual indicator that it opens another menu
            onSelect = function()
                OpenMedicalShop()
            end
        })
    end

    lib.registerContext({
        id = 'rex_npcdoctor_menu',
        title = locale('doctor_menu_title'),
        menu = 'rex_npcdoctor_menu', -- allows going back if nested
        onExit = function()
            -- Optional: play animation cancel or sound
        end,
        options = options
    })

    lib.showContext('rex_npcdoctor_menu')
end

function OpenMedicalShop()
    local shopOptions = {}
    
    for _, item in ipairs(Config.MedicalShop) do
        shopOptions[#shopOptions+1] = {
             title = item.label,
             description = locale('cost_format'):format(item.price),
             icon = item.icon,
             onSelect = function()
                 TriggerServerEvent('rex-npcdoctor:server:purchaseItem', item)
             end
         }
    end
    
    shopOptions[#shopOptions+1] = {
        title = locale('menu_back'),
        icon = 'arrow-left',
        onSelect = function()
            OpenDoctorMenu()
        end
    }
    
    lib.registerContext({
        id = 'rex_npcdoctor_shop',
        title = locale('shop_title'),
        options = shopOptions
    })
    lib.showContext('rex_npcdoctor_shop')
end

CreateThread(function()
    -- spawn configured doctors
    for _, doc in ipairs(Config.Doctors or {}) do
        spawnDoctor(doc)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Delete all spawned NPCs
    for i = 1, #spawnedPeds do
        local ped = spawnedPeds[i]
        if DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, true, true)
            DeletePed(ped)
            SetEntityAsNoLongerNeeded(ped)
        end
    end
    
    -- Remove all interaction points
    for i = 1, #points do
        if points[i] then
            points[i]:remove()
        end
    end
    
    -- Clear tables
    spawnedPeds = {}
    points = {}
end)
