years = 2017:2024
site = "PEROLS" # MONTARNAUD do not have EVP and RH

n_immatureMosquitoes = 100

#number of larval habitats
nr_h_hr = [0.67, 0.33, 0] # rainfed, # irrigated # rainfed and irrigated

for y in years

    varParams = funVarParams(y, site, fixedParams);
    steps = varParams.durSim*fixedParams.stepsPerDay

    #need to write this way otherwise Julia doesn't like it
    model = initialize(; n_immatureMosquitoes = n_immatureMosquitoes, nr_h_hr = nr_h_hr,
    varParams = varParams) 
  
    @time adf, mdf = run!(model, steps; adata, mdata)

    global n_immatureMosquitoes = adf.sum_Ed[steps] # to fix

    amdf = DataFrame(t = 1:varParams.durSim,
        Ed = spdMean(adf.sum_Ed, stepsPerDay),
        E = spdMean(adf.sum_E, stepsPerDay),
        Eq = spdMean(adf.sum_Eq, stepsPerDay),
        L = spdMean(adf.sum_L, stepsPerDay),
        P = spdMean(adf.sum_P, stepsPerDay),
        A = spdMean(adf.sum_A, stepsPerDay),
        VR = spdMean(mdf.VR, stepsPerDay),
        VH = spdMean(mdf.VH, stepsPerDay),
        O = stepsPerDay*spdMean(mdf.O, stepsPerDay))

    CSV.write(string("sim/Sim_", site, "_", y, ".csv"), amdf)

    println(y)
    println(adf.sum_Ed[steps])
end

# run 2025 once

y = 2025

varParams = funVarParams(y, site, fixedParams);
steps = varParams.durSim*stepsPerDay

model = initialize(; n_immatureMosquitoes = n_immatureMosquitoes, nr_h_hr = nr_h_hr, varParams = varParams) 

@time adf, mdf = run!(model, steps; adata, mdata)

amdf = DataFrame(t = 1:varParams.durSim,
        Ed = spdMean(adf.sum_Ed, stepsPerDay),
        E = spdMean(adf.sum_E, stepsPerDay),
        Eq = spdMean(adf.sum_Eq, stepsPerDay),
        L = spdMean(adf.sum_L, stepsPerDay),
        P = spdMean(adf.sum_P, stepsPerDay),
        A = spdMean(adf.sum_A, stepsPerDay),
        VR = spdMean(mdf.VR, stepsPerDay),
        VH = spdMean(mdf.VH, stepsPerDay),
        O = stepsPerDay*spdMean(mdf.O, stepsPerDay))

p1 = Plots.plot(amdf.t/7, [amdf.Ed, amdf.E, amdf.Eq, amdf.L .+ amdf.P], label=["Ed" "E" "Eq" "L+P"]);
p2 = Plots.plot(amdf.t/7, [amdf.A], label="A");
p3 = Plots.plot(1:52, 7*spdMean(amdf.O, 7), label="Ovip.");
p4 = Plots.plot(amdf.t/7, [amdf.VR, amdf.VH], label=["Water Level R" "Water Level H"]);

ptot = plot(p1, p2, p3, p4, plot_title = string(uppercasefirst(lowercase(site)), " - ", y))

savefig(ptot, string("plots/Sim_", site, "_", y, ".png"))

CSV.write(string("sim/Sim_", site, "_", y, ".csv"), amdf)

model

