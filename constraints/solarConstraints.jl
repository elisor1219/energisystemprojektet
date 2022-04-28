function readSolarConstraints(m)
    @constraints m begin
        #Solar can only produce durying the day.
        SOLAR_OUTPUT[r in REGION, h in HOUR],
        Electricity[r, :PV, h] <= InstalledCapacity[r, :PV] * PV_cf[r,h]
    end
end