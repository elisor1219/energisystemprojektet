function readWindConstraints(m)
    @constraints m begin
    #Wind can only produce when it is windy.
    WIND_OUTPUT[r in REGION, h in HOUR],
        Electricity[r, :Wind, h] <= InstalledCapacity[r, :Wind] * wind_cf[r,h]
    end
end