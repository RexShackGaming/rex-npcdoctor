# REX NPC Doctor - Documentation

## Overview

REX NPC Doctor is a RedM/RSG Framework script that spawns NPC doctors at multiple locations throughout RDR2, allowing players to heal injuries and recover from death. The script features a complete medical system with customizable pricing, Discord logging, and a built-in medical supply shop.

**Version:** 2.0.2  
**Framework:** RSG Framework (RedM)  
**Dependencies:** `rsg-core`, `ox_lib`

---

## Features

- **Multiple Doctor Locations** - 8 pre-configured doctor clinics across RDR2
- **Healing System** - Full health restoration with proportional pricing based on damage
- **Revive System** - Players can be revived when dead/fatally injured
- **Medical Shop** - Purchase medical supplies (bandages, etc.)
- **Server-Side Validation** - Secure payment processing to prevent exploits
- **Discord Logging** - All transactions logged to Discord webhooks
- **Interactive UI** - Modern ox_lib context menus
- **Dynamic Pricing** - Heal costs scale with actual damage taken
- **Customizable Locations** - Easy to add/remove doctor stations
- **Blip System** - Map markers for all doctor locations

---

## Installation

1. **Extract** the `rex-npcdoctor` folder into your RedM server's `resources` directory
2. **Add to server.cfg:**
   ```
   ensure rsg-core
   ensure ox_lib
   ensure rex-npcdoctor
   ```
3. **Configure** `shared/config.lua` with your settings (especially Discord webhook)
4. **Restart** your server or run `ensure rex-npcdoctor` in console

---

## Configuration

### Basic Settings (`shared/config.lua`)

#### Payment & Pricing
```lua
Config.HealPrice = 5              -- Cost to fully heal (set to 0 for free)
Config.RevivePrice = 10           -- Cost to revive (set to 0 for free)
Config.ChargeOnServer = true      -- Validate payments server-side
Config.MoneyAccount = 'cash'      -- Money type to charge (cash, bank, etc.)
```

#### Interaction Settings
```lua
Config.InteractKey = 0xF3830D8E   -- Key to interact (default: [J])
Config.PromptText = "Press [J] to talk to the Doctor"
Config.PointRadius = 4.5          -- Distance to trigger menu
Config.DrawTextDistance = 4.5     -- Distance to show prompt
```

#### Discord Logging
```lua
Config.EnableDiscordLogs = true
Config.DiscordWebhook = 'YOUR_WEBHOOK_URL_HERE'  -- Replace with your webhook
Config.DiscordTitle = 'NPC Doctor Log'
Config.DiscordColor = 3447003     -- Hex color for embeds
Config.DiscordFooter = 'RSG NPC Doctor System'
Config.DiscordAvatar = ''         -- Optional custom avatar URL
```

#### Event Overrides
```lua
Config.Events = {
    Heal = 'rex-npcdoctor:client:heal',
    Revive = 'rex-npcdoctor:client:revive',
}
```
*Override these events to integrate with custom medical systems*

#### Doctor Locations
```lua
Config.Doctors = {
    {
        model = 'cs_sddoctor_01',
        coords = vec4(-288.04, 804.18, 119.39, 275.78),  -- Valentine
    },
    -- Add more doctors as needed
}
```

#### Medical Shop Items
```lua
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
    -- Add more items as needed
}
```

---

## How It Works

### 1. Client-Side Flow

**Spawning & Interaction**
- On resource start, doctors are spawned at configured locations
- Each doctor location has an interactive point with a 4.5m radius
- When player enters radius, "Press J to talk to the doctor" prompt appears
- Pressing J opens the doctor menu

**Doctor Menu**
- **If player is alive:**
  - Heal option (shows cost based on damage percentage)
  - Medical Shop option
- **If player is dead/fatally injured:**
  - Revive option (shows fixed cost)

**Dynamic Heal Pricing**
The heal cost scales with damage:
```
chargeCost = ceil((HealPrice / 100) * damagePercentage)
```
- Full damage = full price
- Half damage = half price
- Already at 100% health = disabled option

### 2. Server-Side Flow

**Payment Processing** (`rex-npcdoctor:server:charge`)
1. Validates player exists
2. Whitelist checks action type (Heal/Revive only)
3. Attempts to remove money from player's account
4. If successful:
   - Triggers client-side heal/revive event
   - Logs transaction to Discord
   - Sends success notification
5. If failed:
   - Sends insufficient funds notification

**Item Purchase** (`rex-npcdoctor:server:purchaseItem`)
1. Validates player and item data
2. Removes money from account
3. Adds item to inventory
4. Shows inventory animation
5. Logs transaction to Discord
6. Auto-refunds if inventory is full

### 3. Discord Logging

All transactions are logged with:
- Player character name
- Citizen ID
- Amount paid/item price
- Service type or item name
- Payment method
- Server ID
- Timestamp

---

## Events & Exports

### Client Events

**Heal Event** (default: `rex-npcdoctor:client:heal`)
```lua
TriggerEvent('rex-npcdoctor:client:heal')
```
Heals the player to full health over 3 seconds (can be cancelled)

