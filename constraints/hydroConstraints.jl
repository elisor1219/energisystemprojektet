function readHydroConstraints(m)
    @constraints m begin
        #The inflow of "water" (power) in the hyrdo reservoir.
        #INFLOW_RESERVOIR[h in 2:HOUR[end]],
        #    HydroReservoirStorage[h] <= HydroReservoirStorage[h-1] + inflow[h]

        #The outflow of "water" (power) in the hydro reservoir.
        #OUTFLOW_RESERVOIR[h in 2:HOUR[end]],
        #    HydroReservoirStorage[h] >= HydroReservoirStorage[h-1] - Electricity[:SE, :Hydro, h-1]

        OUT_IN_FLOW_RESERVOIR[h in 1:HOUR[end-1]],
            HydroReservoirStorage[h+1] == HydroReservoirStorage[h] + inflow[h] - Electricity[:SE, :Hydro, h]

        #Sets the first day equal to the last day.
        EQUAL_RESERVOIR,
            HydroReservoirStorage[HOUR[1]] == HydroReservoirStorage[HOUR[end]]

        #The max power the hydro can produce becuse of the water in the reservoir.
        HYDRO_POWER[h in HOUR],
            Electricity[:SE, :Hydro, h] <= HydroReservoirStorage[h]

        #Sets the HydroReservoirStorage to an initial value.
        #HYDRO_INTIAL_SIZE,
        #    HydroReservoirStorage[1] == inflow[1]
    end
end