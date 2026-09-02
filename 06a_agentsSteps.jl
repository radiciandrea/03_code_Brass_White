#dispatched function
function mosquito_step!(m::immatureMosquito, model)

    # pupae (to bring at the beginning!)
    if m.stage == 4 

        # mortality (CORRECT CONDITION ON RAIN)
        if model[m.breedingSite+2].V > 0
          if (model[m.breedingSite+2].V < model[m.breedingSite+2].Vmax) && (model.rho[model.t]*model.sigma < 0.5 * model[m.breedingSite+2].Vmax)
            # throught stage mortality
            tSmuP = -log(max(-0.0070628*model.tempH^2 + 0.3331028*model.tempH - 2.9878761, 0.01))
            #instantaneous mortality rate
            model.muPdt = -log(max(2.916*10^(-5)*model.tempH*(model.tempH - 10.08)*(47.68 - model.tempH)^(1/0.8317), 0.01))*tSmuP*model.dt
          else
            model.muPdt
          end
        else
          model.muPdt
        end
              
        #aging and development
        m.age += model.deltaPdt
        if m.age >= 1
            for i in 1:m.abundance
                add_agent!(adultMosquito, model;
                sex = i > m.abundance/2 ? 0 : 1,
                wlength = wing_func(m.cumTemp/m.LSD, log(m.cumFood/m.LSD)), # since food functions are written as log
                goniotrophicIncrease = 0.0)
            end
            #remove_agent!(m, model)  " this create conflict with the next
            m.abundance = 0
        end

        # mortality (natural and competition)        
        dead_P_potential = m.abundance*(1-exp(-model.muPdt))

        if dead_P_potential < 1 
            sampP = rand(model.rng)
            dead_P = 1*(sampP < dead_P_potential)
        else
            dead_P = round(Int, dead_P_potential)
        end

        m.abundance = m.abundance - dead_P

        if m.abundance == 0
            remove_agent!(m, model)         
        end 
        
    end

    # larvae
    if m.stage == 3 
               
        #eating, ageing, development
        m.cumFood += model[m.breedingSite+2].alpha*model.dt
        m.cumTemp += model.tempH*model.dt
        m.LSD += model.dt
        m.age += model[m.breedingSite+2].deltaLdt

        if m.age >= 1
            m.stage = 4
        end

        # mortality (natural and competition)        
        dead_L_potential = m.abundance*(1-exp(-model[m.breedingSite+2].muLdt))

        if dead_L_potential < 1
            sampL = rand(model.rng)
            dead_L = 1*(sampL < dead_L_potential)
        else
            dead_L = round(Int, dead_L_potential)
        end

        m.abundance = m.abundance - dead_L

        if m.abundance == 0
            remove_agent!(m, model)         
        end 
        
    end

    # quiescent eggs 
    if m.stage == 2

        #no development      
        eggs_to_larvae_potential = (1-model[m.breedingSite+2].hQ)*m.abundance
        if eggs_to_larvae_potential < 1 
            sampE = rand(model.rng)
            eggs_to_larvae = 1*(sampE < eggs_to_larvae_potential)
        else
            eggs_to_larvae = round(Int, eggs_to_larvae_potential)
        end

        m.abundance = m.abundance - eggs_to_larvae 
        model.dbm == 1 && println("created ", eggs_to_larvae, " juvenile/s from E")        
        model.eggs_to_larvae[m.breedingSite] += eggs_to_larvae

        # mortality (here fixed, and time step is needed)
        dead_eggs_potential = m.abundance*(1-exp(-model.muEdt))
        if dead_eggs_potential < 1
            sampE = rand(model.rng)
            dead_eggs = 1*(sampE < dead_eggs_potential)
        else
            dead_eggs = round(Int, dead_eggs_potential)
        end

        m.abundance = m.abundance - dead_eggs
        
        if m.abundance == 0
            remove_agent!(m, model)         
        end 
        
    end

    # active eggs dynamics
    if m.stage == 1
        
        #aging and development (without h)
        m.age += model.deltaEdt
        
        if m.age > 1 # (m.age == 1) || (m.age == 1)
            eggs_to_larvae_potential = (1-model[m.breedingSite+2].Q)*m.abundance
            if eggs_to_larvae_potential < 1 
                sampE = rand(model.rng)
                eggs_to_larvae = 1*(sampE < eggs_to_larvae_potential)
            else
                eggs_to_larvae = round(Int, eggs_to_larvae_potential)
            end

            m.abundance = m.abundance - eggs_to_larvae 
            model.dbm == 1 && println("created ", eggs_to_larvae, " juvenile/s from E")        

            model.eggs_to_larvae[m.breedingSite] += eggs_to_larvae

            # the remaining are quiescent (or they were also before)
            m.stage = 2
        end

        # mortality (here fixed, and time step is needed)
        dead_eggs_potential = m.abundance*(1-exp(-model.muEdt))
        if dead_eggs_potential < 1
            sampE = rand(model.rng)
            dead_eggs = 1*(sampE < dead_eggs_potential)
        else
            dead_eggs = round(Int, dead_eggs_potential)
        end
    
        m.abundance = m.abundance - dead_eggs

        if m.abundance == 0
            remove_agent!(m, model)         
        end 
    end

    # diapausing eggs dynamics
    if m.stage == 0

        # diapausing eggs here are just one agent (id = 0) of variable abundance.
        # no ED agents are created or removed

        #diapausing eggs are supposed to be already developed
        # going to larvae
        deggs_to_larvae_potential = (1 - model[m.breedingSite+2].Q)*m.abundance*(1-exp(-model.hD[model.t]*model.dt))

        if deggs_to_larvae_potential < 1 
            sampE = rand(model.rng)
            deggs_to_larvae =  1*(sampE < deggs_to_larvae_potential)
        else
            deggs_to_larvae = round(Int, deggs_to_larvae_potential)
        end

        #going to quiescence
        deggs_to_qeggs_potential = model[m.breedingSite+2].Q*m.abundance*(1-exp(-model.hD[model.t]*model.dt))

        if(deggs_to_qeggs_potential < 1)
            sampE = rand(model.rng)
            deggs_to_qeggs =  1*(sampE < deggs_to_qeggs_potential)
        else
            deggs_to_qeggs = round(Int, deggs_to_qeggs_potential)
        end

        m.abundance = m.abundance - (deggs_to_larvae + deggs_to_qeggs)

        model.eggs_to_larvae[m.breedingSite] += deggs_to_larvae
        model.deggs_to_qeggs[m.breedingSite] += deggs_to_qeggs

        #mortality
        dead_deggs_potential = m.abundance*(1-exp(-model.muDEdt))
        if dead_deggs_potential < 1 
            sampE = rand(model.rng)
            dead_deggs = 1*(sampE < dead_deggs_potential)
        else
            dead_deggs = round(Int, dead_deggs_potential)
        end
        
        m.abundance = m.abundance - dead_deggs
    end    
