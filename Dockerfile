FROM ubuntu:latest

RUN apt update -y && apt install -y curl

# install the Nix package manager (Determinate Systems installer)
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
  --extra-conf "sandbox = false" \
  --init none \
  --no-confirm

ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"
ENV user=root

# rstats-on-nix binary cache -> download precompiled packages instead of building from source
RUN mkdir -p /root/.config/nix && \
    echo "substituters = https://cache.nixos.org https://rstats-on-nix.cachix.org" > /root/.config/nix/nix.conf && \
    echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0=" >> /root/.config/nix/nix.conf

WORKDIR /project

# bring in the whole repository: pinned default.nix, scripts, results/, manuscript, etc.
COPY . /project

# build the exact, pinned environment from the committed default.nix
RUN nix-build

# render the apa7 manuscript inside the reproducible Nix shell and copy the pdf
#  to docs/ (mount docs/ to retrieve it). The simulation results in results/ are
#  committed, so a render alone works.
# to re-run the full pipeline (simulation, performance measures, render) instead:
#   docker run --rm -v "$PWD/results:/project/results" -v "$PWD/docs:/project/docs" manuscript \
#     nix-shell default.nix --run "Rscript run_all.R && quarto render manuscript.qmd && cp manuscript.pdf docs/"
CMD nix-shell default.nix --run "quarto render manuscript.qmd && cp manuscript.pdf docs/"
