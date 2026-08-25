# agents

@agent struct immatureMosquito(GridAgent{2})
    stage::Int # 0 = diapausing eggs, 1 developing eggs, 2 = quiescent eggs, 3 = larvae, 4 = pupae
    abundance::Int # number of individuals
    age::Float64 # from 0 to 1: when 1, develops
    cumFood::Float64 # sum food eated by larvae (only for larvae)
    cumTemp::Float64 # sum temperatures experienced by larvae (only for larvae)
    LSD::Float64 # larval stage duration (days)
end 

@agent struct adultMosquito(GridAgent{2})
    sex::Int # 0 = female, 1 = male
    wlength::Float64 #wing length, determining fitness
    goniotrophicIncrease::Float64 # from 0 to 1: when 1, oviposition occurs
end 