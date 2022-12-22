# benchmark raster download

apikey = "altimetrie"
layer_name = "ELEVATION.ELEVATIONGRIDCOVERAGE.HIGHRES"
resolution = 25
crs = 2154
overwrite = FALSE
version = "1.3.0"
styles = ""
interactive = FALSE

library(sf)
library(dplyr)
library(terra)
library(microbenchmark)

shape <- mapedit::drawFeatures()
shape <- st_make_valid(shape) %>% st_transform(st_crs(crs))
grid_for_shp <- grid(shape,resolution,crs)
urls <- construct_urls(grid_for_shp,apikey,version,layer_name,styles,crs,resolution)[1:5]

old_method <- function(urls){
   filename <- tempfile(fileext = ".tif")
   default_gdal_skip <- Sys.getenv("GDAL_SKIP")
   default_gdal_http_unsafessl <- Sys.getenv("GDAL_HTTP_UNSAFESSL")
   Sys.setenv(GDAL_SKIP = "DODS")
   Sys.setenv(GDAL_HTTP_UNSAFESSL = "YES")
   on.exit(Sys.setenv(GDAL_SKIP = default_gdal_skip))
   on.exit(Sys.setenv(GDAL_HTTP_UNSAFESSL = default_gdal_http_unsafessl))
   
   tiles_list <- NULL
   for (i in seq_along(urls)) {
      message(sprintf("%1.f/%1.f downloading...", i, length(urls)))
      
      tmp <- tempfile(fileext = ".tif")
      
      # New way which allow to set crs and it also faster
      gdal_utils(util = "translate",
                 source = urls[i],
                 destination = tmp,
                 options = c("-a_srs", st_crs(4326)$input))
      
      tiles_list <- c(tiles_list, tmp)
   }
   
   tiles_list <- normalizePath(tiles_list)
   writeRaster(vrt(tiles_list, overwrite = TRUE), filename, progress = 1, overwrite=TRUE)
   res <- rast(filename)
}
old_method_with_warp <- function(urls){
   filename <- tempfile(fileext = ".tif")
   default_gdal_skip <- Sys.getenv("GDAL_SKIP")
   default_gdal_http_unsafessl <- Sys.getenv("GDAL_HTTP_UNSAFESSL")
   Sys.setenv(GDAL_SKIP = "DODS")
   Sys.setenv(GDAL_HTTP_UNSAFESSL = "YES")
   on.exit(Sys.setenv(GDAL_SKIP = default_gdal_skip))
   on.exit(Sys.setenv(GDAL_HTTP_UNSAFESSL = default_gdal_http_unsafessl))
   
   tiles_list <- NULL
   for (i in seq_along(urls)) {
      message(sprintf("%1.f/%1.f downloading...", i, length(urls)))
      
      tmp <- tempfile(fileext = ".tif")
      
      # New way which allow to set crs and it also faster
      gdal_utils(util = "translate",
                 source = urls[i],
                 destination = tmp,
                 options = c("-a_srs", st_crs(2154)$input))
      
      tiles_list <- c(tiles_list, tmp)
   }
   
   gdal_utils(util = "warp",
              source = normalizePath(tiles_list),
              destination = filename,
              options = c("-t_srs", st_crs(2154)$input))
   res <- rast(filename)
}
terra_method <- function(urls){
   filename <- tempfile(fileext = ".tif")
   writeRaster(vrt(urls, options = c("-a_srs", st_crs(4326)$input)),
               filename,
               progress = 1,
               overwrite = TRUE)
   res <- rast(filename)
} # Functionnel, mais double le temps
gdal_method <- function(urls){
   filename <- tempfile(fileext = ".tif")
   gdal_utils(util = "warp",
              source = urls,
              destination = filename,
              options = c("-t_srs", st_crs(2154)$input))
   res <- rast(filename)
} # Functionnel, mais il manque une bar de progression
gdalvrt_method <- function(urls){
   tmp <- tempfile(fileext = ".vrt")
   filename <- tempfile(fileext = ".tif")
   
   gdal_utils(
      util = "buildvrt",
      source = urls,
      destination = tmp)

   gdal_utils(
      util = "translate",
      source = tmp,
      destination = filename)
   
   res <- rast(filename)

} # Functionnel, mais double le temps

res <- microbenchmark::microbenchmark(
   times = 10,
   old_method(urls),
   old_method_with_warp(urls),
   terra_method(urls),
   gdal_method(urls),
   gdalvrt_method(urls)
)

print(res)
plot(res)
