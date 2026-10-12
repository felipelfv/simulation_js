library(rix)

# Reproducible environment for the MIIV / James-Stein simulation manuscript.
# The simulation results in the manuscript were produced with the lavaan
# development version 0.7-2.3274, pinned below to its GitHub commit.
rix(date = "2026-05-11", # available_dates(); 1.8.x quarto (1.9.37 has a pandoc bug)
    r_pkgs = c("ggplot2", "simhelpers",
               "knitr"),                   # knitr: R engine quarto uses for code chunks
    system_pkgs = "quarto",                # quarto CLI to render the paper
    # LaTeX deps for the Quarto PDF; extend as the build reports missing .sty
    tex_pkgs = c("amsmath", "framed", "fvextra", "fancyvrb", "booktabs",
                 "caption", "etoolbox", "xcolor", "geometry", "hyperref",
                 "float", "pgf", "standalone",
                 # apaquarto (apa7.cls) + the packages it and its template load
                 "apa7", "scalerel", "endfloat", "substr", "xstring",
                 "threeparttable",
                 "threeparttablex", "multirow", "colortbl", "xpatch", "lineno",
                 "fontawesome5", "newtx", "fontaxes", "pbalance", "tcolorbox",
                 "tikzfill", "environ", "pdfcol", "mathspec", "xecjk",
                 "pdflscape", "babel-english"),
    git_pkgs = list(
      list(package_name = "lavaan",
           repo_url = "https://github.com/yrosseel/lavaan",
           commit = "f16c655227ebf999ac39681eb744172c2d7bde6c")
    ),
    project_path = ".",
    overwrite = TRUE
)

# rix bug workaround (per the official docs: "manually inspect and fix the file")
# https://docs.ropensci.org/rix/articles/remote-dependencies.html
# lavaan's DESCRIPTION has `Depends: R (>= ...)`, which rix mis-parses as an
# R-package dependency. R lives at pkgs.R, not pkgs.rPackages.R
# current solution: strip the bad line so the nix build succeeds
nix <- readLines("default.nix")
nix <- nix[!grepl("^\\s+R\\s*$", nix)]
writeLines(nix, "default.nix")
