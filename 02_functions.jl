# statit functions and GAMM 

function spdMean(x::Vector{}, stepsPerDay::Int = 48)
    #::Vector
    lmx = div((length(x)-1),stepsPerDay) 
    mx = zeros(Float64, lmx)

    for i in 1:lmx
        mx[i] = mean(x[1 .+ ((1+stepsPerDay*(i-1)) : stepsPerDay*i)])
    end
    
    return(mx)
    
end

# adapted from https://github.com/DomBrass/Aedes_DDE

L_Dur  = CSV.read(raw"Data/GAMM/LDgam.csv", header=true, DataFrame)

D_Vals = unique(L_Dur[:,2])
T_Vals = unique(L_Dur[:,3])
L_D       = transpose(reshape(L_Dur[:,4], (400,400)));
nodes = (T_Vals,D_Vals);
sGird = interpolate(nodes,L_D, Gridded(Linear()));
tau_L_spl = extrapolate(sGird,Flat());

#Larval development rate

function g_L(TEMP,DENS)

      out = 1 ./tau_L_spl(TEMP,DENS);
      if TEMP < 12
        out = 1 ./ tau_L_spl(12, DENS)
      end

      return(out)
end;

#Larval mortality

L_Surv = CSV.read(raw"Data/GAMM/Fin_LSurv.csv", header=true, DataFrame)

D_Vals = unique(L_Surv[:,3])
T_Vals = unique(L_Surv[:,2])
L_S    = (reshape(L_Surv[:,4], (400,400)));
nodes = (T_Vals,D_Vals);
sGird = interpolate(nodes,L_S, Gridded(Linear()));
surv_L = extrapolate(sGird,Flat());

# larval mortality rate

function mu_L(Temp,Dens)

    out = surv_L(Temp,Dens)

    #=

    if out < 0.01
      out = 0.01
    end
    if out > 0.99
      out = 0.99
    end
    =#

    out = -log(out)

    return(out)
end


# adult reaction norms

# wing_lenght
WL     = CSV.read(raw"Data/GAMM/WL_re.csv", header=true, DataFrame) 

T_Vals = unique(WL[:,3])
D_Vals = unique(WL[:,2])

Wing_W       = transpose(reshape(WL[:,4], (400,400)));
nodes = (T_Vals,D_Vals);
sGird = interpolate(nodes,Wing_W,Gridded(Linear()));
wing_spl     = extrapolate(sGird,Flat());

function wing_func(Temp,Dens)
  ifelse( Temp > 15, wing_spl(Temp,Dens),  wing_spl(15,Dens))
end

# adult mortality
A_Long = CSV.read(raw"Data/GAMM/AMgam.csv", header=true, DataFrame) 

#Defines the mortality of adults based on wing length and adult temperature

T_Vals = unique(A_Long[:,2])
W_Vals = unique(A_Long[:,3])

Long    = transpose(reshape(A_Long[:,4], (400,400)));
nodes = (W_Vals,T_Vals);
sGird = interpolate(nodes,Long,Gridded(Linear()));
del_spl = extrapolate(sGird,Flat());

function mu_A(Temp, Wing_Vals)

  del = del_spl.(Wing_Vals,Temp)
  del =ifelse.(del .< 0.00001,0.00001,del)
  out = -log(0.5) ./ del
  out = ifelse.(out .> 0.5,  0.5, out)

  return(out)
end




