function  model_step!(model)

  # zero oviposition counter
    model.laidE = 0
    model.laidED = 0

    # to correct
    model.it = max(1, abmtime(model))
    model.t = max(1, round(Int64, abmtime(model)*model.dt))
    model.dbm == 1 && println(model.t)

    tasMax0 = model.tasMax[max(1, model.t-1)]
    tasMax1 = model.tasMax[model.t]
    tasMin1 = model.tasMin[model.t]
    tasMin2 = model.tasMin[min(max(1, model.t-1), length(model.t))]
    tSr1 = model.tasMin[model.t]
    tH1 = 24*model.dt*(abmtime(model) - model.dt*floor(abmtime(model)/model.dt))

    tempH = funTempH(tH1, tasMax0, tasMax1, tasMin1, tasMin2, tSr1)
    
    # eggs parameters
    #deltaE is fixed
    model.muEdt = -log(0.955 * exp(-0.5*((tempH-18.8)/21.53)^6))*model.dt # egg mortality rate

    #juvenile parameters
    
    model.deltaJdt = model.dt/(83.85 - 4.89*tempH + 0.08*tempH^2) #juvenile development rate (in SI: 82.42 - 4.87*tempH + 0.08*tempH^ 2)
    muJ = -log(0.977 * exp(-0.5*((tempH-21.8)/16.6)^6)) # juvenile mortality rate

    # sum juveniles for mortality
    jt0 = sum(j.abundance for j in allagents(model) if j isa immatureMosquito && j.stage == 2; init = 0)

    # temp 2 https://fr.wikipedia.org/wiki/Mod%C3%A8le_de_Verhulst a => -mu, y0 => jt0, K => -mu*K
    jt1 = (-muJ*model.K[model.t])/(1 + ((-muJ*model.K[model.t])/jt0 - 1)*exp(muJ*model.dt))

    #avoid infinite value and values lower than natural mortality
    model.muJtotdt = jt1 > 0 ? max(muJ*model.dt, log(jt0/jt1)) : muJ*model.dt

    #adult development
    model.deltaIdt =  model.dt/(50.1 - 3.574*tempH + 0.069*tempH^2) #first pre blood mean rate

    # adult death

    # adult reproduction
    #model.betadt[model.it] = model.dt*(33.2*exp(-0.5*((tempH-70.3)/14.1)^2)*(38.8 - tempH)^1.5)*(tempH<= 38.8) #fertility rate

    #goniotrophic comptetion (Brass et al. 2024)
    model.deltaGdt = model.dt*max(1.93*10^-4*tempH*(tempH - 10.25)*(38.32 - min(38.32,tempH))^0.5, 0)

    #generation of new large agents four times a day
    if mod(model.it,  div(fixedParams.stepsPerDay, fixedParams.freqUpdateLargeClasses)) == 0

      if model.laidEf >0
        add_agent!(immatureMosquito, model;
                    abundance =model.laidEf, stage = 1, stageNext = 1, age = model.deltaEdt/(2*fixedParams.freqUpdateLargeClasses*model.dt)) 
                    # I assume they spent already 1/2 of the period in this class since previous update
                model.dbm == 1 && println("created ", model.laidEf, " egg(s)")
        model.laidEf = 0
      end

      # in the case if diapausing eggs, we do not create a new agent, we just increment the abundance of the existent (ID0)
      if model.laidEDf >0
        model[0].abundance += model.laidEDf
        model.dbm == 1 && println("created ", model.laidEDf, " diapausing egg(s)")
        model.laidEDf = 0
      end

      if model.deggs_to_larvae > 0
        add_agent!(immatureMosquito, model;
        abundance = model.deggs_to_larvae, stage = 2, stageNext = 2, age = model.deltaJdt/(2*fixedParams.freqUpdateLargeClasses*model.dt))
        # I assume they spent already 1/2 of the period in this class since previous update. I consider just last model.deltaJdt
        model.deggs_to_larvae = 0
      end

      if model.eggs_to_larvae > 0
        add_agent!(immatureMosquito, model;
        abundance = model.eggs_to_larvae, stage = 2, stageNext = 2, age = model.deltaJdt/(2*fixedParams.freqUpdateLargeClasses*model.dt))
        # I assume they spent already 1/2 of the period in this class since previous update. I consider just last model.deltaJdt
        model.eggs_to_larvae = 0
      end

    end

end