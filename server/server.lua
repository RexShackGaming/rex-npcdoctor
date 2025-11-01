local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rex-npcdoctor:server:charge', function(amount)
    if not Config.ChargeOnServer or (amount or 0) <= 0 then return end
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveMoney(Config.MoneyAccount or 'cash', amount) then
        TriggerClientEvent('ox_lib:notify', src, { description = locale('paid', amount), type = 'inform' })
    else
        TriggerClientEvent('ox_lib:notify', src, { description = locale('not_enough_money'), type = 'error' })
        -- Optional: prevent action if not enough money; up to your integration
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
        else
            -- Refund if adding item fails
            Player.Functions.AddMoney(Config.MoneyAccount or 'cash', price)
            TriggerClientEvent('ox_lib:notify', src, { description = locale('purchase_failed'), type = 'error' })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { description = locale('not_enough_money'), type = 'error' })
    end
end)
