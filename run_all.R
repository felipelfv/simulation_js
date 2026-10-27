# run_all.R
# runs the complete pipeline: the simulation (simulation.R), followed by the
# screening and performance measures (performance_calculation.R).

# output: results/replications.rds, results/performance.rds, 
# results/screening.rds

source("simulation.R")
source("performance_calculation.R")

