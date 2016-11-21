# Ayuda Sript downloadModis.R
***
## Función modisDownload():

Función para descargar productos modis desde el Data Pool de LA-DAAC de la NASA. Requiere un usuario y contraseña registrados y autorizados para [DataPool (lpdaac)](https://urs.earthdata.nasa.gov/users/new)

### Argumentos: 

- **productName**: Vector de caracteres, se requiere especificar los nombres de los productos a descargar. Por defecto está definido c("MOD13Q1"). Los nombres de los productos modis se pueden obtener de la tabla de productos Modis en este sitio https://lpdaac.usgs.gov/dataset_discovery/modis/modis_products_table.
- **version**: Vector de enteros se requiere especificar la versión del producto a descargar.
- **H**: Vector de enteros. Son los índices horizontales del tile a descargar. Por defecto se especifican c(8,9,10) que corresponden al territorio de Ecuador (continental e insular).
- **V**: Vector de enteros. Son los índices verticales del tile a descargar. Por defecto se especifican c(8,9) que corresponden al territorio de Ecuador (continental e insular).
- **startDate**: Caracter. La fecha de inicio del período a descargar, en formato estándar "%Y-%m-%d". Por defecto se encuentra definido "2013-01-01".
- **endDate**: Caracter Opcional. La fecha de inicio del período a descargar, en formato estándar "%Y-%m-%d". Por defecto se encuentra definido NULL. Si es NULL, el listado de escenas se seleccionará en función del número de escenas requeridas
- **numScenes**:      Entero. Corresponde al número de escenas contadas a partir de la fecha especificada en "startDate". Por defecto se  estable 23, que corresponden a un año completo.
- **outputDir**:      Caracter. Directorio donde se guardarán los ficheros. Si no se especifica tomará el directorio de trabajo usando la función getwd().
- **credentials**:    Vector de 2 caracteres. Obligatorio. Son el usuario y  contraseña que se ingresaron en el momento de registrarse en https://urs.earthdata.nasa.gov/users/new. Por defecto se especifica un vector de ejemplo, que generará un error porque no existen en el sistema de usuarios de EarthData. El vector debe se debe construir de la siguiente forma: c("username", "pass"))

***

## Función modisReproj(): 

Función para reproyectar productos MODIS a otro sistema de referencia de coordenadas (CRS). 

### Argumentos:

 - **hdf**: Caracter. Nombre del fichero HDF descargado. Si el HDF no se encuentra en el directorio de trabajo, se requiere especificar la ruta completa o relativa. Ej. "/ruta/al/fichero.hdf".
- **indexLayers**: Vector de enteros. Corresponde a los índices de las capas contenidas en el fichero hdf. Por defecto se define c(1,12) que corresponden a la capa NDVI y Quality del producto de Indices de Vegetación. 
- **t_srs**: Caracter. SRC de salida de los ficheros en algún formato que reconozca GDAL, de preferencia en formato PROJ4. Por defecto se especifica el SRC Latitud/Longitud ("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"). Más SRC y su estructura PROJ4 se puede encontrar en http://spatialreference.org.
- **outputDir**: Caracter. Ruta al directorio de salida de los ficheros tif. Si no se especifica asumirá la ruta de trabajo usando la función getwd().
- **...**: Otros argumentos de la función gdalwarp() del paquete gdalUtils. 
