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

### Test compiling a simple quarto document

```R
# copy in gen-env.R
library(rix)

rix(
  date = "2025-10-27",
  r_pkgs = c("quarto", "MASS"),
  system_pkgs = "quarto",
  tex_pkgs = c(
    "amsmath",
    "environ",
    "fontawesome5",
    "orcidlink",
    "pdfcol",
    "tcolorbox",
    "tikzfill"
  ),
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)
```

```bash

nix-shell --expr "$(curl -sl https://raw.githubusercontent.com/ropensci/rix/main/inst/extdata/default.nix)"

# in Nix shell
Rscript gen-env.R

```

```bash
# in regular shell

nix-build

nix-shell
```

```bash
# in Nix shell

quarto add quarto-journals/jss

# after downloading from https://github.com/quarto-journals/jss/blob/main/template.qmd:
# - article-visualization.pdf
# - bibliography.bib
# - template.qmd

quarto render template.qmd

#> TexLive update ERROR...
```

Tested again with the exact `default.nix` file in the vignette which does not
use rstats-on-nix cache but still not working.
I am not sure why it does not work but probably something to do with the fact
that Quarto's built-in PDF engine performs automatic installation of any
missing Tex packages and this
section of the quarto [docs](https://quarto.org/docs/output-formats/pdf-engine.html):

> Each year in April, TeXlive updates their remote package repository to the
> new year’s version of TeX. When this happens, previous year installations of
> TeX will not be able to download and install packages from the remote
> repository. When this happens, you may see an error like: Your TexLive
> version is not updated enough to connect to the remote repository and
> download packages. Please update your installation of TexLive or TinyTex.
> When this happens, you can use quarto update tinytex to download and install
> an updated version of tinytex.

But anyway I want to build HTML documents so let's leave this issue aside for
now.


### Quarto document as output of a `targets` pipeline

#### Testing simple brms model in Nix managed environment

Goal here is to build a targets pipeline that produce a quarto document
which will be a stripped down version of the section of the first chapter of
the [brms book](https://paulbuerkner.com/software/brms-book/brms-book.pdf) 
on the first model `epi_gaussian1`.

So first I need to rewrite a `gen-env.R` file with the required
dependencies:

```r
# copy in gen-env.R
library(rix)

rix(
  date = "2025-10-27",
  r_pkgs = c("bayesplot", "brms", "ggplot2",  "magrittr", "posterior",
              "quarto", "rmarkdown", "targets", "tarchetypes"),
  system_pkgs = c("quarto", "git", "cmdstan"),
  git_pkgs = list(
    list(
      package_name = "cmdstanr",
      repo_url = "https://github.com/stan-dev/cmdstanr",
      commit = "da99e2ba954658bdad63bffb738c4444c33a4e0e"
    )
  ),
  ide = "radian",
  project_path = ".",
  tex_pkgs = c("amsmath"),
  overwrite = TRUE
)
```

I took some inspiration from the configuration given in this [rix
issue](https://github.com/ropensci/rix/issues/386).

```bash
nix-shell -p R rPackages.rix
Rscript gen-env.R
```

```bash
nix-build
nix-shell

# inside Nix shell
radian
```

Fitting `epi_gaussian1` model of chapter 1 of brms book works well with this
setup:

```r
library(magrittr)
library(posterior)
library(ggplot2)
library(bayesplot)
library(brms)

data("epilepsy", package = "brms")

fit_epi_gaussian1 <- brm(count ~ 1 + Trt, data = epilepsy)

mcmc_plot(fit_epi_gaussian1, type = "trace")
mcmc_plot(fit_epi_gaussian1, type = "dens")

summary(fit_epi_gaussian1)

draws <- as_draws_df(fit_epi_gaussian1) %>%
  mutate_variables(sigma2 = sigma^2, mu_Trt = b_Intercept + b_Trt1)

bayesplot::mcmc_hist(draws, c("sigma2", "mu_Trt"), bins = 30)
```

#### Building the pipeline




## Resources

* Setting up a project is documented in this
[vignette](https://docs.ropensci.org/rixpress/articles/tutorial.html) 
* Using Nix inside Docker is documented in this
[vignette](https://cran.r-project.org/web/packages/rix/vignettes/z-advanced-topic-using-nix-inside-docker.html) 
* Codespaces with R project:
  - [Step-by-step guide](https://github.com/RamiKrispin/vscode-r#setting-the-dev-containers-extension) 
  - [Post on RStudio and devcontainers](https://medium.com/@adnaan525/codespace-the-next-best-thing-since-sliced-bread-439a13aba0ec) 
  - [devcontainer Configuration for R](https://earthdatascience.org/pages/10-get-started/r-codespaces/02-r-devcontainer.html) 
* Reproducible pipeline with `rix` and `targets`:
  - [vinette Literate programming](https://docs.ropensci.org/rix/articles/z-advanced-topic-building-an-environment-for-literate-programming.html?q=quarto#introduction) 
  - [vignette Reproducible pipeline](https://docs.ropensci.org/rix/articles/z-advanced-topic-reproducible-analytical-pipelines-with-nix.html) 
  - [Github issue](https://github.com/ropensci/rix/issues/386) 
