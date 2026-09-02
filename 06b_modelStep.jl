function  model_step!(model)

  # zero oviposition counter
    model.laidEf = 0
    model.laidEDf = 0

    # time
    model.it = max(1, abmtime(model))
    model.t = max(1, round(Int64, abmtime(model)*model.dt))
    model.dbm > 0 && println(model.t, " - (", model.it, ")")

    tasMax0 = model.tasMax[max(1, model.t-1)]
    tasMax1 = model.tasMax[model.t]
    tasMin1 = model.tasMin[model.t]
    tasMin2 = model.tasMin[min(max(1, model.t-1), length(model.t))]
    tSr1 = model.tasMin[model.t]
    tH1 = 24*model.dt*(abmtime(model) - model.dt*floor(abmtime(model)/model.dt))

    model.tempH = funTempH(tH1, tasMax0, tasMax1, tasMin1, tasMin2, tSr1)

    # eggs parameters

    # development
    model.deltaEdt = max(-0.0008256*model.tempH^2 + 0.0334072*model.tempH - 0.0557825, 0.01)*model.dt # egg temperature reaction norm (development)
    
    # mortality

    #tsmuE = -log(12.217/(6.115*sqrt(2*pi))*exp(-0.5*(model.tempH - 24.672)^2/6.115^2)) # throught stage egg mortality rate
    #model.muEdt = tsmuE*max(-0.0008256*model.tempH^2 + 0.0334072*model.tempH - 0.0557825, 0.01)*model.dt # egg mortality rate
    
    # Let's use the per day Metelmann mortality:
    model.muEdt =-log(0.955 * exp(-0.5*((model.tempH-18.8)/21.53)^6))*model.dt
    
    model.muDEdt = model.tempH > -12 ? 0.01*model.dt : 0.1*model.dt # diapausing egg mortality rate

    # Larval parameters: in agent_step

    # Pupae parameters (mortality into agetn_step)
    
    #development
    model.deltaPdt = -log(max(2.916*10^(-5)*model.tempH*(model.tempH - 10.08)*(47.68 - model.tempH)^(1/0.8317), 0.01))*model.dt

    # Adult parameters

    # goniotrophic cycle (equivalent of duration: here we transform it in rate
    tempHG = @. max(12, min(38.3, model.tempH))
    model.deltaGdt = max(0.000193 * tempHG * (tempHG - 10.25) * sqrt(38.32 - tempHG), 0.01)*model.dt

    # mortality & fecundity:
    # defined in agent-step     

    #generation of new large agents four times a day
    if mod(model.it,  div(fixedParams.stepsPerDay, fixedParams.freqUpdateLargeClasses)) == 0

      if sum(model.laidE) >0

        for i in findall(>(0), model.laidE)
          add_agent!(immatureMosquito, model;
                      abundance =model.laidE[i], stage = 1, age = 0.0, cumFood = 0.0, cumTemp = 0.0, LSD = 0.0, breedingSite = i)
                      # I assume they spent already 1/2 of the period in this class since previous update
                  model.dbm == 1 && println("created ", model.laidE[i], " egg(s)")       
                end
        model.laidE = [0, 0, 0]
      end

      # in the case if diapausing eggs, we do not create a new agent, we just increment the abundance of the existent (ID0)
      if sum(model.laidED) >0
        for i in ((findall(>(0), model.laidED)) .- 1)
          model[i].abundance += model.laidED[i+1]
        end

        model.dbm == 1 && println("created ", sum(model.laidED), " diapausing egg(s)")
        model.laidED = [0, 0, 0]
      end

      if sum(model.deggs_to_qeggs) > 0
        for i in findall(>(0), model.deggs_to_qeggs)
            add_agent!(immatureMosquito, model;
            abundance = model.deggs_to_qeggs[i], stage = 2, age = 0.0, cumFood = 0.0, cumTemp = 0.0, LSD = 0.0, breedingSite = i)
        end
        
        model.deggs_to_qeggs = [0, 0, 0]
      end

      if sum(model.eggs_to_larvae) > 0
        for i in findall(>(0), model.eggs_to_larvae)
          add_agent!(immatureMosquito, model;
          abundance = model.eggs_to_larvae[i], stage = 3, age = 0.0, cumFood = 0.0, cumTemp = 0.0, LSD = 0.0, breedingSite = i)
        end
        
        model.eggs_to_larvae = [0, 0, 0]
      end
    end

end