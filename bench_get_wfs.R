# benchmark get_wfs
rm(list = ls(envir = globalenv()),
   envir = globalenv()); if(!is.null(dev.list())) dev.off(); gc(); cat(rep("\n", 50))

library(sf)
library(httr2)
library(bench)

shape <- mapedit::drawFeatures() |> st_make_valid()
apikey = "cartovecto"
layer_name = "BDCARTO_BDD_WLD_WGS84G:troncon_route"
filename = NULL
overwrite = FALSE
interactive = FALSE

bbox <- st_bbox(st_transform(shape, 4326))
formated_bbox <- paste(bbox["xmin"], bbox["ymin"], bbox["xmax"], bbox["ymax"],
                       "epsg:4326",
                       sep = ",")

params <- list(
   service = "WFS",
   version = "2.0.0",
   request = "GetFeature",
   outputFormat = "json",
   srsName = "EPSG:4326",
   typeName = layer_name,
   bbox = formated_bbox,
   startindex = 0,
   count = 1000
)

read_sf_method <- function(apikey=apikey, params=params){
   url <- request("https://wxs.ign.fr") %>%
      req_url_path_append(apikey) %>%
      req_url_path_append("geoportail/wfs") %>%
      req_url_query(!!!params)
   res <- read_sf(url$url)
   print("done sf")
}

httr2_method <- function(apikey, params=params){
   request <- request("https://wxs.ign.fr") %>%
      req_url_path_append(apikey) %>%
      req_url_path_append("geoportail/wfs") %>%
      req_user_agent("happign (https://paul-carteron.github.io/happign/)") %>%
      req_url_query(!!!params) %>%
      req_perform() %>%
      resp_body_string() %>%
      read_sf()
   print("done httr2")
}

results = bench::mark(
   iterations = 50, check = FALSE, time_unit = "s",
   httr2_method = httr2_method(apikey=apikey, params=params),
   read_sf_method = read_sf_method(apikey=apikey, params=params)
)
plot(results)
View(results)

# Method for adding filter 
base_url <- "https://wxs.ign.fr/geoportail/wfs"
version <- "2.0.0"
url <- parse_url(base_url)
url$query <- list(service = "WFS",
                  version = "2.0.0",
                  request = "GetFeature",
                  outputFormat = "json",
                  srsName = "EPSG:4326",
                  typeName = layer_name,
                  bbox = formated_bbox,
                  startindex = 0,
                  count = 1000,
                  filter= "dwithin(wijkenbuurten2019:geom, point(119400 480254), 500, meters)"  
)

request <- build_url(url)
url <- url_build(pa)

read_sf()


