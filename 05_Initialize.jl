function initialize(;
    n_immatureMosquitoes = 10000,
    n_adultMosquito = 0,
    dims = (20,20),
    seed = 123,
    dbm = 0, # debugging mode (0: no, 0.5: only time, 1: all)
    dt = fixedParams.dt,

    varParams = varParams,
    wlmin = fixedParams.wlmin,
    wlmax = fixedParams.wlmax,
    sigma = fixedParams.sigma,
    Vmax = fixedParams.sigma*fixedParams.lambda,

    # TO RETHINK 
    GPP = 0,
    fd = fixedParams.fd,
    alpha = 0.0,
    nr_h_hr = [1, 0, 0], # number of rainfed only reservoirs; number of human-fed only reservoirs; number of human-fed only reservoirs

    deltaEdt = 0.0,
    muEdt = 0.0,
    muDEdt = 0.0,
    deltaLdt = 0.0,
    muLdt = 0.0,
    muDF = fixedParams.muDF,
    muDD = fixedParams.muDD,
    deltaPdt = 0.0,
    muPdt = 0.0,
    deltaGdt = 0.0,
    #muAdt = 0.0,

    eggs_to_larvae = [0, 0, 0], # one for each breeding site type
    deggs_to_qeggs = [0, 0, 0],
    
    laidE = [0, 0, 0], #for eggs generation
    laidED = [0, 0, 0], #for eggs generation

    laidEf = 0, #for ovposition counter
    laidEDf = 0, #for ovposition counter

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
        :Vmax => Vmax,
        :sigma => sigma,
        :GPP => GPP,
        :fd => fd,
        :alpha => alpha,

        :nr_h_hr => nr_h_hr,

        :hD => varParams.hD,
        :D => varParams.D,

        :deltaEdt => deltaEdt,
        :muEdt => muEdt,
        :muDEdt => muDEdt,
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
        :deggs_to_qeggs => deggs_to_qeggs,

        :laidE => laidE,
        :laidED => laidED,

        :laidEf => laidEf, # fake, for oviposition
        :laidEDf => laidEDf # fake, for oviposition
        )

    space = GridSpace(dims, periodic = false) #no more GridSpaceSingle
    model = StandardABM(Union{immatureMosquito, adultMosquito, breedingSite}, space;
    properties, agent_step! = mosquito_step!, model_step!, rng = rng,
    agents_first = false)

    #add agents 
    
    for i in  5 .+ (1:n_adultMosquito)
        m = adultMosquito(i, (1,1),  i < n_adultMosquito/2 ? 0 : 1, 0.0, 0.0)
        add_agent!(m, model) #add_agent_single!
    end

    for i in  1:3 #findall(>(0), nr_h_hr)
        b = breedingSite(2+i, (2,i),  i, Vmax*nr_h_hr[i], 0.5*Vmax*nr_h_hr[i], 0.0, 0.0, 0.0, 0.0, 0.0)
        add_agent!(b, model) #add_agent_single!

        if round(n_immatureMosquitoes*nr_h_hr[i]/sum(nr_h_hr)) > 0
        m = immatureMosquito(i-1, (1,1), 0, round(n_immatureMosquitoes*nr_h_hr[i]/sum(nr_h_hr)), 0.0, 0.0, 0.0, 0.0, i) # lets consider non diapausing eggs
        add_agent!(m, model) #add_agent_single!
        end

    end

    return model
end

# agents 0, 1, 2 are ED of the 3 breeting sites
# whose ID are 3, 4, 5