**Revive Event** (default: `rex-npcdoctor:client:revive`)
```lua
TriggerEvent('rex-npcdoctor:client:revive')
```
Revives dead/fatally injured players over 5 seconds (can be cancelled)

### Server Events

**Charge Event** (triggered by client)
```lua
TriggerServerEvent('rex-npcdoctor:server:charge', amount, actionType)
```
- `amount` (number): Amount to charge
- `actionType` (string): 'Heal' or 'Revive'

**Purchase Event** (triggered by client)
```lua
TriggerServerEvent('rex-npcdoctor:server:purchaseItem', item)
```
- `item` (table): Item object with price, amount, label, etc.

---

## Customization

### Add Custom Doctor Location

```lua
table.insert(Config.Doctors, {
    model = 'cs_sddoctor_01',
    coords = vec4(x, y, z, heading),
})
```

### Add Medical Shop Item

```lua
table.insert(Config.MedicalShop, {
    item = 'item_name',
    label = 'Item Label',
    price = 10,
    amount = 1,
    info = {},
    type = 'item',
    icon = 'fa-solid fa-icon-name'
})
```

### Integrate with Custom Medical System

Override the default heal/revive events:

```lua
-- Client-side
AddEventHandler('rex-npcdoctor:client:heal', function()
    -- Your custom healing logic
    TriggerEvent('your-medical-system:heal')
end)

AddEventHandler('rex-npcdoctor:client:revive', function()
    -- Your custom revive logic
    TriggerEvent('your-medical-system:revive')
end)
```

### Change Interaction Key

```lua
Config.InteractKey = 0x5B3E83F0  -- Different key code
```
[Find RedM key codes here](https://docs.fivem.net/docs/game-references/controls/)

---

## Files Structure

```
rex-npcdoctor/
├── fxmanifest.lua              -- Resource manifest
├── README.md                   -- Quick setup guide
├── LICENSE.md                  -- License info
├── shared/
│   └── config.lua              -- Configuration file
├── client/
│   └── client.lua              -- Client-side logic
├── server/
│   ├── server.lua              -- Server-side logic
│   └── versionchecker.lua      -- Version checker
└── locales/
    └── en.json                 -- English translations
```

---

## Troubleshooting

### Doctors not spawning
- Check that ped models exist: `cs_sddoctor_01` is valid
- Verify `Config.Doctors` table is populated
- Check server console for errors

### Menu not opening
- Ensure `ox_lib` is running (`ensure ox_lib`)
- Check interaction key isn't bound elsewhere
- Verify player is within `PointRadius` distance

### Payments not processing
- Verify `Config.ChargeOnServer = true`
- Check player money account: `Config.MoneyAccount`
- Ensure RSGCore is properly initialized
- Check server console for payment errors

### Discord logs not sending
- Verify webhook URL is correct
- Check `Config.EnableDiscordLogs = true`
- Ensure webhook has embed permissions
- Check server console for HTTP errors

### Items not being purchased
- Verify item exists in RSGCore shared items
- Check inventory isn't full
- Ensure item name in config matches RSGCore database
- Check `Config.MoneyAccount` has money available

---

## Performance

- **Optimized spawning:** Doctors spawn once on resource start
- **Efficient points system:** Uses ox_lib native point system
- **Server-side validation:** Prevents client-side exploits
- **Low memory footprint:** Minimal loops and event handlers

---

## Security Considerations

✅ **Server-side payment validation** - Prevents money exploitation  
✅ **Whitelisted actions** - Only 'Heal' and 'Revive' allowed  
✅ **Inventory validation** - Auto-refund if item add fails  
✅ **Discord audit trail** - All transactions logged  
✅ **RSGCore authentication** - Uses framework player validation  

---

## API Reference

### Config Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `HealPrice` | number | 5 | Cost to heal (0 = free) |
| `RevivePrice` | number | 10 | Cost to revive (0 = free) |
| `ChargeOnServer` | boolean | true | Validate payments server-side |
| `MoneyAccount` | string | 'cash' | Money account type |
| `EnableDiscordLogs` | boolean | true | Enable Discord logging |
| `PointRadius` | number | 4.5 | Interaction distance |
| `DrawTextDistance` | number | 4.5 | Prompt visibility distance |

### Doctor Table Structure

```lua
{
    model = string,        -- PED model name
    coords = vec4(x,y,z,w) -- Position and heading
}
```

### Medical Shop Item Structure

```lua
{
    item = string,    -- Item identifier
    label = string,   -- Display name
    price = number,   -- Purchase price
    amount = number,  -- Quantity given
    info = {},        -- Additional item data
    type = string,    -- Item type
    icon = string     -- Font Awesome icon
}
```

---

## Support & Credits

- **Framework:** RSG Framework
- **UI Library:** ox_lib
- **Game:** Red Dead Redemption 2 (RedM)

For issues or feature requests, check your server logs for error messages.

---

*Last Updated: 2024*