end

function mosquito_step!(m::adultMosquito, model)

    # if female
    if m.sex == 0
        #goniotriphic increase
        m.goniotrophicIncrease +=  model.deltaGdt

        #reproduction
        if m.goniotrophicIncrease >= 1
            if model.D[model.t] < 1

                # non diapausing oviposition - # removed 0.5*    
                newE_potential = exp(2.35 + 0.69*m.wlength)*model.D[model.t]
                if newE_potential < 1
                    sampleA = rand(model.rng)
                    newE = 1*(sampleA < newE_potential)
                else
                    newE = round(Int, newE_potential)
                end

                #diapausing oviposiiton
                newED_potential = exp(2.35 + 0.69*m.wlength)*(1 - model.D[model.t]) 
                if newED_potential < 1
                    sampleA = rand(model.rng)
                    newED = 1*(sampleA < newED_potential)
                else
                    newED = round(Int, newED_potential)
                end

                # oviposit in random breedingSite
                model.laidED[findfirst(>(rand(model.rng)[1]), cumsum(model.nr_h_hr)./sum(model.nr_h_hr))] += newED
                model.laidEDf += newED        

            else

                # non diapausing oviposition only  
                newE_potential = exp(2.35 + 0.69*m.wlength)
                if newE_potential < 1
                    sampleA = rand(model.rng)
                    newE = 1*(sampleA < newE_potential)
                else
                    newE = round(Int, newE_potential)
                end
            end

            #we put this outside, since non-diapausing are anyway generated
            model.laidE[findfirst(>(rand(model.rng)[1]), cumsum(model.nr_h_hr)./sum(model.nr_h_hr))] += newE
            model.laidEf += newE

            m.goniotrophicIncrease = 0
        end 
    end  
        
    # random mortality
    
    if rand(model.rng) > exp(-mu_A(model.tempH, m.wlength)*model.dt)
        model.dbm == 1 && println("dead id: ", m.id)
        remove_agent!(m, model)
    end
end


function mosquito_step!(m::breedingSite, model)
    
    Vprec = m.V

    if (m.type == 1) || (m.type == 3)
        #hydrological functioning 
        m.V= max(0, min(Vprec + model.sigma*(model.rho[model.t] - model.eta[model.t])*model.dt, m.Vmax)) 

    end

    if (m.type == 2) || (m.type == 3)
        #Irrigation module
        m.V = (Vprec < m.Vmax*0.1) ? 0.5*m.Vmax : max(0, Vprec - (m.type == 2)*model.sigma*model.eta[model.t]*model.dt)
    end

    #Primary production of the larval habitat (corrected from github)
    #model.GPP = (10^-6 * log10(0.45 + 0.095*model.tempH)*m.V + model.fd)*model.dt
    GPP = (10^(0.45 + 0.095*model.tempH - 6)*m.V + model.fd)*model.dt

    #total number of larvae (0.1 to plot also when infinite)
    totL = max(sum(l.abundance for l in allagents(model) if l isa immatureMosquito && l.stage == 3 && l.breedingSite == m.type; init = 0), 0.1)

    # Food available per larvae
    m.alpha = GPP/totL

    # development (from GLM)
    m.deltaLdt = g_L(model.tempH, log(m.alpha))*model.dt # since food functions are written as log

    #crowding term mortality (after mail exchange with Dom)
    cTmuL = max(0, (exp(-exp(1000*(1-totL/3.0)/m.V)) - exp(-1))/(1 - exp(-1)))

    # mortality (from GLM) 
    if m.V > 0
      if (m.V < m.Vmax) && (model.rho[model.t]*model.sigma < 0.5 * m.Vmax)
        # through-stage mortality (from GLM) 
        tSmuL = mu_L(model.tempH, log(m.alpha)) # since food functions are written as log
        # Instantanous mortality
        m.muLdt = min(tSmuL*g_L(model.tempH, log(m.alpha)) + cTmuL, 1)*model.dt
      else
        m.muLdt = model.muDFdt
      end
    else
      m.muLdt = model.muDDdt
    end

    # quiescence entrancy
    m.Q = m.V < Vprec ? 1 - m.V/m.Vmax : 0

    #Hatching out of quiescent class
    m.hQ = m.V > Vprec ? m.V/m.Vmax : 0

end