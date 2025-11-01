Config = {}

-- Basic settings
Config.InteractKey = 0xF3830D8E -- default: [J] 
Config.PromptText = "Press [J] to talk to the Doctor"
Config.HealPrice = 5        -- set to 0 to make free
Config.RevivePrice = 10     -- set to 0 to make free
Config.ChargeOnServer = true -- set true to charge via server (prevents client-side exploits)
Config.MoneyAccount = 'cash'  -- rsg-core account type if charging server-side

-- Discord Webhook Settings
Config.EnableDiscordLogs = true -- set to false to disable Discord logging
Config.DiscordWebhook = 'YOUR_WEBHOOK_URL_HERE' -- Your Discord webhook URL
Config.DiscordTitle = 'NPC Doctor Log'
Config.DiscordColor = 3447003 -- Blue color (hex 0x3498DB)
Config.DiscordFooter = 'RSG NPC Doctor System'
Config.DiscordAvatar = '' -- Optional: custom avatar URL

-- Integration events (override these to plug into your own medical system)
Config.Events = {
    Heal = 'rex-npcdoctor:client:heal',       -- client event to perform a heal
    Revive = 'rex-npcdoctor:client:revive',   -- client event to perform a revive
}

-- NPC doctors you want to spawn
-- Model names must be valid RDR2 peds. Example: 'S_M_M_Doctor_01' or any shopkeeper.
Config.Doctors = {
    {
        model = 'cs_sddoctor_01',
        coords = vec4(-288.04, 804.18, 119.39, 275.78), -- Valentine Doctor clinic porch
    },
    {
        model = 'cs_sddoctor_01',
        coords = vec4(-1806.21, -429.17, 158.83, 258.73), -- Strawberry Doctor clinic porch
    },
    {
        model = 'cs_sddoctor_01',
        coords = vec4(1369.47, -1310.52, 77.94, 158.04), -- Rhodes Doctor clinic porch
    },
    {
        model = 'cs_sddoctor_01',
        coords = vec4(2727.85, -1231.97, 50.38, 89.03), -- St Denis Doctor clinic porch
    },
    {
        model = 'cs_sddoctor_01',
        coords = vec4(-840.33, -1266.62, 43.53, 90.04), -- Blackwater Doctor clinic porch
    },
    {
        model = 'cs_sddoctor_01',
        coords = vec4(-3650.26, -2646.82, -13.46, 176.43), -- Armadillo Doctor clinic porch
    },
    {
        model = 'cs_sddoctor_01',
        coords = vec4(1380.62, -7004.68, 56.84, 79.33), -- Guarma Doctor clinic porch
    },
    {
        model = 'cs_sddoctor_01',
        coords = vec4(2912.45, 1449.84, 57.47, 129.52), -- Annesburg Doctor clinic porch
    },
}

-- Interaction distances
Config.PointRadius = 4.5
Config.DrawTextDistance = 4.5

-- Medical Supplies Shop
Config.MedicalShop = {
    {
        item = 'bandage',
        label = 'Bandage',
        price = 5,
        amount = 1,
        info = {},
        type = 'item',
        icon = 'fa-solid fa-bandage'
    },
}
