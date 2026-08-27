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

    model.tempH = funTempH(tH1, tasMax0, tasMax1, tasMin1, tasMin2, tSr1)

    #hydrological functioning (CORRECT UNIT OF MEASURES)
    Vprec = model.V
    model.V = max(0, min(Vprec + model.sigma*(model.rho[model.t] - model.eta[model.t])*model.dt, model.Vmax)) 

    # eggs parameters

    # development
    model.deltaEdt = max(-0.0008256*model.tempH^2 + 0.0334072*model.tempH - 0.0557825, 0.01)*model.dt # egg temperature reaction norm (development)
    
    # mortality
    model.muEdt = -log(12.217/(6.115*sqrt(2*pi))*exp(-0.5*(model.tempH - 24.672)^2/6.115^2))*model.dt # egg mortality rate
    model.muDEdt = model.tempH > -12 ? 0.01*model.dt : 0.1*model.dt # diapausing egg mortality rate

    # quiescence entrancy
    model.Q = model.V < Vprec ? 1 - model.V/model.Vmax : 0

    #Hatching out of quiescent class
    model.hQ = model.V > Vprec ? model.V/model.Vmax : 0

    #larval parameters

    #Primary production of the larval habitat
    model.NPP = (10^-6 * log10(0.45 + 0.095*model.tempH)*model.V + model.fd)*model.dt

    #total number of larvae
    L = sum(l.abundance for l in allagents(model) if l isa immatureMosquito && l.stage == 3; init = 0)

    # Food available per larvae
    model.alpha = model.NPP/L

    # development (from GLM)
    model.deltaLdt = g_L(model.tempH, model.alpha)*model.dt

    # mortality (from GLM)
    if model.V > 0
      if (model.V < model.Vmax) && (model.rho[model.t]*model.sigma < 0.5 * model.Vmax)
        model.muLdt = mu_L(model.tempH, model.alpha)*model.dt
      else
         model.muLdt = model.muDFdt
      end
    else
      model.muLdt = model.muDDdt
    end

    # Pupae parameters
    
    #development
    model.deltaPdt = -log(max(2.916*10^(-5)*model.tempH*(model.tempH - 10.08)*(47.68 - model.tempH)^(1/0.8317), 0.01))*model.dt

    # mortality 
    if model.V > 0
      if (model.V < model.Vmax) && (model.rho[model.t]*model.sigma < 0.5 * model.Vmax)
        model.muPdt = -log(max(-0.0070628*model.tempH^2 + 0.3331028*model.tempH - 2.9878761, 0.01))*model.dt
      else
         model.muPdt = model.muDDdt
      end
    else
      model.muPdt = model.muDFdt
    end

    # Adult parameters

    # size (wing lenght)

    # goniotrophic cycle (equivalent of duration: here we transform it in rate
    tempHG = @. max(12, min(38.3, model.tempH))
    model.deltaGdt = max(0.000193 * tempHG * (tempHG - 10.25) * sqrt(38.32 - tempHG), 0.01)*model.dt

    # mortality & fecundity:
    # defined per individual      

    #generation of new large agents four times a day
    if mod(model.it,  div(fixedParams.stepsPerDay, fixedParams.freqUpdateLargeClasses)) == 0

      if model.laidEf >0
        add_agent!(immatureMosquito, model;
                    abundance =model.laidEf, stage = 1, age = 0, cumFood = 0, cumTemp = 0, LSD = 0)
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
        abundance = model.deggs_to_larvae, stage = 3, age = 0, cumFood = 0, cumTemp = 0, LSD = 0)
        model.deggs_to_larvae = 0
      end

      if model.deggs_to_qeggs > 0
        add_agent!(immatureMosquito, model;
        abundance = model.deggs_to_qeggs, stage = 2, age = 0, cumFood = 0, cumTemp = 0, LSD = 0)
        model.deggs_to_qeggs = 0
      end

      if model.eggs_to_larvae > 0
        add_agent!(immatureMosquito, model;
        abundance = model.eggs_to_larvae, stage = 3, age = 0, cumFood = 0, cumTemp = 0, LSD = 0)
        model.eggs_to_larvae = 0
      end

      if model.eggs_to_qeggs > 0
        add_agent!(immatureMosquito, model;
        abundance = model.eggs_to_qeggs, stage = 2, age = 0, cumFood = 0, cumTemp = 0, LSD = 0)
        model.eggs_to_qeggs = 0
      end

    end

end