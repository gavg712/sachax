####### download MODIS data #######
modisDownload <- function(productName = c("MOD13Q1"),
                          version = 6,
                          H = c(10),
                          V = c(9),
                          startDate = "2013-01-01",
                          endDate = "2013-03-31",
                          timeStep = "16 days",
                          numScenes = 23, 
                          outputDir = getwd(),
                          credentials = c("user", "pass")){
  require(RCurl)
  require(rvest)
  require(stringr)
  require(lubridate)
  require(gdalUtils)
  
  #Funcion comparar productos
  productos <- function(productName, version){
    prod = substring(productName, 1, 3)
    url = paste0("http://e4ftl01.cr.usgs.gov/", 
                 switch(prod, "MOD" = "MOLT/",
                        "MYD" = "MOLA/", "MCD" = "MOTA/"))
    prods <- read_html(url) %>% 
      html_nodes(xpath = "//body//pre//a") %>% 
      html_text()
    prods <- prods[grep(productName, prods)]
    prods <- prods[grep(sprintf("%02d", version), prods)]
    return(paste0(url,prods))
  }
  
  # directorios de productos
  productURL = NULL
  for(product in productName){
    for(ver in version){
      if(length(productos(product, version))==0){
        print("There aren't a products like this version")
      } else {
        productURL <- c(productURL, productos(product, ver))
      }
    }
  }
  
  # Directorio local de salida
  if(grepl(x = outputDir, pattern = "/$")){ 
    outputDir = gsub(replacement = "", x = outputDir, pattern = "/$")}
  outputDir = paste0(outputDir, "/")
  
  # tiles definidas por H y V
  HV = expand.grid(H, V)
  tiles = paste0("h",sprintf("%02d", HV[,1]),"v",sprintf("%02d", HV[,2]))
  
  #Fechas disponibles en el rango especificado
  startDate = as.Date(startDate)
  Y = year(startDate)
  dates = as.Date(paste(Y,seq(1,366,1), sep="-"),"%Y-%j")
  if(is.null(endDate)){
    startDate = dates[dates >= startDate][1]
    dates = seq(startDate, by = timeStep, length.out = numScenes)
  } else {
    endDate = as.Date(endDate)
    startDate = dates[dates >= startDate][1]
    dates = seq(startDate, endDate, by = timeStep)
  }
  dates = format(dates,"%Y.%m.%d/")
  
  # funcion listar directorios por fecha
  listdirMODIS <- function(productURL, dates){
    pURL <- NULL
    folders <- read_html(productURL) %>% html_nodes(xpath = "//body//pre//a") %>% html_text
    paths=paste0(pURL, folders[unlist(lapply(dates,FUN = grep, x = folders))])
    return(paste0(productURL,paths))
  }
  
  #Lista de directorios
  paths <- NULL
  for(url in productURL) paths <- c(paths, listdirMODIS(url, dates))
  
  #lista de ficheros a descargar
  for (path in paths){
    txt <- read_html(path) %>% 
      html_nodes(xpath = "//body//pre//a") %>% html_text()
    files <- paste0(path, txt[sapply(tiles,FUN = grep, x = txt) %>% as.vector()])
    
    # descarga de ficheros 
    for(file in files){
      try(download.file(url = file, 
                        destfile = paste0(outputDir, 
                                          gsub(pattern = path, replacement = "", x = file)), 
                        method = "wget", 
                        extra = paste("-c --user ", credentials[1], 
                                      "--password ", credentials[2]))
      )
    }
  }
}

modisReproj <- function(hdf, 
                        indexLayers = c(1,12), 
                        t_srs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs",
                        outputDir = getwd(),
                        ...){
  require(raster)
  require(gdalUtils)
  # Directorio local de salida
  if(grepl(x = outputDir, pattern = "/$")){ 
    outputDir = gsub(replacement = "", x = outputDir, pattern = "/$")}
  outputDir = paste0(outputDir, "/")
  modisSRS <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
  sds <- get_subdatasets(hdf)
  for(s in indexLayers){
    gdalwarp(sds[s], 
             dstfile = paste0(outputDir, hdf,".",s, ".tif"), 
             s_srs = modisSRS, 
             t_srs= t_srs, output_Raster = T,...)
  }
}