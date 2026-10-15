library(rix)

# the simulation results in the manuscript were produced with the CRAN release
# of lavaan 0.7-3 (published 2026-10-08). It is newer than the snapshot date and
# not yet in the CRAN archive, so it is pinned to the 0.7-3 tag of the CRAN
# GitHub mirror (cran/lavaan), which holds the exact CRAN source.
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
           repo_url = "https://github.com/cran/lavaan",
           commit = "3d10d4a43d8d15ee683b78d4d6e769804ca87c7c")   # tag 0.7-3
    ),
    project_path = ".",
    overwrite = TRUE
)
