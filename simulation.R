## simulation.R
## Monte Carlo simulation for "Model-Implied Instrumental-Variable and
## James-Stein Estimation of Structural Equation Models".
## Generates the data and fits the four estimators in every replication.
## Output: results/replications.rds, one row per replication, estimator, and
## estimand (n, rel, replication, estimator, parameter, true, estimate, se,
## ci_lower, ci_upper). Runtime is about 55 minutes on an Apple M4 Pro with
## 24 GB of memory running macOS Sequoia 15.7.3.

library(lavaan)
set.seed(1234)

## population model
lam <- c(1, 0.8, 1.2, 1.0, 1, 0.9, 1.1, 1.0, 1, 0.9, 1.1, 1.0)
var_eta <- rep(1, 12)
pop_model <- function(rel) {
  theta <- lam^2 * var_eta * (1 - rel) / rel
  paste0('
  eta1 =~ 1*y1 + 0.8*y2 + 1.2*y3 + 1.0*y4
  eta2 =~ 1*y5 + 0.9*y6 + 1.1*y7 + 1.0*y8
  eta3 =~ 1*y9 + 0.9*y10 + 1.1*y11 + 1.0*y12
  eta2 ~ 0.6*eta1
  eta3 ~ 0.3*eta1 + 0.5*eta2
  eta1 ~~ 1*eta1; eta2 ~~ 0.64*eta2; eta3 ~~ 0.48*eta3
  eta1 ~ 1*1; eta2 ~ 0.5*1; eta3 ~ 0.5*1
  y2 ~ 0.2*1; y3 ~ 0.2*1; y4 ~ 0.2*1; y6 ~ 0.2*1; y7 ~ 0.2*1; y8 ~ 0.2*1
  y10 ~ 0.2*1; y11 ~ 0.2*1; y12 ~ 0.2*1
  ', paste0("y", 1:12, " ~~ ", round(theta, 4), "*y", 1:12, collapse = "; "))
}

## analysis model
mod <- '
  eta1 =~ y1 + y2 + y3 + y4
  eta2 =~ y5 + y6 + y7 + y8
  eta3 =~ y9 + y10 + y11 + y12
  eta2 ~ eta1
  eta3 ~ eta1 + eta2
'

## design
ns <- c(100, 200, 300, 400, 500, 600); rels <- c(0.6, 0.8); R <- 1500
cond <- expand.grid(n = ns, rel = rels)
est <- c("JS", "JSA", "IV", "ML")

## one replication: generate a data set and fit it with every estimator
one <- function(n, rel) {
  pop <- pop_model(rel)
  pt <- lavaanify(pop)
  true <- setNames(pt$ustart, paste0(pt$lhs, pt$op, pt$rhs))
  d <- simulateData(pop, sample.nobs = n)
  do.call(rbind, lapply(est, function(e) {
    fit <- try(sem(mod, data = d, estimator = e, meanstructure = TRUE),
               silent = TRUE)
    if (inherits(fit, "try-error") || !lavInspect(fit, "converged"))
      return(NULL)
    pe <- parameterEstimates(fit, remove.nonfree = TRUE)
    pe <- pe[pe$op != "~1", ]
    par <- paste0(pe$lhs, pe$op, pe$rhs)
    data.frame(n = n, rel = rel, estimator = e, par = par, true = true[par],
               est = pe$est, se = pe$se,
               ci.lower = pe$ci.lower, ci.upper = pe$ci.upper)
  }))
}

## run all conditions
res <- do.call(rbind, lapply(seq_len(nrow(cond)), function(i)
  do.call(rbind, lapply(seq_len(R), function(r) {
    out <- one(cond$n[i], cond$rel[i])
    if (!is.null(out)) out$replication <- r
    out
  }))))

## save
reps <- res[c("n", "rel", "replication", "estimator", "par", "true", "est",
              "se", "ci.lower", "ci.upper")]
names(reps) <- c("n", "rel", "replication", "estimator", "parameter", "true",
                 "estimate", "se", "ci_lower", "ci_upper")
rownames(reps) <- NULL
dir.create("results", showWarnings = FALSE)
saveRDS(reps, "results/replications.rds")
