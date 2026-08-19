function mMean(x::Vector{Float64}, backward::Int = 6, forward::Int = 0)
    #::Vector
    lx = length(x)
    mx = zeros(Float64, lx)

    for i in 1:lx
        mx[i] = mean(x[max(i-backward, 1) : min(i+forward, lx)])
    end
    
    return(mx)
    
end

function spdMean(x::Vector{}, stepsPerDay::Int = 48)
    #::Vector
    lmx = div((length(x)-1),stepsPerDay) 
    mx = zeros(Float64, lmx)

    for i in 1:lmx
        mx[i] = mean(x[1 .+ ((1+stepsPerDay*(i-1)) : stepsPerDay*i)])
    end
    
    return(mx)
    
end

function funKR(prec, daySim, alphaEvap, alphaDens)
    lKRt = length(daySim)
    KRt = zeros(Float64, lKRt)

    for t in daySim
        KRx = zeros(Float64, t)

        for x in 1:t
            KRx[x] = alphaEvap^(t-x) * alphaDens * prec[x]
        end

        KRt[t] = (1 - alphaEvap)*sum(KRx)/(1 - alphaEvap^t)
    end

    return(KRt)
end

function funTempH(tH, tasMax0, tasMax, tasMin, tasMin2, tSr)

    if tH<tSr
    tempH = (tasMax0+tasMin)/2 + (tasMax0-tasMin)/2*cos(pi*(tH+10)/(10+tSr))
    elseif (tH>=tSr) & (tH<14)
    tempH = (tasMax+tasMin)/2 - (tasMax-tasMin)/2*cos(pi*(tH-tSr)/(14-tSr))
    else 
    tempH = (tasMax+tasMin2)/2 + (tasMax-tasMin2)/2*cos(pi*(tH-14)/(10+tSr))
    end

    return(tempH)
end