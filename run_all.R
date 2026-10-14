## run_all.R
## Runs the complete pipeline: the simulation (simulation.R), followed by the
## screening and performance measures (performance_calculation.R).
## Output: results/replications.rds, results/performance.rds,
##         results/screening.rds
## Runtime is about 55 minutes on an Apple M4 Pro with 24 GB of memory
## running macOS Sequoia 15.7.3.

cat("Running simulation ...\n")
source("simulation.R")

cat("Computing performance measures ...\n")
source("performance_calculation.R")

cat("Done. Results written to results/.\n")
