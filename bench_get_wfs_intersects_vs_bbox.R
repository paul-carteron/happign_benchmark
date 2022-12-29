library(happign)
library(sf)
library(bench)

apikey <- "parcellaire"
layer_name <- "CADASTRALPARCELS.PARCELLAIRE_EXPRESS:parcelle"
borders <- get_apicarto_commune("56031")

intersects <- function(borders, apikey, layer_name){
   print("intersects...")
   res <- get_wfs(shape = borders,
                          apikey = apikey,
                          layer_name = layer_name,
                          spatial_filter = "intersects")
   print("intersects done")
   return(res)
}

bbox <- function(borders, apikey, layer_name){
   print("bbox...")
  res <- get_wfs(shape = borders,
           apikey = apikey,
           layer_name = layer_name,
           spatial_filter = "bbox") |> 
      st_transform(st_crs(borders)) |> 
      st_filter(borders, .predicate = st_intersects)
  print("bbox done")
  return(res)
}

results = bench::mark(
   iterations = 20, check = FALSE, time_unit = "s",
   bbox = bbox(borders=borders, apikey=apikey, layer_name=layer_name),
   intersects = intersects(borders=borders, apikey=apikey, layer_name=layer_name)
)
