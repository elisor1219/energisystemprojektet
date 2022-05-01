function saveFigures(pathToFigures)
    savefig(p1, string(pathToFigures,"/germany.svg"))
    savefig(p2, string(pathToFigures,"/sweden.svg"))
    savefig(p3, string(pathToFigures,"/denmark.svg"))
    savefig(p4, string(pathToFigures,"/germany147-651.svg"))
    savefig(p5, string(pathToFigures,"/plants.svg"))
    savefig(p6, string(pathToFigures,"/capacity.svg"))
end

function getMaxEmission(percentage)
    #This will return the max emission the model is able to produce, in ton CO_2
    return 138608551.174*percentage
end