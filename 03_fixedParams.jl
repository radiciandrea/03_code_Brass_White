stepsPerDay = 48

fixedParams = (

# simluation -related
stepsPerDay = stepsPerDay, # need an integer
dt = 1/stepsPerDay, # 48 if each step is 30 minutes
freqUpdateLargeClasses = max(1, div(stepsPerDay, 12)), # frequency of the day at which eggs are laid and or/develop: ideally, 4 times a day

#parameters (Metelmann 2019)
CTTs = 11, #critical temperature over one week in spring (°C )
CPPs = 11.25, #critical photoperiod in spring
deltaE = 1/7.1, #normal egg development rate (1/day)

# advanced parameter for carrying capacity
alphaEvap = 0.9,
alphaDens = 0.001,
alphaRain = 0.00001,

#parameters for modified carrying capacity
lambda = 10^6, #capacity parameter (10^6 larvae/day/ha)
expH = 0.6,

epsRat = 0.2,
eps0 = 1.5,
epsVar = 0.05,
epsOpt = 8,
epsDens = 0.01,
epsFac = 0.01,

#parameters from Brass & White 2024
wlmin = 1.5,
wlmax = 4.0

)