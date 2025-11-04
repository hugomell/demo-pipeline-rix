# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) # Load other packages as needed.

# Define the target list with the pipeline steps:
list(
  tar_target(
    name = data,
    command = data.frame(x = seq_len(26), y = letters)
  ),
  # Compile quarto report
  tar_quarto(
    name = site,
    path = "./site"
  )
)
