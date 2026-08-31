#dispatched function
function mosquito_step!(m::immatureMosquito, model)

    # pupae (to bring at the beginning!)
    if m.stage == 4 
              
        #aging and development
        m.age += model.deltaPdt
        if m.age >= 1
            for i in 1:m.abundance
                add_agent!(adultMosquito, model;
                sex = i > m.abundance/2 ? 0 : 1,
                wlength = wing_func(m.cumTemp/m.LSD, log(m.cumFood/m.LSD)), # since food functions are written as log
                goniotrophicIncrease = 0.0)
            end
            remove_agent!(m, model)   
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
        m.cumFood += model.alpha*model.dt
        m.cumTemp += model.tempH*model.dt
        m.LSD += model.dt
        m.age += model.deltaLdt

        if m.age >= 1
            m.stage = 4
        end

        # mortality (natural and competition)        
        dead_L_potential = m.abundance*(1-exp(-model.muLdt))

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
        eggs_to_larvae_potential = (1-model.hQ)*m.abundance
        if eggs_to_larvae_potential < 1 
            sampE = rand(model.rng)
            eggs_to_larvae = 1*(sampE < eggs_to_larvae_potential)
        else
            eggs_to_larvae = round(Int, eggs_to_larvae_potential)
        end

        m.abundance = m.abundance - eggs_to_larvae 
        model.dbm == 1 && println("created ", eggs_to_larvae, " juvenile/s from E")        
        model.eggs_to_larvae += eggs_to_larvae

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

    # normal eggs dynamics
    if m.stage == 1
        
        #aging and development (without h)
        m.age += model.deltaEdt
        
        if m.age > 1 # (m.age == 1) || (m.age == 1)
            eggs_to_larvae_potential = (1-model.Q)*m.abundance
            if eggs_to_larvae_potential < 1 
                sampE = rand(model.rng)
                eggs_to_larvae = 1*(sampE < eggs_to_larvae_potential)
            else
                eggs_to_larvae = round(Int, eggs_to_larvae_potential)
            end

            m.abundance = m.abundance - eggs_to_larvae 
            model.dbm == 1 && println("created ", eggs_to_larvae, " juvenile/s from E")        

            model.eggs_to_larvae += eggs_to_larvae

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
        deggs_to_larvae_potential = (1 - model.Q)*m.abundance*(1-exp(-model.hD[model.t]*model.dt))

        if deggs_to_larvae_potential < 1 
            sampE = rand(model.rng)
            deggs_to_larvae =  1*(sampE < deggs_to_larvae_potential)
        else
            deggs_to_larvae = round(Int, deggs_to_larvae_potential)
        end

        #going to quiescence
        deggs_to_qeggs_potential = model.Q*m.abundance*(1-exp(-model.hD[model.t]*model.dt))

        if(deggs_to_qeggs_potential < 1)
            sampE = rand(model.rng)
            deggs_to_qeggs =  1*(sampE < deggs_to_qeggs_potential)
        else
            deggs_to_qeggs = round(Int, deggs_to_qeggs_potential)
        end

        m.abundance = m.abundance - (deggs_to_larvae + deggs_to_qeggs)

        model.deggs_to_larvae += deggs_to_larvae
        model.deggs_to_qeggs += deggs_to_qeggs

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

                # non diapausing oviposition    
                newE_potential = 0.5*exp(2.35 + 0.69*m.wlength)*model.D[model.t]
                if newE_potential < 1
                    sampleA = rand(model.rng)
                    newE = 1*(sampleA < newE_potential)
                else
                    newE = round(Int, newE_potential)
                end

                #diapausing oviposiiton
                newED_potential = exp(2.35 + 0.69*m.wlength)*(1 - model.D[model.t]) # removed 0.5*
                if newED_potential < 1
                    sampleA = rand(model.rng)
                    newED = 1*(sampleA < newED_potential)
                else
                    newED = round(Int, newED_potential)
                end
                model.laidED += newED
                model.laidEDf += newED        

            else

                # non diapausing oviposition only  
                newE_potential = 0.5*exp(2.35 + 0.69*m.wlength)
                if newE_potential < 1
                    sampleA = rand(model.rng)
                    newE = 1*(sampleA < newE_potential)
                else
                    newE = round(Int, newE_potential)
                end
            end

            #we put this outside, since non-diapausing are anyway generated
            model.laidE += newE
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
