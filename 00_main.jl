# try to build a agent based model from Brass White 2024

#create Manifest, Project and open it
# add Pkg
using Pkg
Pkg.activate(".")

# create repo on github

# libraries
using Agents, DataFrames, Random, CSV, Plots, SunCalc, Statistics, Dates

#Including functions
include("01_StatFunctions.jl")

#Defining Agents
include("02_agentsDefinition.jl")

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
