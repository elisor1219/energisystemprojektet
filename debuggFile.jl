#Run exercise2b.jl before this file
#exercise1 had 1.387744849926479e11 kg CO_2 and 1.387744849926479e8 ton CO_2
#              138 774 484 993 kg                138 774 485 ton
#              138,774 miljarde kg (swedish)
#10% of that is = 
# =13 877 448 499.3 kg <=> 13,877 miljarde kg <=> 13 877 448 ton <=> 13,877 miljoner ton

value.(sum(Emission))           #Kg CO_2
value.(sum(Emission))/1000      #Ton CO_2
MAX_EMISSION                    #Ton CO_2


#-------------------exercise2b's data-------------------
#=
Total cost: 27,297,058,542 €
        Germany: 23,541,007,254 €
        Sweden: 2,347,739,933 €
        Denmark: 1,408,311,356 €

Total emissions: 4,634,846,244 CO_2
        Germany: 2,640,183,922 CO_2
        Sweden: 1,994,662,322 CO_2
        Denmark: 0 CO_2
- - - - - - - - - - - - - - - - - - - - - - - - - - - -
Average capacity PV:
        Germany: 22,644 MW
        Sweden: 0 MW
        Denmark: 0 MW

Average capacity Wind:
        Germany: 49,547 MW
        Sweden: 8,606 MW
        Denmark: 4,978 MW
=#

#-------------------exercise3's data-------------------
#=
Total cost: 27,726,515,281 €
        Germany: 21,540,920,192 €
        Sweden: 4,641,984,761 €
        Denmark: 1,543,610,329 €

Total emissions: 1,535,284,166 CO_2
        Germany: 91,162,940 CO_2
        Sweden: 1,444,121,225 CO_2
        Denmark: 0 CO_2
- - - - - - - - - - - - - - - - - - - - - - - - - - - -
Average capacity PV:
        Germany: 12,975 MW
        Sweden: 0 MW
        Denmark: 0 MW

Average capacity Wind:
        Germany: 50,022 MW
        Sweden: 20,391 MW
        Denmark: 5,502 MW
=#

#-------------------exercise4's data-------------------
#=
Total cost: 27,726,515,281 €
        Germany: 21,540,920,192 €
        Sweden: 4,641,983,802 €
        Denmark: 1,543,611,287 €

Total emissions: 1,535,284,166 CO_2
        Germany: 91,162,940 CO_2
        Sweden: 1,444,121,225 CO_2
        Denmark: 0 CO_2
- - - - - - - - - - - - - - - - - - - - - - - - - - - -
Average capacity PV:
        Germany: 12,974 MW
        Sweden: 0 MW
        Denmark: 0 MW

Average capacity Wind:
        Germany: 50,023 MW
        Sweden: 20,390 MW
        Denmark: 5,502 MW
=#

plot(HourPower[:,:,:SE])

plant = :PV
region = :DE
value.(AnnualisedInvestment[region,plant])
#Method 1
annualisedCost(cost[plant,1],lifetime[plant])*sum(value.(Electricity[region,plant,:]))/HOUR[end]
#Method 2
annualisedCost(cost[plant,1]*sum(value.(Electricity[region,plant,:]))/HOUR[end],lifetime[plant])
#Method 3
annualisedCost(cost[plant,1]*value.(InstalledCapacity[region,plant]),lifetime[plant])
#Method 4
annualisedCost(cost[plant,1],lifetime[plant])*value.(InstalledCapacity[region,plant])
#Method 1 and 2 are the same and 3 and 4 are also the same.


timeRange = 147:157
value.(TransmissionOutflow[:DK,timeRange])
value.(Electricity[:DE,:Transmission,timeRange])
value.(TransmissionFromTo[:SE,[:DE,:DK],timeRange])
value.(TransmissionOutflow[:SE,timeRange])

value.(Electricity[:DE,:Batteries,timeRange])
value.(BatteryInflow[:DE,timeRange])
value.(BatteryStorage[:DE,timeRange])

value.(sum(Electricity[:DE,:,:])) - value.(sum(load[:DE,:]))
value.(InstalledCapacity[:DE,:Batteries])