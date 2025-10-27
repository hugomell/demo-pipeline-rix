# Comparative Minds Notebooks - Demo reproducible pipeline


## Nix configuration

To manage the pipeline dependencies, I will need Nix, `rix` and `rixpress`.

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

## Bootstrapping a project

### Defining and building the environment

```bash

nix-shell --expr "$(curl -sl https://raw.githubusercontent.com/ropensci/rix/main/inst/extdata/default.nix)"

```

```R

library(rixpress)

rxp_init()

```

```R
# copy to `gen-env.R` 
library(rix)

# Define execution environment
rix(
  date = "2025-04-11",
  r_pkgs = c("dplyr", "igraph"),
  git_pkgs = list(
    package_name = "rixpress",
    repo_url = "https://github.com/ropensci/rixpress",
    commit = "HEAD"
  ),
  ide = "rstudio",
  project_path = ".",
  overwrite = TRUE
)
```

Then, in the temporary Nix shell, we run:

```bash

Rscript gen-env.R

```

And in a regular shell: `nix-build` (took maybe ~15 minutes to build, but
a lot of the time probably was for the installation of RStudio).

To use the environment I can run `nix-shell` and then `rstudio`.

### Defining and building the pipeline

Next, we define our pipeline:

```R
# copy to `gen-pipeline.R` 
library(rixpress)
library(igraph)

list(
  rxp_r_file(
    name = mtcars,
    path = 'data/mtcars.csv',
    read_function = \(x) (read.csv(file = x, sep = "|"))
  ),

  rxp_r(
    name = filtered_mtcars,
    expr = filter(mtcars, am == 1)
  )
) |> rxp_populate(build = TRUE)
```

We can source the file to build it: `source("gen-pipeline.R")` 
-> Successful built! \o/

```R

rxp_read("filtered_mtcars")

# to save the object:
rxp_load("filtered_mtcars")
# which is equivalent to `filtered_mtcars <- rxp_read("filtered_mtcars")`

```


## Resources

* Setting up a project is documented in this [vignette](https://docs.ropensci.org/rixpress/articles/tutorial.html) 
