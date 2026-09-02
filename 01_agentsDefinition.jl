# agents

@agent struct immatureMosquito(GridAgent{2})
    stage::Int # 0 = diapausing eggs, 1 developing eggs, 2 = quiescent eggs, 3 = larvae, 4 = pupae
    abundance::Int # number of individuals
    age::Float64 # from 0 to 1: when 1, develops
    cumFood::Float64 # sum food eated by larvae (only for larvae)
    cumTemp::Float64 # sum temperatures experienced by larvae (only for larvae)
    LSD::Float64 # larval stage duration (days)
    breedingSite::Int # 0 = rainfed, 1 = irrigated, 2 = both
end 

@agent struct adultMosquito(GridAgent{2})
    sex::Int # 0 = female, 1 = male
    wlength::Float64 #wing length, determining fitness
    goniotrophicIncrease::Float64 # from 0 to 1: when 1, oviposition occurs
end 

@agent struct breedingSite(GridAgent{2})
    type::Int # 1 = rainfed, 2 = irrigated, 3 = both
    Vmax::Float64 #Volume max
    V::Float64 #Volume
    Q::Float64 #fraction of eggs into quiescence
    hQ::Float64 #fraction of qeggs into larvae
    alpha::Float64 # respiration
    deltaLdt::Float64 # larval finite developent
    muLdt::Float64 # larval finite mortality
end 