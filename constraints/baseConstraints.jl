function readBaseConstraints(m)
    @constraints m begin
    #How much energy we are producing. Not all of the energy will be 
    #converted into electricity.
    GENARTION_CAPACITY[r in REGION, p in PLANT, h in HOUR],
        Electricity[r,p,h] <= InstalledCapacity[r, p]

    #The efficiency of diffrent plants. (>= is more stable then ==)
    #EFFICIENCY_CONVERION[r in REGION, p in PLANT, h in HOUR],
    #    EnergyFuel[r,p,h] == Electricity[r,p,h] / efficiency[p]

    #The amount of CO_2 we are producing. (>= is more stable then ==)
    EMISSION[r in REGION],
        Emission[r] == emissionFactor[:Gas] * sum(Electricity[r,:Gas,h] for h in HOUR)

    #The annualisedInvestment cost for all plants.
    ANNUALISED_INVESTMENT[r in REGION, p in PLANT],
        AnnualisedInvestment[r,p] >=  annualisedCost(cost[p,1]*InstalledCapacity[r,p], lifetime[p])

    #The cost of the system per region.
    RUNNING_COST[r in REGION, p in PLANT],
        RunnigCost[r,p] >= cost[p,2]*sum(Electricity[r,p,h]*efficiency[p] for h in HOUR)

    #The price of the fuel cost.
    FUEL_COST[r in REGION, p in PLANT],
        FuelCost[r,p] >= cost[p,3]*sum(Electricity[r,p,h] for h in HOUR)
    end
end