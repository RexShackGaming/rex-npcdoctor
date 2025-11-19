local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

-- Discord Webhook Function
local function SendDiscordLog(title, description, color, fields)
    if not Config.EnableDiscordLogs or not Config.DiscordWebhook or Config.DiscordWebhook == 'YOUR_WEBHOOK_URL_HERE' then
        return
    end

    local embed = {
        {
            ['title'] = title or Config.DiscordTitle,
            ['description'] = description or '',
            ['color'] = color or Config.DiscordColor,
            ['fields'] = fields or {},
            ['footer'] = {
                ['text'] = Config.DiscordFooter .. ' | ' .. os.date('%Y-%m-%d %H:%M:%S'),
            },
            ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%S'),
        }
    }

    local payload = {
        username = Config.DiscordTitle,
        avatar_url = Config.DiscordAvatar,
        embeds = embed
    }

    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers)
        -- Optional: handle response
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('rex-npcdoctor:server:charge', function(amount, actionType)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- Basic validation
    if not Player then return end
    if not Config.ChargeOnServer then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    -- Whitelist allowed action types (security)
    local validActions = { Heal = true, Revive = true }
    if not validActions[actionType] then
        actionType = 'Unknown'
    end

    local moneyType = Config.MoneyAccount or 'cash'
    local hadEnough = Player.Functions.RemoveMoney(moneyType, amount)

    if hadEnough then
        -- Success notification
         TriggerClientEvent('ox_lib:notify', src, {
             title = locale('paid_title'),
             description = locale('paid', amount),
             type = 'success',
             duration = 5000
         })

        -- Perform the actual action
        if actionType == 'Revive' then
            TriggerClientEvent(Config.Events.Revive, src)
        elseif actionType == 'Heal' then
            TriggerClientEvent(Config.Events.Heal, src)
        end

        -- Discord logging
        local charinfo = Player.PlayerData.charinfo
        local charname = ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
        if charname == '' then charname = 'Unknown' end

        SendDiscordLog(
            locale('discord_medical_service_title'),
            locale('discord_medical_service_desc', charname),
            5767168, -- Nice teal/green
            {
                { name = locale('discord_field_character'), value = charname, inline = true },
                { name = locale('discord_field_citizenid'), value = Player.PlayerData.citizenid or 'N/A', inline = true },
                { name = locale('discord_field_amount_paid'), value = '$'..amount, inline = true },
                { name = locale('discord_field_service_type'), value = actionType, inline = true },
                { name = locale('discord_field_payment_method'), value = moneyType:sub(1, 1):upper() .. moneyType:sub(2), inline = true },
                { name = locale('discord_field_serverid'), value = tostring(src), inline = true },
            }
        )
    else
        -- Not enough money
         TriggerClientEvent('ox_lib:notify', src, {
             title = locale('not_enough_money_title'),
             description = locale('not_enough_money'),
             type = 'error',
             duration = 6000
         })
    end
end)

RegisterNetEvent('rex-npcdoctor:server:purchaseItem', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local price = item.price or 0
    local amount = item.amount or 1

    if Player.Functions.RemoveMoney(Config.MoneyAccount or 'cash', price) then
		
        if Player.Functions.AddItem(item.item, amount) then
			TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.item], 'add', amount)
            TriggerClientEvent('ox_lib:notify', src, { description = locale('purchased', item.label, amount, price), type = 'success' })
            
            -- Discord Log
            local citizenid = Player.PlayerData.citizenid or 'Unknown'
            local charname = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            
            SendDiscordLog(
                locale('discord_item_purchase_title'),
                locale('discord_item_purchase_desc', charname),
                3447003, -- Blue
                {
                    { name = locale('discord_field_character'), value = charname, inline = true },
                    { name = locale('discord_field_citizenid'), value = citizenid, inline = true },
                    { name = locale('discord_field_item'), value = item.label, inline = true },
                    { name = locale('discord_field_quantity'), value = tostring(amount), inline = true },
                    { name = locale('discord_field_price'), value = '$' .. price, inline = true },
                    { name = locale('discord_field_payment_method'), value = Config.MoneyAccount, inline = true },
                }
            )
        else
            -- Refund if adding item fails
            Player.Functions.AddMoney(Config.MoneyAccount or 'cash', price)
            TriggerClientEvent('ox_lib:notify', src, { description = locale('purchase_failed'), type = 'error' })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { description = locale('not_enough_money'), type = 'error' })
    end
end)
