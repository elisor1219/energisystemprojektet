using JuMP, AxisArrays ,Gurobi, UnPack, CSV, DataFrames, PlotlyJS

#TODO: LookOver the KW and KWH and how we use it. I think something may be off.

println("\nBuilding model...")
include("input_energisystemprojekt.jl")
@unpack REGION, PLANT, HOUR, numregions, load, maxcap , cost,
        discountrate, lifetime, efficiency, emissionFactor, inflow,
        PV_cf, wind_cf = read_input()

m = Model(Gurobi.Optimizer)

function annualisedCost(investmentCost, years)
    investmentCost * ((discountrate)/(1-(1/((1+discountrate)^years))))
end

#Constans that will be used in the model
RESERVOIR_MAX_SIZE = 33*1000000                             #[MW]
# NOT IN USE [(TWh*1 000 000) / h] = [MW]

println("\nSetting variables...")
@variables m begin
    #Variables is written in UpperCamelCase and names of constraits are
    #written in SCREAMING_SNAKE_CASE
    Electricity[r in REGION, p in PLANT, h in HOUR] >= 0            #In MW
    EnergyFuel[r in REGION, p in PLANT, h in HOUR] >= 0             #In MW
    Capacity[r in REGION, p in PLANT] >= 0                          #In MW
    Emission[r in REGION, p in PLANT] >= 0                          #ton CO_2
    RunnigCost[r in REGION, p in PLANT] >= 0                        #euro
    FuelCost[r in REGION, p in PLANT] >= 0                          #euro
    AnnualisedInvestment[r in REGION, p in PLANT] >= 0              #euro
    0 <= HydroReservoirStorage[h in HOUR] <= RESERVOIR_MAX_SIZE     #MW
end

println("\nSetting upper bounds...")
for r in REGION, p in PLANT
    set_upper_bound(Capacity[r, p], maxcap[r, p])
end

#If the program is to slow we can,
#1) No calcualte the AnnualisedInvestment for Hydro because 
#   that will alwyas be 0.
#2) Emission is only created from Gas

println("\nSetting constraints...")
@constraints m begin
    GENARTION_CAPACITY[r in REGION, p in PLANT, h in HOUR],
        Electricity[r, p, h] <= Capacity[r, p]

    #The minimum amount of energy needed.
    ELECTRICITY_NEED[r in REGION, h in HOUR],
        sum(Electricity[r, p, h] for p in PLANT) >= load[r, h]

    #The efficiency of diffrent plants. (>= is more stable then ==)
    EFFICIENCY_CONVERION[r in REGION, p in PLANT, h in HOUR],
        EnergyFuel[r,p,h] == Electricity[r,p,h] / efficiency[p]

    #The amount of CO_2 we are producing. (>= is more stable then ==)
    EMISSION[r in REGION, p in PLANT],
        Emission[r, p] >= emissionFactor[p] * sum(EnergyFuel[r, p, h] for h in HOUR)

    #The annualisedInvestment cost for all plants.
    ANNUALISED_INVESTMENT[r in REGION, p in PLANT],
        AnnualisedInvestment[r,p] >=  annualisedCost(cost[p,1]*sum(Electricity[r,p,h] for h in HOUR)/HOUR[end], lifetime[p])

    #The cost of the system per region.
    RUNNING_COST[r in REGION, p in PLANT],
        RunnigCost[r,p] >= cost[p,2]*sum(Electricity[r,p,h] for h in HOUR)

    #The price of the fuel cost. 
    FUEL_COST[r in REGION, p in PLANT],
        FuelCost[r,p] >= cost[p,3]*sum(EnergyFuel[r,p,h] for h in HOUR)

    #Specific constraints v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v

    
    #---Wind---
    #Wind can only produce when it is windy.
    WIND_OUTPUT[r in REGION, h in HOUR],
        Electricity[r, :Wind, h] <= Capacity[r, :Wind] * wind_cf[r,h]

    #---Solar (PV)---
    #Solar can only produce durying the day.
    SOLAR_OUTPUT[r in REGION, h in HOUR],
        Electricity[r, :PV, h] <= Capacity[r, :PV] * PV_cf[r,h]

    #---Hydro---
    #The inflow of "water" (power) in the hyrdo reservoir.
    INFLOW_RESERVOIR[h in 2:HOUR[end]],
        HydroReservoirStorage[h] <= HydroReservoirStorage[h-1] + inflow[h]

    #The outflow of "water" (power) in the hydro reservoir.
    OUTFLOW_RESERVOIR[h in 2:HOUR[end]],
        HydroReservoirStorage[h] <= HydroReservoirStorage[h-1] - Electricity[:SE, :Hydro, h-1]

    #Sets the first day equal to the last day.
    EQUAL_RESERVOIR,
        HydroReservoirStorage[HOUR[1]] == HydroReservoirStorage[HOUR[end]]

    #The max power the hydro can produce becuse of the water in the reservoir.
    HYDRO_POWER[h in HOUR],
        Electricity[:SE, :Hydro, h] <= HydroReservoirStorage[h]
    
    #Sets the HydroReservoirStorage to an initial value.
    HYDRO_INTIAL_SIZE,
        HydroReservoirStorage[1] == inflow[1]

