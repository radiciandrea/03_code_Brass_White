# try to build a agent based model from Brass White 2024

#create Manifest, Project and open it
# add Pkg
using Pkg
Pkg.activate(".")

# create repo on github

# libraries
#add 
using Agents, DataFrames, Random, Plots, SunCalc, Statistics, Dates, Interpolations, TidierData

#Defining Agents
include("01_agentsDefinition.jl")

#Including GAMM functions from Brass_White
include("02_functions.jl")

#Including fixed parameters 
include("03_fixedParams.jl")

#Elaborate variable annual/daily parameters
include("04_varParams.jl")

#Defining Initialize function
include("05_Initialize.jl")

#Defining agentStep function
include("06a_agentsSteps.jl")

#Defining modelStep function
include("06b_modelStep.jl")

#Including plotting and data collection
include("07_plotDataSettings.jl")
