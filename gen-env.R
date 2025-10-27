# This script defines the default environment the pipeline runs in.
# Add the required packages to execute the code necessary for each derivation.
# If you want to create visual representations of the pipeline, consider adding
# `{visNetwork}` and `{ggdag}` to the list of R packages.
library(rix)

# Define execution environment
rix(
  date = "2025-04-11",
  r_pkgs = c("dplyr", "igraph"),
  git_pkgs = list(
    "package_name" = "rixpress",
    "repo_url" = "https://github.com/b-rodrigues/rixpress",
    "commit" = "HEAD"
  ),
  ide = "rstudio",
  project_path = ".",
  overwrite = TRUE
)
