#some one has already defined years and site

function funVarParams(year::Int, site::String, fixedParams)

    WDF = CSV.read(string("data/Meteo_",site,"_", year,".csv"), DataFrame)

    # Parameters of the site
    firstDay = Date(year)
    durSim = size(WDF,1)
    daySim = 1:durSim
    dateSim = @. firstDay + Day(daySim - 1)

    lat = WDF.lat[1]
    lon = WDF.lon[1]
    H = WDF.H[1]
    tasMax = WDF.tasMax
    tasMin = WDF.tasMin
    tas = WDF.tas
    rho = WDF.prec
    
    #hydrological parameters
    #https://www.sciencedirect.com/science/article/abs/pii/0002157177900073
    #Penman formula
    h = 100 #elevation
    Tm = tempH + 0.006*h
    Td = tempH # dew point, to change
    eta = 700*Tm/(100-lat) + 15*(tempH - Td)/(80 - tempH) # mm/day

    #Psi = photperiod
    times = getSunlightTimes(dateSim, lat, lon)
    tSr = (times.sunrise .- collect(DateTime(year, 1, 1):Day(1):DateTime(year, 12, 31))) ./ Hour(1) .+ 2.0 # correction needed since time is in UTC
    Psi = @. (times.sunset - times.sunrise) / Hour(1)
    deltaPsi = [Psi 1] - [1 Psi]

    #Elaborate weather variables
    tas7 = mMean(tas)
    tasMinDJF = minimum([tas[1:31]; tas[(1:28) .+ 31]; tas[durSim .- (0:30)]])
    
    #critical photperiod in autumn
    Phi = 0.1*abs(lat) + 9.5

    # compute annual parameters
    hD = ifelse.((tas .> 12.5) .& (Psi .> Phi) .& (deltaPsi .> 0), 1, 0)# spring hatching rate of diapasuing eggs
    D = ifelse.((tas .> 18) .& (deltaPsi .< 0), 1 .- 1 ./(1 .+ 15 .* exp.(Psi - Phi)), 1)   # fraction of eggs going into diapause
    
    muA = ifelse.(tas .>= 0, -log.(0.677 .* exp.(-0.5 .*((tas .-20.9) ./ 13.2).^6).* abs.(tas).^0.1),
    -log.(0.677 .* exp.(-0.5 .*((tas .-20.9) ./ 13.2).^6))) # adult mortality rate +correct the problems due to negative values from SI
    gamma = @. 0.93*exp(-0.5*((tasMinDJF -11.68)/15.67)^6) #survival probability of diapausing eggs (1:/inter) #at DOY = 10?

    h = @. (1-fixedParams.epsRat)*(1+fixedParams.eps0)*exp(-fixedParams.epsVar*(rho-fixedParams.epsOpt)^2)/
        (exp(-fixedParams.epsVar*(rho  -fixedParams.epsOpt)^2)+ fixedParams.eps0) +
        fixedParams.epsRat*fixedParams.epsDens/(fixedParams.epsDens + exp(-fixedParams.epsFac*H))
    
    # Compute K 
    KR = funKR(rho , daySim, fixedParams.alphaEvap, fixedParams.alphaDens)
    KH = fixedParams.alphaRain*(H^fixedParams.expH)
    K = fixedParams.lambda .* (KR .+ KH)

    varParams = (
        durSim = durSim,
        eta = eta,
        rho = rho,
        tas = tas,
        tasMin = tasMin,
        tasMax = tasMax,
        tSr = tSr,
        hD = hD,
        D = D,
        muA = muA,
        gamma = gamma,
        h = h,
        K = K
    )

    return(varParams)

end