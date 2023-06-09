
#' Convert the Norwegian road network (NVDB Ruteplan nettverksdatasett) into network graphs in R
#'
#' The function `vegnett_to_R` can be used to convert the Norwegian road network, downloaded from \href{https://kartkatalog.geonorge.no/metadata/nvdb-ruteplan-nettverksdatasett/8d0f9066-34f9-4423-be12-8e8523089313}{Geonorge}, to formats that enable network analysis in R (`tbl_graph` and `cppRouting`).
#'
#' @param vegnett The Norwegian road network as an `sf` object, downloaded from \href{https://kartkatalog.geonorge.no/metadata/nvdb-ruteplan-nettverksdatasett/8d0f9066-34f9-4423-be12-8e8523089313}{Geonorge}.
#' @param crs_out Numeric vector with the chosen coordinate reference system (CRS). The default value is set to `CRS 25833`.
#' @param year Numeric vector with the year the road network is from. Due to changes in the format of the files between 2021 and 2022, the most important thing is to choose between the "old" format (-2021) or the new format (2022-). The default value is set to 2022. Please see the example for the column names for 2021 and earlier.
#' @param fromnodeID Character vector with the name of the column indicating the from node ID. Default value is set to `FROMNODE` (column name in 2022).
#' @param tonodeID Character vector with the name of the column indicating the to node ID. Default value is set to `TONODE` (column name in 2022).
#' @param FT_minutes Character vector with the name of the column that contains the cost in minutes from `fromnodeID` to `tonodeID` (FT). Default value is set to `DRIVETIME_FW` (column name in 2022).
#' @param TF_minutes Character vector with the name of the column that contains the cost in minutes from `tonodeID` to `fromnodeID` (TF). Default value is set to `DRIVETIME_BW` (column name in 2022).
#' @param meters Character vector with the name of the column that contains the cost in meters (equal for FT and TF). Default value is set to `SHAPE_LENGTH` (column name in 2022).
#' @param turn_restrictions Logical. Default value is `FALSE`. If `TRUE` turn restrictions will be added to the road network. The turn restrictions layer from the road network file has to be loaded before this can be used (and the object has to be called `turnrestrictions_geom`). Due to errors in the turn restrictions file for 2022 it is not recommended to use this feature for now.
#' @param ferry Logical/numeric vector. Default value is `TRUE` which means that all edges that involve ferries are given their original drive time (somewhere between 10 and 13 km/h). If a numeric value is supplied, the cost for all edges involving ferries will be converted to the supplied value in km/h.
#'
#' @returns List containing the following elements:
#'
#' `[1] graph`: the road network structured as a tidy graph (`tbl_graph` object).
#'
#' `[2] nodes`: the road network's nodes (`sf` object).
#'
#' `[3] edges`: road network's edges/node links (`data.frame`).
#'
#' `[4] graph_cppRouting_minutes`: the road network structured as a `cppRouting` graph with the cost of travel in minutes (`cppRouting` object).
#'
#' `[5] graph_cppRouting_meters`: the road network structured as a `cppRouting` graph with the cost of travel in meters (`cppRouting` object).
#' @export
#'
#' @examples
#' vegnett_sampledata
#' vegnett_list <- vegnett_to_R(vegnett = vegnett_sampledata,
#'                              year = 2021,
#'                              fromnodeID = "FROMNODEID",
#'                              tonodeID = "TONODEID",
#'                              FT_minutes = "FT_MINUTES",
#'                              TF_minutes = "TF_MINUTES",
#'                              meters = "SHAPE_LENGTH")
#'
#' graph <- vegnett_list[[1]]
#' nodes <- vegnett_list[[2]]
#' edges <- vegnett_list[[3]]
#' graph_cppRouting_minutes <- vegnett_list[[4]]
#' graph_cppRouting_meters <- vegnett_list[[5]]
#'
#' graph
#' nodes
#' head(edges)
#' head(graph_cppRouting_minutes$data)
#' head(graph_cppRouting_minutes$coords)
#' head(graph_cppRouting_minutes$dict)
#' graph_cppRouting_minutes$nbnode
#'
#' head(graph_cppRouting_meters$data)
#' head(graph_cppRouting_meters$coords)
#' head(graph_cppRouting_meters$dict)
#' graph_cppRouting_meters$nbnode
#'
#' @encoding UTF-8
#'
#'

