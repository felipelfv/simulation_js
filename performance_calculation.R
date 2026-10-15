# performance_calculation.R

# screens the replications and computes the performance measures.
# input:  results/replications.rds (written by simulation.R, which is run
#  first if the file is missing)
# output: results/performance.rds, one row per condition, estimator, and
#  estimand (K, bias, rel_bias, rel_bias_mcse, sd, sd_mcse, se_sd, rb_var,
#  rb_var_mcse, coverage, coverage_mcse), and results/screening.rds, the
#  convergence, outlier, and inadmissibility counts.

library(simhelpers)

if (!file.exists("results/replications.rds")) source("simulation.R")
res <- readRDS("results/replications.rds")
ns <- sort(unique(res$n)); rels <- sort(unique(res$rel))
est <- c("JS", "JSA", "IV", "ML")
R <- max(res$replication); n_cond <- length(ns) * length(rels)

# screening: convergence, outliers, inadmissible solutions
res$cond <- paste(res$n, res$rel)
key <- function(d) paste(d$cond, d$replication)
nonfinite <- !is.finite(res$estimate) | !is.finite(res$se) |
  !is.finite(res$ci_lower) | !is.finite(res$ci_upper)
nonconv <- unique(res[nonfinite, c("cond", "replication", "estimator")])
res_c <- res[!key(res) %in% key(nonconv), ]
out <- do.call(rbind, lapply(split(res_c, res_c[c("cond", "estimator", "parameter")]),
  function(x) {
    q <- quantile(x$estimate, c(0.25, 0.75)); iqr <- q[2] - q[1]
    flag <- x$estimate < q[1] - 3 * iqr | x$estimate > q[2] + 3 * iqr
    if (!any(flag)) NULL else
      data.frame(cond = x$cond[1], estimator = x$estimator[1],
                 replication = x$replication[flag])
  }))
out_rep <- unique(out[c("cond", "replication")])
res_s <- res_c[!key(res_c) %in% key(out_rep), ]
inad <- unique(res[grepl("~~", res$parameter) & res$estimate <= 0,
                   c("cond", "estimator", "replication")])
scr <- list(
  nonconv = nrow(nonconv),
  removed = nrow(out_rep),
  removed_pct = 100 * nrow(out_rep) / (R * n_cond),
  removed_by_cond = sort(100 * table(out_rep$cond) / R, decreasing = TRUE),
  flagged_by_est = 100 * table(unique(out[c("cond", "estimator", "replication")])$estimator) / (R * n_cond),
  flagged_100_06 = 100 * table(factor(unique(out[out$cond == "100 0.6",
                                                 c("estimator", "replication")])$estimator, levels = est)) / R,
  removed_replications = out_rep,
  inad = nrow(inad),
  inad_by = table(inad$estimator, inad$cond),
  inadmissible_replications = inad)

# performance measures on the retained replications
summ <- do.call(rbind, lapply(split(res_s, res_s[c("n", "rel", "estimator", "parameter")]),
  function(x) {
    tp <- x$true[1]
    ab <- calc_absolute(x, estimates = estimate, true_param = tp,
                        criteria = c("bias", "stddev"))
    rl <- calc_relative(x, estimates = estimate, true_param = tp,
                        criteria = "relative bias")
    rv <- calc_relative_var(x, estimates = estimate, var_estimates = se^2,
                            criteria = "relative bias")
    cv <- calc_coverage(x, lower_bound = ci_lower, upper_bound = ci_upper,
                        true_param = tp, criteria = "coverage")
    data.frame(x[1, c("n", "rel", "estimator", "parameter")],
               K = ab$K_absolute,
               bias = ab$bias,
               rel_bias = rl$rel_bias - 1, rel_bias_mcse = rl$rel_bias_mcse,
               sd = ab$stddev, sd_mcse = ab$stddev_mcse,
               se_sd = mean(x$se) / ab$stddev,
               rb_var = rv$rel_bias_var, rb_var_mcse = rv$rel_bias_var_mcse,
               coverage = cv$coverage, coverage_mcse = cv$coverage_mcse)
  }))
rownames(summ) <- NULL

# save
saveRDS(summ, "results/performance.rds")
saveRDS(scr, "results/screening.rds")
