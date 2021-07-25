map_file <- function(map_name){
  dir <- here::here("map_html", map_name)
  if(!dir.exists(dir)) dir.create(dir, recursive=TRUE)
  here::here(dir, "index.html")
}

save_map <- function(map, map_title){
  map_name <- snakecase::to_snake_case(map_title)
  htmlwidgets::saveWidget(map, 
                          file=map_file(map_name),
                          title=map_title)
}