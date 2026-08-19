function initialize(;
    n_immatureMosquitoes = 10000,
    n_adultMosquito = 0,
    dims = (20,20),
    seed = 123,
    dbm = 0,

    varParams = varParams,
    
    dt = fixedParams.dt,
    wlmin = fixedParams.wlmin,
    wlmax = fixedParams.wlmax,
    deltaE = fixedParams.deltaE,

    muEdt = 0.0,
    muJtotdt = 0.0,
    deltaJdt = 0.0,
    deltaIdt = 0.0,
    deltaGdt = 0.0,
    eggs_to_larvae = 0,
    deggs_to_larvae = 0,
    laidE = 0,
    laidED = 0,
    laidEf = 0,
    laidEDf = 0,

    totJ = 0,
    t = 1,
    it = 1
    )

    rng = Random.Xoshiro(seed)

    properties = Dict(
        :rng => rng,
        :dbm => dbm,
        :deltaEdt => deltaE*dt,
        :rhodt => varParams.rho*dt,
        :etadt => varParams.eta*dt,
        :V = Vmax, # we assume it is completely full at the beginning (as Brass/White)
        :tas => varParams.tas,
        :tasMin => varParams.tasMin,
        :tasMax => varParams.tasMax,
        :tSr => varParams.tSr,
        :muEdt => muEdt,
        :muJtotdt => muJtotdt,
        :deltaJdt => deltaJdt,
        :deltaIdt => deltaIdt,
        :sigma => varParams.sigma,
        :omega => varParams.omega,
        :muAdt => varParams.muA*dt,
        :gamma => varParams.gamma,
        :deltaGdt=> deltaGdt,
        :wlmax => wlmax,
        :wlmin => wlmin,
        :h => varParams.h,
        :K => varParams.K,
        :totJ => totJ,
        :dt => dt,
        :t => t,
        :it => it,
        :eggs_to_larvae => eggs_to_larvae,
        :deggs_to_larvae => deggs_to_larvae,
        :laidE => laidE,
        :laidED => laidED,
        :laidEf => laidEf,
        :laidEDf => laidEDf)

    space = GridSpace(dims, periodic = false) #no more GridSpaceSingle
    model = StandardABM(Union{immatureMosquito, adultMosquito}, space;
    properties, agent_step! = mosquito_step!, model_step!, rng = rng,
    agents_first = false)

    #add agents 
    if n_immatureMosquitoes > 0
        m = immatureMosquito(0, (1,1), n_immatureMosquitoes, 0, 0, 0) # lets consider non diapausing eggs
        add_agent!(m, model) #add_agent_single!
    end

    for i in 1:n_adultMosquito
        m = adultMosquito(i, (1,1), 0, 0.0, i < n_adultMosquito ? 0 : 1, 0)
        add_agent!(m, model) #add_agent_single!
    end

    return model
end

