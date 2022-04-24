# I den här filen kan ni stoppa all inputdata.
# Läs in datan ni fått som ligger på Canvas genom att använda paketen CSV och DataFrames

function read_input()
println("\nReading Input Data...")
folder = dirname(@__FILE__)

#Sets
REGION = [:DE, :SE, :DK]
PLANT = [:Wind, :PV, :Hydro, :Gas] # Add all plants
HOUR = 1:8760

#Parameters
numregions = length(REGION)
numhours = length(HOUR)

timeseries = CSV.read("$folder\\TimeSeries.csv", DataFrame)
wind_cf = AxisArray(ones(numregions, numhours), REGION, HOUR)
PV_cf = AxisArray(ones(numregions, numhours), REGION, HOUR)
load = AxisArray(zeros(numregions, numhours), REGION, HOUR)
inflow = AxisArray(zeros(1, numhours), [:SE], HOUR)


for r in REGION
        wind_cf[r, :]=timeseries[:, "Wind_"*"$r"]               # 0-1, share of installed cap
        PV_cf[r, :]=timeseries[:, "PV_"*"$r"]                   # 0-1, share of installed cap
        load[r, :]=timeseries[:, "Load_"*"$r"]                  # [MWh]
        inflow[:SE,:]=timeseries[:, "Hydro_inflow"]             # [MWh]
end

almostInf = typemax(Int)/1000
maxcaptable = [                                                             # GW
        # PLANT      DE             SE              DK
        :Wind        180            280             90
        :PV          460            75              60
        :Hydro       0              14               0
        :Gas       almostInf     almostInf       almostInf
        ]

maxcap = AxisArray(maxcaptable[:,2:end]'.*1000, REGION, PLANT) # MW

costTable = [
        # PLANT   Investment cost [€/MW]    Running cost [€/MWh_elec]    Fuel cost [€/MWh_fuel]
        :Wind           1100*1000                     0.1                         0
        :PV              600*1000                     0.1                         0
        :Hydro            0*1000                      0.1                         0
        :Gas             550*1000                      2                          22
        ]
cost = AxisArray(costTable[:,2:end], PLANT, [:IC, :RC, :FC])

Lifetime = [
        #Plant          #Years
        :Wind             25
        :PV               25
        :Hydro            80
        :Gas              30
        ]
lifetime = AxisArray(vec(Lifetime[:,2:end]), PLANT)

Efficiency = [
        #Plant          #Efficiency
        :Wind                1
        :PV                  1
        :Hydro               1
        :Gas                0.4
        ]
efficiency = AxisArray(vec(Efficiency[:,2:end]), PLANT)

EmissionFactor = [
        #Plant        #emission factor
        :PV                  0
        :PV                  0
        :Hydro               0
        :Gas               0.202
        ]
emissionFactor = AxisArray(vec(EmissionFactor[:,2:end]), PLANT)


discountrate=0.05


      return (; REGION, PLANT, HOUR, numregions, load, maxcap, cost,
                discountrate, lifetime, efficiency, emissionFactor, inflow,
                PV_cf, wind_cf)

end # read_input
