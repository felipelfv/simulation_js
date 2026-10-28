# README

This repository contains the code, results, and manuscript for the article
**"James–Stein Estimation of Structural Equation Models With Latent
Variables: A Case Study With lavaan"** by Felipe Fontana Vieira and Yves
Rosseel.

<sub>The code in this repository is licensed under the [MIT License](LICENSE).
The manuscript, figures, and other non-code content are licensed under a
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).</sub>

## Repository Structure

```
.
├── .github/workflows/render.yaml  # GitHub Actions: renders the manuscript and commits the pdf on every push
├── gen_env.R                  # generates default.nix via {rix} (pinned R + packages + Quarto + TeX)
├── default.nix                # generated environment definition (built with nix-shell)
├── Dockerfile                 # Docker build: installs Nix, builds the environment, renders the manuscript
├── .dockerignore              # trims the Docker build context (excludes .git, result, caches)
├── .zenodo.json               # metadata for the Zenodo archive of each GitHub release
├── run_all.R                  # runs simulation.R and then performance_calculation.R
├── simulation.R               # data generation and estimation → results/replications.rds
├── performance_calculation.R  # screening and performance measures → results/{performance,screening}.rds
├── results/
│   ├── replications.rds       # one row per replication × estimator × estimand (n, rel, replication,
│   │                          #   estimator, parameter, true, estimate, se, ci_lower, ci_upper)
│   ├── performance.rds        # one row per condition × estimator × estimand (K, bias, rel_bias,
│   │                          #   rel_bias_mcse, sd, sd_mcse, se_sd, rb_var, rb_var_mcse,
│   │                          #   coverage, coverage_mcse)
│   └── screening.rds          # convergence, outlier, and inadmissibility counts
├── manuscript.qmd             # paper source (apa 7 via the apaquarto extension)
├── references.bib             # bibliography
├── manuscript.pdf             # rendered output
├── _extensions/               # apaquarto extension
└── docs/
    ├── manuscript.pdf         # copy of the rendered pdf served via GitHub Pages
    └── index.html             # redirect to the pdf
```

`manuscript.pdf` and `docs/` are rebuilt and committed on every push
to `main` by the GitHub Actions workflow (`.github/workflows/render.yaml`),
which builds the Nix environment and renders the manuscript from the saved
results.

## Pipeline

