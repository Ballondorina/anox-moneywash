Config = {}
Config.Debug = false
Config.Framework = 'qbx' -- 'esx', 'qb', 'qbx'
Config.Language = 'en'
Config.Target = 'ox'  -- 'ox', 'qb'

Config.MinimumWashAmount = 1000
Config.WashingFeePercentage = 10
Config.CollectionTimeWindow = 45
Config.CardLossChance = 50
Config.RequiredItem = "laundry_card"

Config.UISystem = {
    Notify = "ox",
    ProgressBar = "ox",
    AlertDialog = "ox",
    InputDialog = "ox",
    TextUI = "ox",
    icon = "fa-solid fa-spray-can-sparkles"
}

Config.MachineProps = {
    idle = "bkr_prop_prtmachine_dryer",
    inserted = "bkr_prop_prtmachine_dryer_op",
    spinning = "bkr_prop_prtmachine_dryer_spin"
}

Config.MachineLocations = {
    {
        coords = vector3(456.2181, -1317.8198, 29.3128),
        heading = 139.3531,
        label = "Moneywash",
        washingTime = 40,
        cooldown = 40,
        blip = {
            enabled = true,
            sprite = 500,
            color = 62,
            scale = 0.8,
            display = 4,
            shortRange = true
        }
    },
    {
        coords = vector3(705.9923, -961.1241, 30.3953),
        heading = 95.0856,
        label = "Moneywash",
        washingTime = 60,
        cooldown = 60,
        blip = {
            enabled = true,
            sprite = 500,
            color = 62,
            scale = 0.8,
            display = 4,
            shortRange = true
        }
    },
    {
        coords = vector3(3540.5610, 3653.5337, 33.8887),
        heading = 173.6375,
        label = "Moneywash",
        washingTime = 30,
        cooldown = 30,
        blip = {
            enabled = true,
            sprite = 500,
            color = 62,
            scale = 0.8,
            display = 4,
            shortRange = true
        }
    }
}