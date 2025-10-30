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
