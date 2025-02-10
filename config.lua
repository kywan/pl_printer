lib.locale()

Config = {}

Config.Debug = false

Config.Notify = 'ox' --ox, esx, okok,qb,wasabi,custom


Config.PrinterModel = {`prop_printer_02`,`prop_printer_01`}

Config.ItemName = 'paper'

Config.Print = {
    Price = 50, --Price
    Account = 'bank' --This is the account your money will be deducted
}

Config.EnableLocation = false

Config.Locations = {
    {coords = vector3(451.53, -923.32, 28.44), heading = 190.0, object = "prop_printer_02"},
    -- Add more locations with coords and heading
}

