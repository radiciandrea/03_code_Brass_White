# run 2025 with paramscan

y = 2025

varParams = funVarParams(y, site, fixedParams);
steps = varParams.durSim*stepsPerDay

scannedParams = Dict(
    :n_immatureMosquitoes => collect(round.(Int, n_immatureMosquitoes .*(0.95, 1, 1.05))), #collect(round.(Int, n_immatureMosquitoes .*(0.9:0.05:1.1))),
    :seed => collect(1:5), #collect(1:5)

    :n_adultMosquito => 0,
    :dims => (20,20),

    :varParams => varParams,
    #:fixedParams => fixedParams,

    :dbm => 0,
    :tempH => 0.0,
    :GPP => 0.0,
    :alpha => 0.0,
    :deltaEdt => 0.0,
    :muEdt => 0.0,
    :muDEdt => 0.0,
    :Q => 0.0,
    :hQ => 0.0,
    :deltaLdt => 0.0,
    :muLdt => 0.0,

    :deltaPdt => 0.0,
    :muPdt => 0.0,
    :deltaGdt=> 0.0,           
    :t => 1,
    :it => 1,
    :tempH => 0.0,
    :eggs_to_larvae => 0,
    :deggs_to_larvae => 0,
    :deggs_to_qeggs => 0,
    :eggs_to_qeggs => 0,
    :qeggs_to_larvae => 0,
    :laidE => 0,
    :laidED => 0,
    :laidEf => 0,
    :laidEDf => 0)

    #=
:V => (fixedParams.sigma*fixedParams.lambda/2), # Brass/White assumed it is completely full at the beginning
:Vmax => fixedParams.sigma*fixedParams.lambda,
:sigma => fixedParams.sigma,
:wlmax => fixedParams.wlmin,
:wlmin => fixedParams.wlmax,
:dt => fixedParams.dt,
:fd => fixedParams.fd,
:K => fixedParams.K,   
:muDFdt => (fixedParams.muDF*fixedParams.dt),
:muDDdt => (fixedParams.muDD*fixedParams.dt)
=#
    
@time spadf, spmdf = paramscan(scannedParams, initialize; adata, mdata, n = steps)

# Pass to R
CSV.write(string("sim/spadf_", site, "_", y, "_sp.csv"), spadf)
CSV.write(string("sim/spmdf_", site, "_", y, "_sp.csv"), spmdf)

spamdf = [spadf spmdf[:, [:O]]]

#https://blog.tidy-intelligence.com/posts/dplyr-vs-tidierdata/

sspmdf = @chain spmdf begin
    @mutate(idRep = string(seed, "_", "n_immatureMosquitoes"))
    @group_by(idRep)
    @mutate(O1 = stepsPerDay*spdMean(O, stepsPerDay))
    @ungroup
end

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
fillalpha = 0.3)

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