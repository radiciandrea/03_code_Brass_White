#dispatched function
function mosquito_step!(m::immatureMosquito, model)

    #update the stage
    m.stage = m.stageNext

    # eggs dynamics
    if m.stage == 0

        # diapausing eggs here are just one agent (id = 0) of variable abundance.
        # no ED agents are created or removed

        #diapausing eggs are supposed to be already developed:
        # they just hatch depending on sigma and h
        #divided in 2 to work also when dt is low
        deggs_to_larvae_potential = m.abundance*(1-exp(-model.sigma[model.t]*model.h[model.t]*model.dt))
        if(deggs_to_larvae_potential < 1)
            sampE = rand(model.rng)
            deggs_to_larvae = 1*(sampE < deggs_to_larvae_potential)
            viable_deggs_to_larvae =  1*(sampE < model.gamma*deggs_to_larvae_potential)
        else
            deggs_to_larvae = round(Int, deggs_to_larvae_potential)
            viable_deggs_to_larvae = round(Int, model.gamma*deggs_to_larvae_potential)
        end
            m.abundance = m.abundance - deggs_to_larvae

        model.deggs_to_larvae += viable_deggs_to_larvae
    end

    # eggs dynamics
    if m.stage == 1
        # mortality (here fixed, and time step is needed)
        dead_eggs_potential = m.abundance*(1-exp(-model.muEdt))
        if(dead_eggs_potential < 1)
            sampE = rand(model.rng)
            dead_eggs = 1*(sampE < dead_eggs_potential)
        else
            dead_eggs = round(Int, dead_eggs_potential)
        end

        m.abundance = m.abundance - dead_eggs

        #aging and development (without h)
        m.age += model.deltaEdt
        
        if m.age >= 1
            eggs_to_larvae_potential = model.h[model.t]*m.abundance
            if(eggs_to_larvae_potential < 1)
                sampE = rand(model.rng)
                eggs_to_larvae = 1*(sampE < eggs_to_larvae_potential)
            else
                eggs_to_larvae = round(Int, eggs_to_larvae_potential)
            end

            m.abundance = m.abundance - eggs_to_larvae 
            model.dbm == 1 && println("created ", eggs_to_larvae, " juvenile/s from E")        

            model.eggs_to_larvae += eggs_to_larvae

            if m.abundance == 0
                remove_agent!(m, model)         
            end 
        end
    end

    if m.stage == 2
        # mortality (natural and competition)        
        dead_J_potential = m.abundance*(1-exp(-model.muJtotdt))

        if(dead_J_potential < 1)
            sampJ = rand(model.rng)
            dead_J = 1*(sampJ < dead_J_potential)
        else
            dead_J = round(Int, dead_J_potential)
        end

        m.abundance = m.abundance - dead_J
        
        #aging and development

        m.age += model.deltaJdt
        if m.age >= 1
            for i in 1:m.abundance
                add_agent!(adultMosquito, model;
                stage = 0, age = 0, sex = i > m.abundance/2 ? 0 : 1,
                wlength = model.wlmin + (model.wlmax - model.wlmin)*rand(model.rng),
                goniotrophicIncrease = 0.0)
            end
            remove_agent!(m, model)   
        end
        
    end
    
end

function mosquito_step!(m::adultMosquito, model)

    # random mortality
    if rand(model.rng) > exp(-model.muAdt[model.t])
        model.dbm == 1 && println("dead id: ", m.id)
        remove_agent!(m, model)
    end

    if m.stage == 0
        #ageing
        m.age += model.deltaIdt

        #development
        if m.age >= 1
            m.stage = 1
            m.age = 0
        end
    end

    # reproduction
    
    if m.stage == 1 && m.sex == 0

        #goniotriphic increase
        m.goniotrophicIncrease +=  model.deltaGdt

        if m.goniotrophicIncrease >= 1
            if model.omega[model.t] > 0
                # non diapausing oviposition    
                newE_potential = 0.5*exp(2.35 + 0.69*m.wlength)*(1 - model.omega[model.t])
                if newE_potential < 1
                    sampleA = rand(model.rng)
                    newE = 1*(sampleA < newE_potential)
                else
                    newE = round(Int, newE_potential)
                end

                #diapausing oviposiiton
                newED_potential = 0.5*exp(2.35 + 0.69*m.wlength)*model.omega[model.t]
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
                newE_potential = 0.5*exp(2.35 + 0.69*m.wlength)*(1 - model.omega[model.t])
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
end