The commands below assume an R installation with the packages listed under
[Reproducible Environment](#reproducible-environment) and the Quarto CLI. See
[Three Ways to Reproduce the Article](#three-ways-to-reproduce-the-article)
for obtaining such an environment with Nix, Docker, or plain R.

`run_all.R` runs Steps 1 and 2 in sequence, so the whole simulation pipeline
can be reproduced with a single command:

```sh
Rscript run_all.R
```

The steps can also be run separately, as described below.

The pipeline has three stages. Each stage reads the previous stage's output,
so the manuscript can be rendered from the committed results without rerunning
the simulation.

### Step 1: Run the simulation

```sh
Rscript simulation.R    # → results/replications.rds
```

`simulation.R` generates the data under the population model and fits every
data set with the four estimators (`lavaan::sem` with `estimator = "JS"`,
`"JSA"`, `"IV"`, and `"ML"`). It stores the estimates, standard errors, and 
confidence intervals of every free parameter
other than the intercepts. One seed (`1234`) is set before the loop. The run
takes about 55 minutes on an Apple M4 Pro with 24 GB of memory running macOS
Sequoia 15.7.3.

### Step 2: Screen the replications and compute the performance measures

```sh
Rscript performance_calculation.R    # → results/{performance,screening}.rds
```

`performance_calculation.R` applies the two-step screening described in the
paper (convergence, then outliers by the three interquartile range rule,
removing a flagged replication for all estimators), counts inadmissible
solutions, and computes the performance measures and their Monte Carlo
standard errors with *simhelpers*. If `results/replications.rds` is missing,
it runs `simulation.R` first.

### Step 3: Render the manuscript

```sh
quarto render manuscript.qmd    # → manuscript.pdf
```

The manuscript sources `performance_calculation.R`, so rendering it also
regenerates `results/performance.rds` and `results/screening.rds` from the
saved replications. Deleting `results/replications.rds` before rendering
reruns the simulation as well, so a single render then executes all three
stages.

### Data flow

```
simulation.R ──> results/replications.rds
                          │
                          ▼
performance_calculation.R ──> results/performance.rds, results/screening.rds
                          │
                          ▼
manuscript.qmd ──> manuscript.pdf
```

## Reproducible Environment

`default.nix` is generated by `gen_env.R` with the [rix](https://docs.ropensci.org/rix/)
package. It pins R and all R packages to the `rstats-on-nix` snapshot of
2026-05-11, lavaan to the CRAN release 0.7-3 (the version used for the
results), and the Quarto CLI and TeX packages needed by apaquarto. Because
lavaan 0.7-3 is newer than the snapshot date, it is taken from the 0.7-3 tag
of the CRAN GitHub mirror (`cran/lavaan`), which holds the exact CRAN source. 
The environment provides:

| Software   | Version    |
|------------|------------|
| R          | 4.6.0      |
| lavaan     | 0.7-3      |
| simhelpers | 0.3.1      |
| ggplot2    | 4.0.3      |
| knitr      | 1.51       |
| Quarto     | 1.8.26     |

The committed results in `results/` were produced inside this environment
(`nix-shell --pure`). The manuscript PDF in this repository is
rendered on GitHub Actions inside the Nix environment.

## Three Ways to Reproduce the Article

### 1. Nix on your own machine

Install Nix and build the pinned environment from the committed
`default.nix`, then run the pipeline inside it. The rix documentation
explains how to install Nix and use the environment:
[Getting Started](https://docs.ropensci.org/rix/articles/getting-started.html),
[Setting Up and Using Nix and Rix on macOS](https://docs.ropensci.org/rix/articles/setting-up-macos.html),
and [on Linux and Windows](https://docs.ropensci.org/rix/articles/setting-up-linux-windows.html).

```sh
nix-build                                                        # builds the environment
nix-shell --pure --run 'quarto render manuscript.qmd'            # renders from the committed results
nix-shell --pure --run 'Rscript run_all.R'                       # optional: reruns the simulation and performance measures first
```

### 2. Docker

If you would rather not install Nix on your host, the `Dockerfile` installs Nix
inside a container and builds the same pinned environment for you. Only Docker
is required. The image can either render the manuscript from the committed
results or rerun the whole pipeline first.

```bash
# build the image (installs Nix, builds default.nix)
docker build -t manuscript .

# option 1: render the manuscript from the committed results.
# the pdf is written to your local docs/ folder
docker run --rm -v "$PWD/docs:/project/docs" manuscript

# option 2: rerun the simulation and the performance calculation, then render.
# the .rds files are written to your local results/ folder and the pdf to docs/
docker run --rm -v "$PWD/results:/project/results" -v "$PWD/docs:/project/docs" manuscript \
  nix-shell default.nix --run "Rscript run_all.R && quarto render manuscript.qmd && cp manuscript.pdf docs/"
```

### 3. Plain R, without Nix or Docker

Install R, Quarto, and the packages in the table above, as close to the listed
versions as you can, and run the scripts directly:

```sh
Rscript run_all.R                    # optional, about 55 minutes. runs simulation.R and performance_calculation.R
                                     #   (results/ is committed, so this can be skipped)
quarto render manuscript.qmd         # → manuscript.pdf
```

lavaan must be version 0.7-3 or later (published on CRAN 2026-10-08). The
`IV` estimator first appeared in 0.7-2, and 0.7-3 is the first release in
which `JS` and `JSA` handle latent regressions and provide analytical standard
errors. Earlier releases restricted them to confirmatory factor models.
The committed results were produced with lavaan 0.7-3 from CRAN. To install
exactly that version:

```r
remotes::install_version("lavaan", version = "0.7-3")
```

Rendering the manuscript also needs the TeX packages used by apaquarto.
