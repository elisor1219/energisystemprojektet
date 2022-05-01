function readTransmissionConstraints(m)
    @constraints m begin
        #---Transmission---
        INFLOW_TRANSMISSION[r in REGION, h in HOUR],
            sum(TransmissionFromTo[r,i,h] for i in REGION) == TransmissionOutflow[r,h]#*efficiency[:Transmission]

        TRANSMISSION_TO_ELECTRICITY[r in REGION, h in HOUR],
            Electricity[r, :Transmission, h] == sum(TransmissionFromTo[i,r,h] for i in REGION)

        SEND_CAPACITY[r in REGION, h in HOUR],
            TransmissionOutflow[r,h] <= InstalledCapacity[r,:Transmission]
    end
end