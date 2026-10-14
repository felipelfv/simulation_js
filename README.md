# README

This repository contains the code, results, and manuscript for the article
**"Model-Implied Instrumental-Variable and James–Stein Estimation of
Structural Equation Models: A Case Study With lavaan"** by Felipe Fontana
Vieira and Yves Rosseel.

The article sets out model-implied instrumental-variable two-stage least
squares (MIIV-2SLS) and the scaling and aggregated James–Stein estimators as
implemented in lavaan, states the delta method standard errors for the
James–Stein estimators, and evaluates the standard errors of all four
estimators (JS, JSA, MIIV-2SLS, ML) in a simulation study with 6 sample sizes
× 2 reliability levels = 12 conditions, each run for 1,500 replications.

<sub>The code in this repository is licensed under the [MIT License](LICENSE).
The manuscript, figures, and other non-code content are licensed under a
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).</sub>

## Repository Structure

```
.
├── gen_env.R                  # generates default.nix via {rix} (pinned R + packages + Quarto + TeX)
├── default.nix                # generated environment definition (built with nix-shell)
├── Dockerfile                 # containerised build: installs Nix, builds the environment, renders the manuscript
├── .dockerignore              # trims the Docker build context (excludes .git, result, caches)
├── simulation.R               # data generation and estimation → results/replications.rds
├── performance_calculation.R  # screening and performance measures → results/{performance,screening}.rds
├── results/
│   ├── replications.rds       # one row per replication × estimator × estimand (n, rel, replication,
│   │                          #   estimator, parameter, true, estimate, se, ci_lower, ci_upper)
│   ├── performance.rds        # one row per condition × estimator × estimand (K, bias, sd, sd_mcse,
│   │                          #   se_sd, rb_var, rb_var_mcse, coverage, coverage_mcse)
│   └── screening.rds          # convergence, outlier, and inadmissibility counts
├── miiv_js_estimation.qmd     # paper source (APA 7 via the apaquarto extension)
├── references.bib             # bibliography
├── miiv_js_estimation.pdf     # rendered output
├── _extensions/               # vendored apaquarto extension
└── docs/
    ├── miiv_js_estimation.pdf # copy of the rendered PDF served via GitHub Pages
    └── index.html             # redirect to the PDF
```

`miiv_js_estimation.pdf` and `docs/` are rebuilt and committed on every push
to `main` by the GitHub Actions workflow (`.github/workflows/render.yaml`),
which builds the Nix environment and renders the manuscript from the saved
results.

## Pipeline

The pipeline has three stages. Each stage reads the previous stage's output,
so the manuscript can be rendered from the committed results without rerunning
the simulation.

### Step 1: Run the simulation

```sh
nix-shell --pure --run 'Rscript simulation.R'    # → results/replications.rds
```

`simulation.R` generates the data under the population model and fits every
data set with the four estimators (`lavaan::sem` with `estimator = "JS"`,
`"JSA"`, `"IV"`, and `"ML"`, all with a mean structure). It stores the
estimates, standard errors, and confidence intervals of every free parameter
other than the intercepts. One seed (`1234`) is set before the loop. The run
takes about 45 minutes on a laptop.

### Step 2: Screen the replications and compute the performance measures

```sh
nix-shell --pure --run 'Rscript performance_calculation.R'    # → results/{performance,screening}.rds
```

`performance_calculation.R` applies the two-step screening described in the
paper (convergence, then outliers by the three interquartile range rule,
removing a flagged replication for all estimators), counts inadmissible
solutions, and computes the performance measures and their Monte Carlo
standard errors with *simhelpers*. If `results/replications.rds` is missing,
it runs `simulation.R` first.

### Step 3: Render the manuscript

```sh
nix-shell --pure --run 'quarto render miiv_js_estimation.qmd'    # → miiv_js_estimation.pdf
```

The manuscript sources `performance_calculation.R`, so rendering it also
regenerates `results/performance.rds` and `results/screening.rds` from the
saved replications. Deleting `results/replications.rds` before rendering
reruns the whole pipeline.

### Data flow

```
simulation.R ──> results/replications.rds
                          │
                          ▼
performance_calculation.R ──> results/performance.rds, results/screening.rds
                          │
                          ▼
miiv_js_estimation.qmd ──> miiv_js_estimation.pdf
```

### Reproducing with Docker

If you would rather not install Nix on your host, the `Dockerfile` installs Nix
inside a container and builds the pinned environment for you. Only Docker is
required. The image can either render the manuscript from the committed
results or rerun the whole pipeline first.

```bash
# Build the image (installs Nix, builds default.nix)
docker build -t miiv-js-manuscript .

# Option 1: render the manuscript from the committed results;
# the PDF is written to your local docs/ folder
docker run --rm -v "$PWD/docs:/project/docs" miiv-js-manuscript

# Option 2: rerun the simulation and the performance calculation, then render;
# the .rds files are written to your local results/ folder and the PDF to docs/
docker run --rm -v "$PWD/results:/project/results" -v "$PWD/docs:/project/docs" miiv-js-manuscript \
  nix-shell default.nix --run "Rscript simulation.R && Rscript performance_calculation.R && quarto render miiv_js_estimation.qmd && cp miiv_js_estimation.pdf docs/"
```

## Reproducible Environment

`default.nix` is generated by `gen_env.R` with the [rix](https://docs.ropensci.org/rix/)
package. It pins R and all R packages to the `rstats-on-nix` snapshot of
2026-05-11, lavaan to the GitHub commit carrying development version
0.7-3.3292 (the version used for the results), and the Quarto CLI and TeX
packages needed by apaquarto. With Nix installed, `nix-build` creates the
environment and `nix-shell` enters it.
