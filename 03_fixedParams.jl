stepsPerDay = 48

fixedParams = (

# simluation -related
stepsPerDay = stepsPerDay, # need an integer
dt = 1/stepsPerDay, # 48 if each step is 30 minutes
freqUpdateLargeClasses = max(1, div(stepsPerDay, 12)), # frequency of the day at which eggs are laid and or/develop: ideally, 4 times a day

#parameters from Brass & White 2024

#Environmental & Hydrological
mu = 130, #Surface area of developmental habitat (cm2)
Vmax = 500, # Volume of developmental habitat (ml)
fd = 80, #Detritus in larval habitat

# Adults
wlmin = 1.5,
wlmax = 4.0

)