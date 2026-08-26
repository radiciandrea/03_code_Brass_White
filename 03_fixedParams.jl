stepsPerDay = 48

fixedParams = (

# simluation -related
stepsPerDay = stepsPerDay, # need an integer
dt = 1/stepsPerDay, # 48 if each step is 30 minutes
freqUpdateLargeClasses = max(1, div(stepsPerDay, 12)), # frequency of the day at which eggs are laid and or/develop: ideally, 4 times a day

#parameters from Brass & White 2024

#Environmental & Hydrological
sigma = 130, #Surface area of developmental habitat (cm2)
Vmax = 500, # Volume of developmental habitat (ml)
fd = 80, #Detritus in larval habitat
K = 80, #Number of larval habitats (TO CHANGE)


# Larval and Juvenile
muDD = 0.99, #Mortality rate of juveniles when the habitat dries out (day−1)
muDF = 0.2, # Mortality rate of juveniles during overspill (day−1)

# Adults
wlmin = 1.5,
wlmax = 4.0

)