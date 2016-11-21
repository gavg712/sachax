library(raster)
library(sp)
library(ggplot2)
library(rasterVis)
library(RColorBrewer)
library(geoR)
library(gstat)
library(rgdal)
library(foreach)
library(doMC)

##### FUNCIONES #####
# Preparacion de datos
preparingData <- function(table, CoordX = "Longitud", CoordY = "Latitud", VarCols = 4:15,
                          CRS = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs", 
                          rasDEM = dem){
  if(class(table) == "data.frame") {
    coordinates(table) <- c(CoordX, CoordY)
  }
  
  proj4string(table) <- CRS
  
  if(proj4string(table) != proj4string(dem)){
    table <- spTransform(table, CRSobj = proj4string(dem))
  }
  
  table <- intersect(table, dem)
  table$Altitud <- extract(dem, table)
  AltD <- round(mean(table$Altitud, na.rm=T)/100)*100
  
  for (i in names(table)[VarCols]){
    fit <- lm(paste(i, "~ Altitud"), data=table)
    Ro <- summary(fit)[[4]][2]
    table@data[,paste0(i, "x")] <- table@data[,i] - (Ro * (AltD - table@data[,"Altitud"]))
  }
  return(table)
}

friesMeteo <- function(points=table, n, VarCols=4:15, dem=dem, AltD=AltD){
  require(raster)
  require(sp)
  require(geoR)
  require(gstat)
  require(rgdal)
  Ro <- svg <- fitsvg <- mod <- formul2 <- crossval <- list()
  rmsd <- map <- Tdet <- result <- Valid <- fitValid <- list()
  i = n
  msk <- reclassify(dem, matrix(c(-Inf, 0, NA, 0,+Inf, TRUE), byrow = TRUE))
  grd <- as(msk, "SpatialGridDataFrame")
  distancias <- dist(coordinates(table))
  VarCols = names(table)[VarCols]
  Ro[[i]] = summary(lm(paste(VarCols[i], "~ Altitud"), data=table))[[4]][2]
  svg[[i]] <- variog(coords = coordinates(points), 
                     data = points[[paste0(VarCols[i], "x")]],
                     breaks = "default")
  fitsvg[[i]] <- variofit(svg[[i]], ini = c(1, 100), nugget = 0.1,
                          cov.model = 'gaussian')
  mod[[i]] <- vgm(psill = fitsvg[[i]]$cov.pars[2], model = "Gau",
                  range = fitsvg[[i]]$cov.pars[1], nugget = fitsvg[[i]]$nugget)
  formul2[[i]] <- formula(paste0(VarCols[i], "x ~ 1"))
  crossval[[i]] <- krige.cv(formula = formul2[[i]], locations = points,
                            model = mod[[i]])
  rmsd[[i]] <- sqrt(mean(crossval[[i]]$residual ^ 2))
  map[[i]] <- krige(formula = formul2[[i]], locations = points,
                    model = mod[[i]], newdata = grd)
  Tdet[[i]] <- as(map[[i]], "RasterLayer")
  result[[i]] <- (Tdet[[i]] + (Ro[[i]] * (dem - AltD))) * msk
  writeRaster(result[[i]], filename = paste0("T", VarCols[i], ".pdf"),
    format = "GTiff", overwrite = TRUE)
  return(list("Validacion Cruzada" = crossval, "Error Cuadrado Medio" = rmsd))
}

system.time({
dem <- raster("datos/dem90.tif")
table <- read.table("datos/Tmx.csv", sep=",", header = T)
table <- preparingData(table = table)
AltD <- round(mean(table$Altitud, na.rm=T)/100)*100
registerDoMC(detectCores()-1)
foreach(n=1:12) %dopar% friesMeteo(points=table, n, VarCols=4:15, dem=dem, AltD=AltD)
})
