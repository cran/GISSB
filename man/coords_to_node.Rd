% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/coords_to_node.R
\encoding{UTF-8}
\name{coords_to_node}
\alias{coords_to_node}
\title{Connect coordinates to the nearest nodes in the road network}
\usage{
coords_to_node(
  coords,
  nodes_object = nodes,
  edges_object = edges,
  direction = "from",
  ID_col = "ID",
  crs_out = 25833,
  knn = 1,
  membership = FALSE
)
}
\arguments{
\item{coords}{An \code{sf} object with the coordinates that should be connected to the road network.}

\item{nodes_object}{An \code{sf} object with the nodes of the road network. This can be created with the function \code{\link[=vegnett_to_R]{vegnett_to_R()}}.}

\item{edges_object}{A data frame with the edges of the road network. This can be created with the function \code{\link[=vegnett_to_R]{vegnett_to_R()}}.}

\item{direction}{Character vector with \code{from} if the points should be from nodes or \code{to} if the points should be to nodes.}

\item{ID_col}{Character vector with the name of the ID column. Default value is set to “ID”.}

\item{crs_out}{Numeric vector for the chosen coordinate reference system (CRS).}

\item{knn}{Numeric vector with the chosen number of nodes that should be returned for each of the coordinates. If \code{knn = 1} only the nearest nodes to the chosen coordinates will be returned. If \code{knn = 2} the two nearest nodes will be returned etc.}

\item{membership}{Logical. If \code{TRUE} the search for nodes is limited to nodes that belong to a road network that is connected either to the from or to nodes (only possible for either from or to). E.g. if you only want to search for from nodes that belong to the same road network as the to nodes, membership is set to \code{FALSE} in the search for to nodes and \code{membership = TRUE} for the from nodes (in that order).}
}
\value{
An object (\code{data.frame}) with the following columns; \code{from_nodeID}/\code{to_nodeID}, \code{membership_from_node}/\code{membership_to_node}, \code{coords_google_from_node}/\code{coords_google_to_node}, \code{knn_from_node}/\code{knn_to_node}, and \code{ID}.
}
\description{
The function \code{coords_to_node} can be used to find the nearest nodes in the Norwegian road network (in meters) for chosen coordinates.
}
\details{
Before the function can be used, the nodes of the road network must be converted to an \code{sf} object that is called \code{nodes} (or another name supplied to the \code{nodes_object} argument). This can be done with the function \code{\link[=vegnett_to_R]{vegnett_to_R()}}.
}
\examples{
coords <- address_to_coords(zip_code = "0185", address = "Schweigaards gate 10")
coords_to_node(coords = coords,
               direction = "from",
               nodes_object = nodes_sampledata,
               edges_object = edges_sampledata)

}
