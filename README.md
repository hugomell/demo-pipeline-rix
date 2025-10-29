# Comparative Minds Notebooks - Demo reproducible pipeline


## Nix configuration

To manage the pipeline dependencies, I will need Nix and `rix`.

I already have installed Nix on my machine using The Determinate Nix
Installer, but I am not sure I have the `cachix` client and `rstats-on-nix`
cache configured as recommended in the following
[vignette](https://docs.ropensci.org/rix/articles/b1-setting-up-and-using-rix-on-linux-and-windows.html#using-the-determinate-systems-installer).

However I get an error when I run the suggested `nix-env` command:

```bash
nix-env -iA cachix -f https://cachix.org/api/v1/install
#> error: profile '/home/hugo/.local/state/nix/profiles/profile' is
#> incompatible with 'nix-env'; please use 'nix profile' instead
```

I decided to try to fix this issue by reinstalling Nix using the Determinate
Nix Installer:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

Since I already have Nix on my machine, the installation failed at first
(after hanging for a few minutes) but I was automatically asked to uninstall Nix
instead.
On the second run of the above command the installation was successful.
However I had to reinstall all software in my global `devbox` configuration
which took a few minutes...

So now I re-ran the `nix-env` command:

```bash

nix-env -iA cachix -f https://cachix.org/api/v1/install

```

No errors! \o/

Then, as recommended in the vignette, we run:

```bash

cachix use rstats-on-nix

# NB: To avoid running the above command as root I first add to run:
 echo "trusted-users = root hugo" | sudo tee -a /etc/nix/nix.conf && sudo pkill nix-daemon
# Then I re-ran the cachix command from another shell

```

Ok, now we should be good to go!



## Bootstrapping a `rix` project

```bash

nix-shell --expr "$(curl -sl https://raw.githubusercontent.com/ropensci/rix/main/inst/extdata/default.nix)"

```

Write a `gen-env.R` file with the following content:

```R
# copy to `gen-env.R` 
library(rix)

# Define execution environment
rix(
  date = "2025-04-11",
  r_pkgs = c("dplyr", "ggplot2"),
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)
```

Then, in the temporary Nix shell, we run:

```bash

Rscript gen-env.R

```

And in a regular shell: `nix-build`

To use the environment I can run `nix-shell`.



## Using containers to manage the environment

### Generic Dockerfile

We can just modify the generic Dockerfile provided in the vignette (see
Resources).

```containerfile
## copy to Containerfile
FROM ubuntu:latest

RUN apt update -y

RUN apt install curl -y

WORKDIR /code

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
```

To build the image:

```bash

podman build -t demo-rix-image .

```

To run a container:

```bash

podman run --rm -it --name demo-rix demo-rix-image

```

Ok, I have access to both `dplyr` and `ggplot2` from within the Nix shell.

### Deploying simple devcontainer to Github Codespaces

First, I needed to create a new repository on Github and push my local repo
to it:

```bash

git remote add github-remote git@github.com:hugomell/demo-pipeline-rix.git

git push github-remote main

```

Then, I add a `.devcontainer.json` file at the root of the project:

```json
# copy to .devcontainer.json
{
    "name" : "Nix inside Docker on Github",
    "build" : {
        "dockerfile" : "Containerfile"
    },
    "customizations": {
        "vscode": {
            "extensions": [
                "REditorSupport.r",
                "quarto.quarto"
            ],
            "settings": {
                "r.plot.devArgs": {
                      "width": 1200,
                      "height": 500
                    },
                "workbench.editorAssociations": {
                      "*.qmd": "quarto.visualEditor"
                    }
            }
        }
    }
}
```

Now I should be able to create a Codespace from the Github repository home
page that spins up the devcontainer defined above.

### Running the devcontainer locally

I can do so easily with `devpod`:

```bash
devpod up . --ide=none /code
```



## Build a reproducible pipeline with `targets` 





## Resources

* Setting up a project is documented in this
[vignette](https://docs.ropensci.org/rixpress/articles/tutorial.html) 
* Using Nix inside Docker is documented in this
[vignette](https://cran.r-project.org/web/packages/rix/vignettes/z-advanced-topic-using-nix-inside-docker.html) 
* Codespaces with R project:
  - [Step-by-step guide](https://github.com/RamiKrispin/vscode-r#setting-the-dev-containers-extension) 
  - [Post on RStudio and devcontainers](https://medium.com/@adnaan525/codespace-the-next-best-thing-since-sliced-bread-439a13aba0ec) 
  - [devcontainer Configuration for R](https://earthdatascience.org/pages/10-get-started/r-codespaces/02-r-devcontainer.html) 

