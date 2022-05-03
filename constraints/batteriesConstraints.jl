function readBatteriesConstraints(m)
    @constraints m begin
        #---Batteries---
        #The inflow in the batteries. Taking away 10% to account fot the round trip efficiency.
        #INFLOW_STORAGE[r in REGION, p in PLANT, h in 2:HOUR[end]],
            #BatteryStorage[r,h] <= BatteryStorage[r,h-1] + (Electricity[r,p,h-1]-load[r,h])*efficiency[:Batteries]
            #BatteryStorage[r,h] <= BatteryStorage[r,h-1] + 1#(Electricity[r,p,h-1]-load[r,h])*efficiency[:Batteries]

        BATTERY_IN_FLOW_CAP[r in REGION, h in HOUR],
            BatteryInflow[r,h] <= InstalledCapacity[r, :Batteries]

        BATTERY_OUT_FLOW_CAP[r in REGION, h in HOUR],
            BatteryOutflow[r,h] <= InstalledCapacity[r, :Batteries]

        BATTERY_STORAGE_CAP[r in REGION, h in HOUR],
            BatteryStorage[r,h] <= InstalledCapacity[r, :Batteries]

        BATTERY_OUTFLOW_EFFICIENCY[r in REGION, h in HOUR],
            Electricity[r, :Batteries, h] == BatteryOutflow[r,h]*efficiency[:Batteries]

        #The outflow of the batteries.
        OUT_IN_FLOW_STORAGE[r in REGION, h in 1:HOUR[end-1]],
            BatteryStorage[r,h+1] == BatteryStorage[r,h] + BatteryInflow[r,h] - BatteryOutflow[r,h]

        EQUAL_TEST[r in REGION],
            BatteryStorage[r,HOUR[1]] == BatteryStorage[r,HOUR[end]]

        #The max power the batteries can produce becuse of the electricity in the storage.
        BATTERY_POWER[r in REGION, h in HOUR],
            BatteryOutflow[r,h] <= BatteryStorage[r,h]

        #Sets the BatteryStorage to an initial value.
        #BATTERY_STORAGE_INTIAL_SIZE[r in REGION],
        #    BatteryStorage[r,1] == 0
    end
end