end

println("\nSetting objective function...")
@objective m Min begin
    sum(sum(RunnigCost[r,p] for p in PLANT) for r in REGION) +
    sum(sum(AnnualisedInvestment[r,p] for p in PLANT) for r in REGION) +
    sum(sum(FuelCost[r,p] for p in PLANT) for r in REGION)
end


println("\nSolving model...")
optimize!(m)



if termination_status(m) == MOI.OPTIMAL
    println("\nSolve status: Optimal")
elseif termination_status(m) == MOI.TIME_LIMIT && has_values(m)
    println("\nSolve status: Reached the time-limit")
else
    error("The model was not solved correctly.")
end

systemCost = objective_value(m)/1000000 # M€
Capacity_result = value.(Capacity)

emissionResult = value(sum(Emission)) #Ton CO_2


println("Total cost: ", systemCost, " M€")
println("Total emissions: ", emissionResult, " Ton(k) CO_2")

#Calculating the total power generated from diffrent PLANTS in diffrent REGIONS
Power = AxisArray(zeros(length(REGION), length(PLANT)), REGION, PLANT)
for r in REGION, p in PLANT
    Power[r, p] = value.(sum(Electricity[r, p, :]))
end

#Calculating the power generated from diffrent plants in diffrent REGIONS.
#This will make it easier to plot later.
HourPower = AxisArray(zeros(length(HOUR), length(PLANT), length(REGION)), HOUR, PLANT, REGION)
for h in HOUR, p in PLANT, r in REGION
    HourPower[h,p,r] = value.(Electricity[r,p,h])
end


#Here the plotting part begins the plotting part------------------------------
#I think we need to take the avrage production for a day maybe.

#timeInterval = 147:147+23
timeInterval = 147:651
#timeInterval = HOUR

SE_df = DataFrame(Hour=timeInterval, 
                  Wind=HourPower[timeInterval,:Wind,:DE],
                  Solar=HourPower[timeInterval,:PV,:DE],
                  Hydro=HourPower[timeInterval,:Hydro,:DE],
                  Gas=HourPower[timeInterval,:Gas,:DE],
                  Nuclear=HourPower[timeInterval,:Nuclear,:DE]
)

long_SE_df = stack(SE_df, Not([:Hour]), variable_name="Production", value_name="MW")


#
#CSV.write("C:\\Users\\Eliso\\Documents\\Chalmers\\Studieår 3\\Läsperiod 4\\MVE347 Miljö och Matematisk Modellering\\energisystemprojektet\\export_df.csv", SE_df)
#
plot(long_SE_df, kind="bar", x=:Hour, y=:MW, color=:Production, Layout(title="Energy production Sweden", barmode="stack", bargap=0))

#
#df = dataset(DataFrame, "tips")
#plot(df, x=:total_bill, kind="histogram", color=:sex, Layout(barmode="stack"))
#
#
#plot(timeInterval,HourPower[timeInterval,:,:SE])
#plot(timeInterval,load[:SE,timeInterval])
#
#plot(HourPower[timeInterval,:,:SE], kind="bar", x=:hours, y=:MW, Layout(title="Long-Form Input", barmode="stack"))