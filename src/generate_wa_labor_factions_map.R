# dependencies
library(leaflet)  
library(tidyverse)
library(here)
options("rgdal_show_exportToProj4_warnings"="none")
library(rgdal)
library(rgeos)
library(geosphere)
library(sf)
library(googlesheets4)
source(here::here("src", "utils.R"))
# ingest MLA data - kept on google sheet for convenient updating
ss <- "15o0X79WuNDE9Un7r1ttPE7VeZTimmZMZ8mkKAtdBT_o"
wa_labor_factions <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/15o0X79WuNDE9Un7r1ttPE7VeZTimmZMZ8mkKAtdBT_o/edit?usp=sharing", sheet="data")
# ingest electorates
electorates <- readOGR(here("data", "input", "WAStateElectoratesProposedLGATE_133", "StateElectoratesProposedLGATE_133.shp"), layer = "StateElectoratesProposedLGATE_133", GDAL1_integer64_policy = TRUE)
# modify electorate data to include gs MLA information
mla_electorates <- electorates[electorates@data$type_descr=="Proposed MLA",]
mla_electorates@data <- mutate(mla_electorates@data, name = stringr::str_replace(name, ",.*$", ""))
wa_labor_factions.matchable <- mutate(wa_labor_factions, electorate = toupper(electorate))
mla_electorates.labor_enriched <- mla_electorates
mla_electorates.labor_enriched@data <- left_join(mla_electorates@data, wa_labor_factions.matchable, by=c("name"="electorate")) 
# simplify electorate polygons for a faster map experience
simp_electorates <- rgeos::gSimplify(mla_electorates.labor_enriched, topologyPreserve = TRUE, tol = 50)
# set up some unique colors to represent each faction
factions.uniq <- unique(mla_electorates.labor_enriched@data$faction)
pal.fctn <- colorFactor(RColorBrewer::brewer.pal(n=length(factions.uniq), name="Dark2"), factions.uniq)
# project polygons so they're mapable
simp_electorates_latlon <- spTransform(simp_electorates, CRS("+proj=longlat +datum=WGS84"))
popup_html <- "{mla_electorates.labor_enriched@data$name},  {mla_electorates.labor_enriched@data$mp},  {mla_electorates.labor_enriched@data$faction}"
map <-
leaflet() %>%
  addProviderTiles("CartoDB.Positron", options=providerTileOptions(noWrap=TRUE)) %>%
  #leaflet::setMaxBounds("113.338953078", "-43.6345972634", "153.569469029", "-10.6681857235") %>%
  setView(lat="-31.953512",lng="115.8613", zoom=9) %>%
  addPolygons(data=simp_electorates_latlon,
              stroke = TRUE, color=pal.fctn(mla_electorates.labor_enriched@data$faction), weight=5,
              fillColor = pal.fctn(mla_electorates.labor_enriched@data$faction), fillOpacity = 0.6,
              smoothFactor = 2,
              group = mla_electorates.labor_enriched@data$faction, 
              label=htmltools::htmlEscape(glue::glue(popup_html)),
              highlightOptions=highlightOptions("#fbf5e9", weight=8))
save_map(map, "WA Labor Factions")
