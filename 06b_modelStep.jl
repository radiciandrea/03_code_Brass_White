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

    #hydrological functioning (CORRECT UNIT OF MEASURES)
    Vprec = model.V
    model.V = max(0, min(Vprec + model.mu*(model.rho[model.t] - model.eta[model.t]), model.Vmax)) 

    # eggs parameters

    # development
    model.deltaE = max(-0.0008256*tempH^2 + 0.0334072*tempH - 0.0557825, 0.01)*model.dt # egg temperature reaction norm (development)
    
    # mortality
    model.muEdt = -log(12.217/(6.115*sqrt(2*pi))*exp(-0.5*(tempH - 24.672)^2/6.115^2))*model.dt # egg mortality rate
    model.muEdt = tempH > -12 ? 0.01*model.dt : 0.1*model.dt # diapausing egg mortality rate

    # quiescence entrancy (only once a day?)
    model.Q = model.V < Vprec ? 1 - model.V/model.Vmax : 0

    #Hatching out of quiescent class
    model.hQ = model.V > Vprec ? model.V/model.Vmax : 0

    #larval parameters

    #Primary production of the larval habitat
    model.F = (10^-6 * log10(0.45 + 0.095*tempH)*model.V + model.fd)*model.dt

    #total number of larvae
    L = sum(l.abundance for l in allagents(model) if l isa immatureMosquito && l.stage == 3; init = 0)

    # Food available per larvae
    model.alpha = model.F/L

    # development (from GLM)
    model.deltaLdt = x

    # mortality (from GLM)
    if model.V > 0
      if (model.V < model.Vmax) && (model.rho*model.mu < 0.5 * model.Vmax)
        model.muLdt =x
      else
         model.muLdt =x
      end
    else
      model.muLdt =x
    end

    # Pupae parameters
    
    #development
    model.deltaPdt = -log(max(2.916*10^(-5)*tempH*(tempH - 10.08)*(47.68 - tempH)^(1/0.8317), 0.01))*model.dt

    # mortality 
    if model.V > 0
      if (model.V < model.Vmax) && (model.rho*model.mu < 0.5 * model.Vmax)
        model.muPdt = -log(max(-0.0070628*tempH^2 + 0.3331028*tempH - 2.9878761, 0.01))*model.dt
      else
         model.muPdt = model.muDD*model.dt
      end
    else
      model.muPdt = model.muDF*model.dt
    end

    # Adult parameters

    # size (wing lenght)

    # goniotrophic cycle (equivalent of duration)

    # mortality

    # fecundity

    
    

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