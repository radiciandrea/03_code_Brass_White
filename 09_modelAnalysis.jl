# run 2025 with paramscan

y = 2025

varParams = funVarParams(y, site, fixedParams);
steps = varParams.durSim*stepsPerDay


scannedParams = Dict(
    :n_immatureMosquitoes => collect(round.(Int, n_immatureMosquitoes .*(0.8:0.05:1.2))),
    :seed => collect(1:5),

    :n_adultMosquito => 0,
    :dims => (20,20),
    :dbm => 0,
    :varParams => varParams,
    :dt => fixedParams.dt,
    :wlmin => fixedParams.wlmin,
    :wlmax => fixedParams.wlmax,
    :deltaE => fixedParams.deltaE,
    :muEdt => 0.0,
    :muJtotdt => 0.0,
    :deltaJdt => 0.0,
    :deltaIdt => 0.0,
    :deltaGdt => 0.0,
    :eggs_to_larvae => 0,
    :deggs_to_larvae => 0,
    :laidE => 0,
    :laidED => 0,
    :laidEf => 0,
    :laidEDf => 0,
    :totJ => 0,
    :t => 1,
    :it => 1
    )

@time spadf, spmdf = paramscan(scannedParams, initialize; adata, mdata, n = steps)

spamdf = [spadf spmdf[:, [:O]]]

#https://blog.tidy-intelligence.com/posts/dplyr-vs-tidierdata/

sspmdf = @chain spmdf begin
    @group_by(time)
    @summarize(O_10 = quantile(O, 0.1),
    O_25 = quantile(O, 0.25),
    O_mean = mean(O),
    O_50 = quantile(O, 0.5),
    O_75 = quantile(O, 0.75),
    O_90 = quantile(O, 0.9))
    @arrange(time)
end

# and average over 7 * stepsPerDay
stepsPerWeek = 7*stepsPerDay

wsspmdf = DataFrame(week = 1:52,
O_10 = Vector{Float64}(undef, 52),
O_25 = Vector{Float64}(undef, 52),
O_mean = Vector{Float64}(undef, 52),
O_50 = Vector{Float64}(undef, 52),
O_75 = Vector{Float64}(undef, 52),
O_90 = Vector{Float64}(undef, 52))

for i in 2:7
    wsspmdf[:,i] = stepsPerWeek*spdMean(sspmdf[:,i], stepsPerWeek)
end

Plots.plot(wsspmdf.O_50,
ribbon = (wsspmdf.O_50 .- wsspmdf.O_25, wsspmdf.O_75 .- wsspmdf.O_50),
fillalpha = 0.3);

CSV.write(string("sim/Sim_", site, "_", y, "_sp.csv"), wsspmdf)

#=next

params = Dict(
    :deltaE => deltaE
)

adf, _ = paramscan(params, initialize; adata)

adf

#agents.abmvideo("ourmodel.mp4", model, agent_step!; frames = 10, framerate = 1)
# genrate an interactive video
video,  _ = abmexploration(model; adata, params)

video
=#