## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 5, fig.height = 5
)

## ---- include=FALSE-----------------------------------------------------------

library(dplyr)
library(GISSB)

# Laster inn filene #
# vegnett <- sf::read_sf("C:/Users/rdn/Downloads/Samferdsel_0000_Norge_25833_NVDBRuteplanNettverksdatasett_FGDB/vegnettRuteplan_FGDB_20210528.gdb", 'ERFKPS')

# OBS
# graph <- readRDS(file = "C:/Users/rdn/Documents/Kart/Vegnett/graph.rds")
# nodes <- readRDS(file = "C:/Users/rdn/Documents/Kart/Vegnett/nodes.rds")
# edges <- readRDS(file = "C:/Users/rdn/Documents/Kart/Vegnett/edges.rds")
# graph_cppRouting_minutes <- readRDS(file = "C:/Users/rdn/Documents/Kart/Vegnett/graph_cppRouting_minutes.rds")
# graph_cppRouting_meters <- readRDS(file = "C:/Users/rdn/Documents/Kart/Vegnett/graph_cppRouting_meters.rds")


## ---- eval=TRUE---------------------------------------------------------------
fra <- GISSB::address_to_coords(zip_code = "0177",
                         address = "Akersveien 26")

fra

til <- GISSB::address_to_coords(zip_code = "2211",
                         address = "Otervegen 23")

til

## ---- eval=TRUE---------------------------------------------------------------
postnummere = c("0177", "2211")
adresser = c("Akersveien 26", "Otervegen 23")

fra_4326 <- GISSB::address_to_coords(zip_code = postnummere,
                         address = adresser,
                         crs_out = 4326)
fra_4326

## ---- eval=TRUE---------------------------------------------------------------
leaflet::leaflet(width = "100%") %>%
  leaflet::addTiles() %>%
  leaflet::addMarkers(data = fra_4326$geometry)

## ---- eval=TRUE---------------------------------------------------------------
fra <- GISSB::coords_to_google(fra)
fra$coords_google

til <- GISSB::coords_to_google(til)
til$coords_google

## ---- eval=FALSE--------------------------------------------------------------
#  vegnett <- sf::read_sf("vegnettRuteplan_FGDB_20210528.gdb", 'ERFKPS')
#  
#  ggplot2::ggplot() +
#    ggplot2::geom_sf(data = vegnett)

## ---- echo=FALSE, error = TRUE, out.width = "100%"----------------------------
knitr::include_graphics(paste0(here::here(), "/vignettes/images/vegnett_2021.png"))

## ---- eval=FALSE--------------------------------------------------------------
#  vegnett_list <- vegnett_to_R(vegnett = vegnett_sampledata,
#                              year = 2021,
#                              fromnodeID = "FROMNODEID",
#                              tonodeID = "TONODEID",
#                              FT_minutes = "FT_MINUTES",
#                              TF_minutes = "TF_MINUTES",
#                              meters = "SHAPE_LENGTH")
#  
#  graph <- vegnett_list[[1]]
#  nodes <- vegnett_list[[2]]
#  edges <- vegnett_list[[3]]
#  graph_cppRouting_minutes <- vegnett_list[[4]]
#  graph_cppRouting_meters <- vegnett_list[[5]]

## ---- eval=FALSE--------------------------------------------------------------
#  from_node <- GISSB::coords_to_node(coords = fra, direction = "from")
#  from_node
#  
#  to_node <- GISSB::coords_to_node(coords = til, direction = "to")
#  to_node

## ---- eval=FALSE--------------------------------------------------------------
#  from_node <- GISSB::coords_to_node(coords = fra, direction = "from", membership = FALSE)
#  
#  to_node <- GISSB::coords_to_node(coords = til, direction = "to", membership = TRUE)

## ---- eval=FALSE--------------------------------------------------------------
#  avstand_min <- GISSB::shortest_path_igraph(from_node_ID = from_node$from_node,
#                             to_node_ID = to_node$to_node,
#                             unit = "minutes",
#                             path = F)
#  
#  paste0(round(avstand_min$length, digits = 1), " minutter / ",
#         substr(avstand_min$length/60, 1, 1),
#         " timer og ",
#         round(avstand_min$length, digits = 0)-as.numeric(substr(avstand_min$length/60, 1, 1))*60, " minutter")
#  
#  avstand_meter <- GISSB::shortest_path_igraph(from_node_ID = from_node$from_node,
#                                   to_node_ID = to_node$to_node,
#                                   unit = "meters",
#                                   path = F)
#  
#  paste0(round(avstand_meter$length, digits = 1), " meter / ",
#         round(avstand_meter$length/1000, digits = 1), " km."
#         )
#  

## ---- eval=FALSE--------------------------------------------------------------
#  path <- GISSB::shortest_path_igraph(from_node_ID = from_node$from_node,
#                             to_node_ID = to_node$to_node,
#                             unit = "minutes",
#                             path = TRUE)
#  
#  path$epath

## ---- eval=FALSE--------------------------------------------------------------
#  GISSB::path_leaflet(path)

## ---- eval=FALSE--------------------------------------------------------------
#  avstand_cpp_min <- GISSB::shortest_path_cppRouting(from_node$from_node,
#                                         to_node$to_node,
#                                         unit = "minutes",
#                                         graph_cppRouting_object = graph_cppRouting_minutes)
#  
#  avstand_cpp_min
#  
#  avstand_cpp_meter <- GISSB::shortest_path_cppRouting(from_node$from_node,
#                                         to_node$to_node,
#                                         unit = "meters",
#                                         graph_cppRouting_object = graph_cppRouting_meters)
#  
#  avstand_cpp_meter

## ---- eval=FALSE--------------------------------------------------------------
#  
#  adresser <- c("Sykehusveien 25",
#                "Sognsvannsveien 20",
#                "Kirkeveien 166",
#                "Parkvegen 35",
#                "Kirkevegen 31",
#                "Sjukehusveien 9",
#                "Sogneprest Munthe-Kaas vei 100")
#  
#  postnummere <- c("1474",
#                "0372",
#                "0450",
#                "2212",
#                "2413",
#                "2500",
#                "1346")
#  
#  til <- GISSB::address_to_coords(zip_code = postnummere,
#                           address = adresser) %>%
#    GISSB::coords_to_google()
#  
#  to_node <- GISSB::coords_to_node(coords = til, direction = "to", membership = F)
#  
#  to_node
#  
#  fra <- GISSB::address_to_coords(zip_code = c("0177", "2211"),
#                           address = c("Akersveien 26", "Otervegen 23")) %>%
#    GISSB::coords_to_google()
#  
#  from_node <- GISSB::coords_to_node(coords = fra, direction = "from", membership = T)
#  
#  from_node
#  
#  avstand_cpp <- GISSB::shortest_path_cppRouting(unique(from_node$from_node),
#                                         unique(to_node$to_node),
#                                         unit = "minutes")
#  avstand_cpp
#  
#  avstand_cpp_min <- GISSB::shortest_path_cppRouting(unique(from_node$from_node),
#                                         unique(to_node$to_node),
#                                         unit = "minutes",
#                                         dist = "min")
#  avstand_cpp_min
#  
#  avstand_cpp_max <- GISSB::shortest_path_cppRouting(unique(from_node$from_node),
#                                         unique(to_node$to_node),
#                                         unit = "minutes",
#                                         dist = "max")
#  avstand_cpp_max
#  
#  
#  

