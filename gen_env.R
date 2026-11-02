library(rix)

# the simulation results in the manuscript were produced with the development
# version of lavaan 0.7-3.3364 (GitHub yrosseel/lavaan, commit ef620c8 of
# 2026-11-01).
rix(date = "2026-05-11", # available_dates(), 1.8.x quarto (1.9.37 has a pandoc bug)
    r_pkgs = c("ggplot2", "simhelpers",
               "knitr"),                   # knitr: R engine quarto uses for code chunks
    system_pkgs = "quarto",                # quarto cli to render the paper
    # LaTeX deps for the Quarto pdf, extend as the build reports missing .sty
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
           commit = "ef620c8ed3cfd0cdf2821ad2c75e57bb75cf0358")   # 0.7-3.3364, 2026-11-01
    ),
    project_path = ".",
    overwrite = TRUE
)