vegnett_to_R <- function(vegnett,
                         crs_out = 25833,
                         year = 2022,
                         fromnodeID = "FROMNODE",
                         tonodeID = "TONODE",
                         FT_minutes = "DRIVETIME_FW",
                         TF_minutes = "DRIVETIME_BW",
                         meters = "SHAPE_LENGTH",
                         turn_restrictions = FALSE,
                         ferry = TRUE) {


  suppressWarnings(
    vegnett <- vegnett %>%
      sf::st_zm(drop = TRUE) %>%
      dplyr::rename_all(toupper) %>%
      sf::st_cast("LINESTRING") %>%
      dplyr::filter(ONEWAY == "TF" & !!rlang::sym(TF_minutes) > 0 |
                      ONEWAY == "FT" & !!rlang::sym(FT_minutes) > 0 |
                      ONEWAY == "B" & !!rlang::sym(FT_minutes) > 0 |
                      ONEWAY == "B" & !!rlang::sym(TF_minutes) > 0)

  )

  rename_geometry <- function(g, name){
    current = attr(g, "sf_column")
    names(g)[names(g)==current] = name
    sf::st_geometry(g)=name
    g
  }

  vegnett <- rename_geometry(vegnett, "geometry")
  sf::st_geometry(vegnett) <- "geometry"

  # Change km/h for ferry edges
  if (is.numeric(ferry)==T){
    vegnett <- vegnett %>%
      dplyr::mutate(km = !!rlang::sym(meters)/1000,
                    hours = !!rlang::sym(FT_minutes)/60,
                    km_h = km/hours,
                    FT_minutes_new = (km/ferry)*60,
                    !!FT_minutes := dplyr::case_when(
                      ROADCLASS == 4 ~ FT_minutes_new,
                      TRUE ~ !!rlang::sym(FT_minutes)
                    ),
                    !!TF_minutes := dplyr::case_when(
                      ROADCLASS == 4 ~ FT_minutes_new,
                      TRUE ~ !!rlang::sym(TF_minutes)
                    )) %>%
      dplyr::select(-km, -hours, -km_h, FT_minutes_new)
  }

  ######################
  ## Data processing ###
  ######################

  # Adding an extra row where the road goes both ways #
  # Creating a subset with values where the road goes both ways (B) and specifies direction from-to (FT) and to-from (TF) #
  B_FT <- vegnett %>%
    dplyr::filter(ONEWAY == "B") %>%
    dplyr::mutate(direction = "B_FT") %>%
    dplyr::filter(!!rlang::sym(FT_minutes) > 0 | !!rlang::sym(TF_minutes) > 0) # Removes edges where FT_MINUTES or TF_MINUTES is missing


  B_TF <- vegnett %>%
    dplyr::filter(ONEWAY == "B") %>%
    dplyr::mutate(direction = "B_TF") %>%
    dplyr::filter(!!rlang::sym(FT_minutes) > 0 | !!rlang::sym(TF_minutes) > 0) # Removes edges where FT_MINUTES or TF_MINUTES is missing


  # Subset with only FT #
  FT <- vegnett %>%
    dplyr::filter(ONEWAY == "FT") %>%
    dplyr::mutate(direction = "FT") %>%
    dplyr::filter(!!rlang::sym(FT_minutes) > 0) # Removes edges where FT_MINUTES is missing

  # Subset with only TF #
  TF <- vegnett %>%
    dplyr::filter(ONEWAY == "TF") %>%
    dplyr::mutate(direction = "TF") %>%
    dplyr::filter(!!rlang::sym(TF_minutes) > 0)  # Removes edges where TF_MINUTES is missing

  # Binding together all the edges #
  edges <- rbind(B_FT, FT, B_TF, TF) %>%
    dplyr::mutate(edgeID = c(1:dplyr::n())) %>% # adding new edge ID
    dplyr::mutate(!!FT_minutes := dplyr::case_when( # specify correct FT_MINUTES for edges that go TF
      direction %in% c("B_TF", "TF") ~ !!rlang::sym(TF_minutes), TRUE ~ !!rlang::sym(FT_minutes)),
      FROMNODEID_new = dplyr::case_when(direction %in% c("B_TF", "TF") ~ !!rlang::sym(tonodeID), TRUE ~ !!rlang::sym(fromnodeID)),
      TONODEID_new = dplyr::case_when(direction %in% c("B_TF", "TF") ~ !!rlang::sym(fromnodeID), TRUE ~ !!rlang::sym(tonodeID))
    )

  # Adding turn restrictions (optional) #
  if (turn_restrictions==TRUE){

    if (year <= 2021){
      vegnett_Edge1FID <- vegnett %>%
        data.frame() %>%
        dplyr::filter(FID %in% as.character(unique(turnrestrictions_geom$Edge1FID))) %>%
        dplyr::select(FID, tidyselect::all_of(fromnodeID), tidyselect::all_of(tonodeID)) %>%
        dplyr::rename(FROMNODEID_1 = !!rlang::sym(fromnodeID),
                      TONODEID_1 = !!rlang::sym(tonodeID))

      vegnett_Edge2FID <- vegnett %>%
        data.frame() %>%
        dplyr::filter(FID %in% as.character(unique(turnrestrictions_geom$Edge2FID))) %>%
        dplyr::select(FID, tidyselect::all_of(fromnodeID), tidyselect::all_of(tonodeID)) %>%
        dplyr::rename(FROMNODEID_2 = !!rlang::sym(fromnodeID),
                      TONODEID_2 = !!rlang::sym(tonodeID))

      turnrestrictions_geom <- turnrestrictions_geom %>%
        dplyr::left_join(vegnett_Edge1FID, by = c("Edge1FID" = "FID")) %>%
        dplyr::left_join(vegnett_Edge2FID, by = c("Edge2FID" = "FID")) %>%
        dplyr::mutate(fromToNode = dplyr::case_when(
          Edge1End == "N" ~ FROMNODEID_1,
          Edge1End == "Y" ~ TONODEID_1,
          TRUE ~ ""),
          toToNode = dplyr::case_when(
            Edge1End == "N" & FROMNODEID_1 == FROMNODEID_2 ~ TONODEID_2,
            Edge1End == "Y" & TONODEID_1 == FROMNODEID_2 ~ TONODEID_2,
            TRUE ~ FROMNODEID_2
          ),
          turn = 1) %>%
        dplyr::select(fromToNode, toToNode, Edge1End, FROMNODEID_1, TONODEID_1, FROMNODEID_2, TONODEID_2)
    }

    turnrestrictions_geom <- turnrestrictions_geom %>%
      dplyr::rename(FROMNODEID = fromToNode,
                    TONODEID = toToNode) %>%
      dplyr::mutate(turn = 1)

    edges <- dplyr::left_join(edges, turnrestrictions_geom, by = c("FROMNODEID_new" = "FROMNODEID", "TONODEID_new" = "TONODEID")) %>%
      dplyr::filter(is.na(turn))
  }

  # Extracting the nodes from the edges and specifies start and end #
  nodes <- edges %>%
    sf::st_coordinates() %>%
    dplyr::as_tibble() %>%
    dplyr::rename(edgeID = L1) %>%
    dplyr::group_by(edgeID) %>%
    dplyr::slice(c(1, dplyr::n())) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(start_end = rep(c('start', 'end'), times = dplyr::n()/2))

  nodes  <- dplyr::left_join(nodes, edges, by = c("edgeID")) %>%
    dplyr::mutate(start_end = dplyr::case_when(
      direction %in% c("B_TF", "TF") & start_end == "start" ~ "end",
      direction %in% c("B_TF", "TF") & start_end == "end" ~ "start", TRUE ~ start_end)) %>%
    dplyr::mutate(xy = paste(.$X, .$Y)) %>% # adding node ID
    dplyr::mutate(xy = factor(xy, levels = unique(xy))) %>%
    dplyr::group_by(xy) %>%
    dplyr::mutate(nodeID = dplyr::cur_group_id()) %>%
    dplyr::ungroup() %>%
    dplyr::select(-xy, -geometry) #

  # Start nodes #
  source_nodes <- nodes %>%
    dplyr::filter(start_end == 'start') %>%
    dplyr::pull(nodeID)

  # End nodes #
  target_nodes <- nodes %>%
    dplyr::filter(start_end == 'end') %>%
    dplyr::pull(nodeID)

  # Creating edges from source_nodes and target_nodes #
  lookup <- c(meters = meters, minutes = FT_minutes) # OBS: legg denne direkte inn i all_of()?
  edges <- edges %>%
    dplyr::mutate(from = source_nodes, to = target_nodes) %>%
    dplyr::rename(tidyselect::all_of(lookup))

  # Extracting distinct nodes with coordinates #
  nodes <- nodes %>%
    dplyr::distinct(nodeID, .keep_all = TRUE) %>%
    dplyr::select(-c(edgeID, start_end)) %>%
    sf::st_as_sf(coords = c('X', 'Y')) %>%
    sf::st_set_crs(sf::st_crs(edges))

  # Creating tbl_graph object of the road network #
  graph <- tidygraph::tbl_graph(nodes = nodes, edges = dplyr::as_tibble(edges), directed = TRUE)

  # Removing loops in the graph #
  graph <- igraph::simplify(graph, remove.loops = TRUE, remove.multiple = FALSE)
  graph <- tidygraph::as_tbl_graph(graph)

  # Extracting new edges (where loops are removed) #
  edges <- graph %>%
    tidygraph::activate(edges) %>%
    data.frame()

  membership <- igraph::components(graph)$membership
  membership <- data.frame(membership)

  nodes <- nodes %>%
    cbind(membership) %>%
    dplyr::select(nodeID, geometry, membership) %>%
    sf::st_set_crs(crs_out)


  ################################
  ## Creating cppRouting graph ###
  ################################

  # Minutes #
  edges_minutes <- edges %>%
    data.frame() %>%
    dplyr::select(from, to, minutes) %>%
    dplyr::rename(weight = minutes) %>%
    dplyr::mutate(from = as.character(from),
                  to = as.character(to))

  # Meters #
  edges_meters <- edges %>%
    data.frame() %>%
    dplyr::select(from, to, meters) %>%
    dplyr::rename(weight = meters) %>%
    dplyr::mutate(from = as.character(from),
                  to = as.character(to))

  node_list_coord <- nodes %>%
    dplyr::mutate(X = unlist(purrr::map(geometry,1)),
                  Y = unlist(purrr::map(geometry,2))) %>%
    data.frame() %>%
    dplyr::select(nodeID, X, Y)

  ### Creating cppRouting graph ###
  graph_cppRouting_minutes <- cppRouting::makegraph(edges_minutes, directed = TRUE, coords = node_list_coord)
  graph_cppRouting_meters <- cppRouting::makegraph(edges_meters, directed = TRUE, coords = node_list_coord)


  return(list(graph,
              nodes,
              edges,
              graph_cppRouting_minutes,
              graph_cppRouting_meters))

}



# globalVariables
utils::globalVariables(c("graph", "edges", "ONEWAY", "km", "hours", ":=", "km_h",
                         "FT_minutes_new", "FID", "fromToNode", "fromToNode", "toToNode", "FROMNODEID_1", "TONODEID_1", "FROMNODEID_2", "TONODEID_2", "turn", "L1", "edgeID", ".", "xy", "geometry",
                         "Edge1End", "start_end", "nodeID", "from", "to", "minutes", "X", "Y", "to_node", "coords_google", "variabel", "from_node", "graph_cppRouting_minutes", "from_nodeID",
                         "coords_google_1", "coords_google_2", "lat"))


# Suppress R CMD check note
#' @importFrom here here
NULL
