library(rix)

# Reproducible environment for the MIIV / James-Stein simulation manuscript.
# The simulation results in the manuscript were produced with the lavaan
# development version 0.7-3.3292, pinned below to its GitHub commit.
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
           commit = "54b89fb9b8c1c9257edfcc39ea0f44b4f6e92af3")
    ),
    project_path = ".",
    overwrite = TRUE
)
