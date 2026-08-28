function initialize(;
    n_immatureMosquitoes = 10000,
    n_adultMosquito = 0,
    dims = (20,20),
    seed = 123,
    dbm = 0.5, # debugging mode (0: no, 0.5: only time, 1: all)
    dt = fixedParams.dt,

    varParams = varParams,
    wlmin = fixedParams.wlmin,
    wlmax = fixedParams.wlmax,

    Vmax = fixedParams.sigma*fixedParams.lambda,
    sigma = fixedParams.sigma,
    GPP = 0,
    fd = fixedParams.fd,
    K = fixedParams.K,
    alpha = 0.0,

    deltaEdt = 0.0,
    muEdt = 0.0,
    muDEdt = 0.0,
    Q = 0.0,
    hQ = 0.0,
    deltaLdt = 0.0,
    muLdt = 0.0,
    muDF = fixedParams.muDF,
    muDD = fixedParams.muDD,
    deltaPdt = 0.0,
    muPdt = 0.0,
    deltaGdt = 0.0,
    #muAdt = 0.0,

    eggs_to_larvae = 0,
    deggs_to_larvae = 0,
    deggs_to_qeggs = 0,
    eggs_to_qeggs = 0,
    qeggs_to_larvae = 0,
    
    laidE = 0, #for ovposition counter
    laidED = 0, #for ovposition counter
    laidEf = 0, #for eggs generation
    laidEDf = 0, #for eggs generation

    t = 1,
    it = 1,
    tempH = 0
    )

    rng = Random.Xoshiro(seed)

    properties = Dict(
        :rng => rng,
        :dbm => dbm,
        
        :tas => varParams.tas,
        :tasMin => varParams.tasMin,
        :tasMax => varParams.tasMax,
        :tSr => varParams.tSr,
        :tempH => tempH,
        :rho => varParams.rho,
        
        :eta => varParams.eta,
        :V => Vmax/2, # Brass/White assumed it is completely full at the beginning
        :Vmax => Vmax,
        :sigma => sigma,
        :GPP => GPP,
        :fd => fd,
        :K => K,
        :alpha => alpha,

        :hD => varParams.hD,
        :D => varParams.D,

        :deltaEdt => deltaEdt,
        :muEdt => muEdt,
        :muDEdt => muDEdt,
        :Q => Q,
        :hQ => hQ,
        :deltaLdt => deltaLdt,
        :muLdt => muLdt,
        :muDFdt => muDF*dt,
        :muDDdt => muDD*dt,
        :deltaPdt => deltaPdt,
        :muPdt => muPdt,
        :deltaGdt=> deltaGdt,
        #:muAdt => muAdt,
        
        :wlmax => wlmax,
        :wlmin => wlmin,

        :dt => dt,
        :t => t,
        :it => it,
        :tempH => 0,

        :eggs_to_larvae => eggs_to_larvae,
        :deggs_to_larvae => deggs_to_larvae,
        :deggs_to_qeggs => deggs_to_qeggs,
        :eggs_to_qeggs => eggs_to_qeggs,
        :qeggs_to_larvae => qeggs_to_larvae,
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
        m = immatureMosquito(0, (1,1), 0, n_immatureMosquitoes, 0.0, 0.0, 0.0, 0.0) # lets consider non diapausing eggs
        add_agent!(m, model) #add_agent_single!
    end

    for i in 1:n_adultMosquito
        m = adultMosquito(i, (1,1),  i < n_adultMosquito/2 ? 0 : 1, 0.0, 0.0)
        add_agent!(m, model) #add_agent_single!
    end

    return model
end

