# agents

@agent struct immatureMosquito(GridAgent{2})
    abundance::Int # number of individuals
    stage::Int # 0 = diapasing eggs, 1 developing eggs, 2 = quiescent eggs, 3 = larvae, 4 = pupae
    cumAlpha::Float64 # average food eated by larvae (only for larvae)
    age::Float64 # from 0 to 1: when 1, develops
end 

@agent struct adultMosquito(GridAgent{2})
    stage::Int # 0 = immature adults, 1 = mature adults
    age::Float64 # from 0 to 1: when 1, develops
    sex::Int # 0 = female, 1 = male
    wlength::Float64 #wing length, determining fitness
    goniotrophicIncrease::Float64 # from 0 to 1: when 1, oviposition occurs
end 