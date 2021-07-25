source(here::here("src", "utils.R"))
source_here("dependencies.R")
gen_files <- dir(here::here("src"), full.names=TRUE, pattern="generate_")
purrr::walk(gen_files, source_here)
