using JuMP, AxisArrays ,Gurobi, UnPack, CSV, DataFrames, PlotlyJS, Format

pathToFigures = "figures/exercise2"

println("\nBuilding model...")
include("input_energisystemprojekt_exercise2b.jl")
include("constraints\\baseConstraints.jl")
include("constraints\\windConstraints.jl")
include("constraints\\solarConstraints.jl")
include("constraints\\hydroConstraints.jl")
include("constraints\\batteriesConstraints.jl")
include("helpFunctions.jl")
@unpack REGION, PLANT, HOUR, numregions, load, maxcap , cost,
        discountrate, lifetime, efficiency, emissionFactor, inflow,
        PV_cf, wind_cf = read_input()

m = Model(Gurobi.Optimizer)
#set_optimizer_attribute(m, "NumericFocus", 1)
#set_optimizer_attribute(m, "BarHomogeneous", 1)

function annualisedCost(investmentCost, years)
    investmentCost * ((discountrate)/(1-(1/((1+discountrate)^years))))
end

#Constans that will be used in the model
RESERVOIR_MAX_SIZE = 33*1000000                                     #[MWh]
MAX_EMISSION = getMaxEmission(0.1)                                  #Ton CO_2


println("\nSetting variables...")
@variables m begin
    #Variables is written in UpperCamelCase and names of constraits are
    #written in SCREAMING_SNAKE_CASE
    Electricity[r in REGION, p in PLANT, h in HOUR] >= 0            #In MW
    EnergyFuel[r in REGION, p in PLANT, h in HOUR] >= 0             #In MW
    Emission[r in REGION] >= 0                                      #In ton CO_2
    RunnigCost[r in REGION, p in PLANT] >= 0                        #In euro
    FuelCost[r in REGION, p in PLANT] >= 0                          #In euro
    AnnualisedInvestment[r in REGION, p in PLANT] >= 0              #In euro
    0 <= HydroReservoirStorage[h in HOUR] <= RESERVOIR_MAX_SIZE     #In MWh
    0 <= InstalledCapacity[r in REGION, p in PLANT] <= maxcap[r, p] #In MW
    BatteryStorage[r in REGION, h in HOUR] >= 0                                #In MWh
    BatteryInflow[r in REGION, h in HOUR] >= 0
    BatteryOutflow[r in REGION, h in HOUR] >= 0
end

#df_DE = CSV.read("C:\\Users\\Eliso\\Documents\\Chalmers\\Studieår 3\\Läsperiod 4\\MVE347 Miljö och Matematisk Modellering\\energisystemprojektet\\elecOptDE_Exer2b.csv", DataFrame)
#df_SE = CSV.read("C:\\Users\\Eliso\\Documents\\Chalmers\\Studieår 3\\Läsperiod 4\\MVE347 Miljö och Matematisk Modellering\\energisystemprojektet\\elecOptSE_Exer2b.csv", DataFrame)
#df_DE = CSV.read("C:\\Users\\Eliso\\Documents\\Chalmers\\Studieår 3\\Läsperiod 4\\MVE347 Miljö och Matematisk Modellering\\energisystemprojektet\\elecOptDK_Exer2b.csv", DataFrame)
#for p in PLANT, h in HOUR
#    set_start_value(Electricity[:DE,p,h],df_DE[!,p][h])
#end
#for p in PLANT, h in HOUR
#    set_start_value(Electricity[:SE,p,h],df_DE[!,p][h])
#end
#for p in PLANT, h in HOUR
#    set_start_value(Electricity[:DK,p,h],df_DE[!,p][h])
#end


#If the program is to slow we can,
#1) Not calcualte the AnnualisedInvestment for Hydro because
#   that will alwyas be 0.
#2)

#TODO: When adding nucler, remeber to add p in [:GAS, :Nucler] an so on.

readBaseConstraints(m)

readWindConstraints(m)

readSolarConstraints(m)

readHydroConstraints(m)

readBatteriesConstraints(m)

