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
