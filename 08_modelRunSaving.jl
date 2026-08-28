years = 2017:2024
site = "MONTARNAUD"

n_immatureMosquitoes = 200

for y in years

    varParams = funVarParams(y, site, fixedParams);
    steps = varParams.durSim*fixedParams.stepsPerDay

    #need to write this way otherwise Julia doesn't like it
    model = initialize(; n_immatureMosquitoes = n_immatureMosquitoes,
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
        O = stepsPerDay*spdMean(mdf.O, stepsPerDay),
        V = stepsPerDay*spdMean(mdf.V, stepsPerDay))

    CSV.write(string("sim/Sim_", site, "_", y, ".csv"), amdf)

    println(y)
    println(adf.sum_Ed[steps])
end

# run 2025 once

y = 2025

varParams = funVarParams(y, site, fixedParams);
steps = varParams.durSim*stepsPerDay

model = initialize(; n_immatureMosquitoes = n_immatureMosquitoes) 

@time adf, mdf = run!(model, steps; adata, mdata)

amdf = DataFrame(t = 1:varParams.durSim,
        Ed = spdMean(adf.sum_Ed, stepsPerDay),
        E = spdMean(adf.sum_E, stepsPerDay),
        Eq = spdMean(adf.sum_Eq, stepsPerDay),
        L = spdMean(adf.sum_L, stepsPerDay),
        P = spdMean(adf.sum_P, stepsPerDay),
        A = spdMean(adf.sum_A, stepsPerDay),
        O = stepsPerDay*spdMean(mdf.O, stepsPerDay),
        V = spdMean(mdf.V, stepsPerDay))

p1 = Plots.plot(amdf.t/7, [amdf.Ed, amdf.E, amdf.Eq, amdf.L .+ amdf.P], label=["Ed" "E" "Eq" "L+P"]);
p2 = Plots.plot(amdf.t/7, [amdf.A], label="A");
p3 = Plots.plot(1:52, 7*spdMean(amdf.O, 7), label="Ovip.");
Plots.scatter!(1:52, 7*spdMean(amdf.O, 7), label="");
p4 = Plots.plot(1:52, spdMean(amdf.V, 7), label="Water Level");

ptot = plot(p1, p2, p3, p4, plot_title = string(uppercasefirst(lowercase(site)), " - ", y))

savefig(ptot, string("plots/Sim_", site, "_", y, ".png"))

CSV.write(string("sim/Sim_", site, "_", y, ".csv"), amdf)

model