println("\nSetting constraints...")
@constraints m begin
    #The minimum amount of energy needed.
    ELECTRICITY_NEED[r in REGION, h in HOUR],
        sum(Electricity[r, p, h] for p in PLANT) - BatteryInflow[r,h] >= load[r, h]

    #The cap on how much CO_2 we can produce.
    MAX_EMISSION_CAP,
        sum(Emission) <= MAX_EMISSION

end

println("\nSetting objective function...")
@objective m Min begin
    sum(RunnigCost) + sum(AnnualisedInvestment) + sum(FuelCost)
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

#Find the systemcost for diffrent regions
regionCost = AxisArray(zeros(length(REGION)), REGION)
for r in REGION
    regionCost[r] = value(sum(RunnigCost[r,p] for p in PLANT)) +
    value(sum(AnnualisedInvestment[r,p] for p in PLANT)) +
    value(sum(FuelCost[r,p] for p in PLANT))
end

systemCost = objective_value(m) # €

Emission = Emission*1000 # Ton CO_2 to CO_2
totalEmissionResult = value(sum(Emission)) # CO_2




#This part is for formating and printing the value of the cost and emission v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
#Formating the values
formatedValuesCost = AxisArray(Vector{Union{Nothing, String}}(nothing, length(REGION)), REGION)
formatedValuesCost[:DE] = format(regionCost[:DE], precision=0, commas=true )
formatedValuesCost[:SE] = format(regionCost[:SE], precision=0, commas=true )
formatedValuesCost[:DK] = format(regionCost[:DK], precision=0, commas=true )

formatedValuesCO_2 = AxisArray(Vector{Union{Nothing, String}}(nothing, length(REGION)), REGION)
formatedValuesCO_2[:DE] = format(value(Emission[:DE]), precision=0, commas=true )
formatedValuesCO_2[:SE] = format(value(Emission[:SE]), precision=0, commas=true )
formatedValuesCO_2[:DK] = format(value(Emission[:DK]), precision=0, commas=true )

#Printing the values
println("Total cost: ", format(systemCost, precision=0, commas=true ), " €")
println("\tGermany: ", formatedValuesCost[:DE], " €")
println("\tSweden: ", formatedValuesCost[:SE], " €")
println("\tDenmark: ", formatedValuesCost[:DK], " €")
println("")
println("Total emissions: ", format(totalEmissionResult, precision=0, commas=true ), " CO_2")
println("\tGermany: ", formatedValuesCO_2[:DE], " CO_2")
println("\tSweden: ", formatedValuesCO_2[:SE], " CO_2")
println("\tDenmark: ", formatedValuesCO_2[:DK], " CO_2")
#This part is for formating and printing the value of the cost and emission ^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^



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



#Calculating "the average capacity factors for PV and Wind" v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
#Formating the values
formatedValuesPV = AxisArray(Vector{Union{Nothing, String}}(nothing, length(REGION)), REGION)
formatedValuesPV[:DE] = format(sum(HourPower[:,:PV,:DE])/length(HOUR), precision=0, commas=true )
formatedValuesPV[:SE] = format(sum(HourPower[:,:PV,:SE])/length(HOUR), precision=0, commas=true )
formatedValuesPV[:DK] = format(sum(HourPower[:,:PV,:DK])/length(HOUR), precision=0, commas=true )

formatedValuesWind = AxisArray(Vector{Union{Nothing, String}}(nothing, length(REGION)), REGION)
formatedValuesWind[:DE] = format(sum(HourPower[:,:Wind,:DE])/length(HOUR), precision=0, commas=true )
formatedValuesWind[:SE] = format(sum(HourPower[:,:Wind,:SE])/length(HOUR), precision=0, commas=true )
formatedValuesWind[:DK] = format(sum(HourPower[:,:Wind,:DK])/length(HOUR), precision=0, commas=true )


