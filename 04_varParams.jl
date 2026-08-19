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

    #Psi = photperiod
    times = getSunlightTimes(dateSim, lat, lon)
    tSr = (times.sunrise .- collect(DateTime(year, 1, 1):Day(1):DateTime(year, 12, 31))) ./ Hour(1) .+ 2.0 # correction needed since time is in UTC
    Psi = @. (times.sunset - times.sunrise) / Hour(1)

    FoA = durSim-152 # first of august: last day of diapause hatching
    FoJul = durSim-183 # first of july: first day of (possible) diapause entrance

    #Elaborate weather variables
    tas7 = mMean(tas)
    tasMinDJF = minimum([tas[1:31]; tas[(1:28) .+ 31]; tas[durSim .- (0:30)]])
    
    #geo parameters (Metelmann 2019)
    CPPa = 10.058 + 0.08965 * lat  # critical photperiod in autumn

    # compute annual parameters
    sigma = ifelse.((tas7 .> fixedParams.CTTs) .& (Psi .> fixedParams.CPPs) .& (daySim .< FoA), 0.1, 0.0)# spring hatching rate (1/day) (correction sigma = 0 after august)
    omega = ifelse.((Psi .< CPPa) .& (daySim .> FoJul), 0.5, 0.0) # fraction of eggs going into diapause
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
        lat = lat,
        tas = tas,
        tasMin = tasMin,
        tasMax = tasMax,
        tSr = tSr,
        sigma = sigma,
        omega = omega,
        muA = muA,
        gamma = gamma,
        h = h,
        K = K
    )

    return(varParams)

end