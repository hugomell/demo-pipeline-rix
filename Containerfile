FROM ubuntu:latest

RUN apt update -y

RUN apt install curl -y

# Download default `default.nix` 
RUN curl -O https://raw.githubusercontent.com/ropensci/rix/main/inst/extdata/default.nix

# Copy a script to generate the environment of interest using {rix}
COPY gen-env.R .

# Install Nix inside Docker
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
  --extra-conf "sandbox = false" \
  --init none \
  --no-confirm

# Adds Nix to the path
ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"
ENV user=root

# Set up rstats-on-nix cache
RUN mkdir -p /root/.config/nix && \
    echo "substituters = https://cache.nixos.org https://rstats-on-nix.cachix.org" > /root/.config/nix/nix.conf && \
    echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0=" >> /root/.config/nix/nix.conf

# Overwrite the default.nix downloaded previously
RUN nix-shell --run "Rscript gen-env.R"

# Build the environment
RUN nix-build

# Start Nix shell
CMD nix-shell