#Printing the values
println("- - - - - - - - - - - - - - - - - - - - - - - - - - - -")
println("Average capacity PV: ")
println("\tGermany: ", formatedValuesPV[:DE], " MW")
println("\tSweden: ", formatedValuesPV[:SE], " MW")
println("\tDenmark: ", formatedValuesPV[:DK], " MW")
println("")
println("Average capacity Wind: ")
println("\tGermany: ", formatedValuesWind[:DE], " MW")
println("\tSweden: ", formatedValuesWind[:SE], " MW")
println("\tDenmark: ", formatedValuesWind[:DK], " MW")
#Calculating "the average capacity factors for PV and Wind" ^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^





#Here begins the plotting part v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
time = 24*2
newAvrageTime = 1:floor(Int,HOUR[end]/time)
AverageDayPower = AxisArray(zeros(floor(Int,length(HOUR)/time), length(PLANT), length(REGION)), 1:HOUR[end]/time, PLANT, REGION)
for d in newAvrageTime, p in PLANT, r in REGION
    if d*time + time-1 > HOUR[end]
        break
    end
    nextAvrage = HourPower[d*time:d*time+time-1,p,r]
    average = sum(nextAvrage)/time
    AverageDayPower[d,p,r] = average
end


timeInterval = 147:651



#Ploting the average domestic generation of Germany v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
df = DataFrame(TowDays=newAvrageTime,
                  Wind=AverageDayPower[newAvrageTime,:Wind,:DE],
                  Solar=AverageDayPower[newAvrageTime,:PV,:DE],
                  Gas=AverageDayPower[newAvrageTime,:Gas,:DE],
                  Hydro=AverageDayPower[newAvrageTime,:Hydro,:DE],
                  Batteries=AverageDayPower[newAvrageTime,:Batteries,:DE],
)

long_df = stack(df, Not([:TowDays]), variable_name="Production", value_name="MW")

p1 = plot(long_df,
    kind="bar",
    x=:TowDays,
    y=:MW,
    color=:Production,
    Layout(title="The twoday-average energy production in Germany",
        barmode="stack",
        bargap=0,
        font=attr(
            size=15,
        )
    )
)




#Ploting the average domestic generation of Sweden v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
df = DataFrame(TowDays=newAvrageTime,
                  Wind=AverageDayPower[newAvrageTime,:Wind,:SE],
                  Solar=AverageDayPower[newAvrageTime,:PV,:SE],
                  Gas=AverageDayPower[newAvrageTime,:Gas,:SE],
                  Hydro=AverageDayPower[newAvrageTime,:Hydro,:SE],
                  Batteries=AverageDayPower[newAvrageTime,:Batteries,:SE],
)

long_df = stack(df, Not([:TowDays]), variable_name="Production", value_name="MW")

p2 = plot(long_df,
    kind="bar",
    x=:TowDays,
    y=:MW,
    color=:Production,
    Layout(title="The twoday-average energy production in Sweden",
        barmode="stack",
        bargap=0,
        font=attr(
            size=15,
        )
    )
)




#Ploting the average domestic generation of Denmark v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
df = DataFrame(TowDays=newAvrageTime,
                  Wind=AverageDayPower[newAvrageTime,:Wind,:DK],
                  Solar=AverageDayPower[newAvrageTime,:PV,:DK],
                  Gas=AverageDayPower[newAvrageTime,:Gas,:DK],
                  Hydro=AverageDayPower[newAvrageTime,:Hydro,:DK],
                  Batteries=AverageDayPower[newAvrageTime,:Batteries,:DK],
)

long_df = stack(df, Not([:TowDays]), variable_name="Production", value_name="MW")

p3 = plot(long_df,
    kind="bar",
    x=:TowDays,
    y=:MW,
    color=:Production,
    Layout(title="The twoday-average energy production in Denmark",
        barmode="stack",
        bargap=0,
        font=attr(
            size=15,
        )
    )
)






#Ploting the domestic generation of Germany v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
df = DataFrame(Hour=timeInterval,
                  Wind=HourPower[timeInterval,:Wind,:DE],
                  Solar=HourPower[timeInterval,:PV,:DE],
                  Gas=HourPower[timeInterval,:Gas,:DE],
                  Hydro=HourPower[timeInterval,:Hydro,:DE],
                  Batteries=HourPower[timeInterval,:Batteries,:DE],
)

long_df = stack(df, Not([:Hour]), variable_name="Production", value_name="MW")

p4 = plot(long_df,
    kind="bar",
    x=:Hour,
    y=:MW,
    color=:Production,
    Layout(title="Energy production in Germany between hour 147 and 651.",
        barmode="stack",
        bargap=0,
        font=attr(
            size=15,
        )
    )
)






#Ploting the diffrent plants in use v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
region = ["Germany", "Sweden", "Denmark"]

p5 = plot(
    [
        bar(name="Wind", x=region, y=Power[:,:Wind]),
        bar(name="Solar", x=region, y=Power[:,:PV]),
        bar(name="Gas", x=region, y=Power[:,:Gas]),
        bar(name="Hydro", x=region, y=Power[:,:Hydro]),
        bar(name="Batteries", x=region, y=Power[:,:Batteries])
    ],
    Layout(
        title="Total energy production in diffrent regions and plants.",
        yaxis_title="MW",
        font=attr(
            size=15,
        )
    )
)
relayout!(p5, barmode="group")



#Plotting the diffrent installed capacitys in the regions
p6 = plot(
    [
        bar(name="Wind", x=region, y=value.(InstalledCapacity[:,:Wind])),
        bar(name="Solar", x=region, y=value.(InstalledCapacity[:,:PV])),
        bar(name="Gas", x=region, y=value.(InstalledCapacity[:,:Gas])),
        bar(name="Hydro", x=region, y=value.(InstalledCapacity[:,:Hydro])),
        bar(name="Batteries", x=region, y=value.(InstalledCapacity[:,:Batteries]))
    ],
    Layout(
        title="Total capacity in diffrent regions and plants.",
        yaxis_title="MW",
        font=attr(
            size=15,
        )
    )
)
relayout!(p6, barmode="group")

display(p1)
display(p2)
display(p3)
display(p4)
display(p5)
display(p6)

saveFigures(pathToFigures)



##Exporting some optimal values to a CSV file
#df = DataFrame(Hour=HOUR,
#                  Wind=HourPower[HOUR,:Wind,:DE],
#                  PV=HourPower[HOUR,:PV,:DE],
#                  Gas=HourPower[HOUR,:Gas,:DE],
#                  Hydro=HourPower[HOUR,:Hydro,:DE],
#                  Batteries=HourPower[HOUR,:Batteries,:DE],
#)
#CSV.write("C:\\Users\\Eliso\\Documents\\Chalmers\\Studieår 3\\Läsperiod 4\\MVE347 Miljö och Matematisk Modellering\\energisystemprojektet\\elecOptDE_Exer2b.csv", df)
#
#df = DataFrame(Hour=HOUR,
#                  Wind=HourPower[HOUR,:Wind,:SE],
#                  PV=HourPower[HOUR,:PV,:SE],
#                  Gas=HourPower[HOUR,:Gas,:SE],
#                  Hydro=HourPower[HOUR,:Hydro,:SE],
#                  Batteries=HourPower[HOUR,:Batteries,:SE],
#)
#CSV.write("C:\\Users\\Eliso\\Documents\\Chalmers\\Studieår 3\\Läsperiod 4\\MVE347 Miljö och Matematisk Modellering\\energisystemprojektet\\elecOptSE_Exer2b.csv", df)
#
#df = DataFrame(Hour=HOUR,
#                  Wind=HourPower[HOUR,:Wind,:DK],
#                  PV=HourPower[HOUR,:PV,:DK],
#                  Gas=HourPower[HOUR,:Gas,:DK],
#                  Hydro=HourPower[HOUR,:Hydro,:DK],
#                  Batteries=HourPower[HOUR,:Batteries,:DK],
#)
#CSV.write("C:\\Users\\Eliso\\Documents\\Chalmers\\Studieår 3\\Läsperiod 4\\MVE347 Miljö och Matematisk Modellering\\energisystemprojektet\\elecOptDK_Exer2b.csv", df)
