# Cómo se generaron los datos de las zonas de aviso

Los ficheros de `db/seeds/` son la fuente de verdad de la aplicación y no se
regeneran: se obtuvieron una sola vez a partir de las publicaciones de AEMET. Este
documento explica de dónde salió cada columna y con qué criterios, para poder
rehacerlo el día que AEMET publique una delimitación de zonas nueva.

La división administrativa del INE, sobre la que esto se apoya, está documentada
aparte en [division-territorial.md](division-territorial.md).

No hay scripts en el repositorio a propósito. Lo que hay aquí es el procedimiento y
los detalles que costaron trabajo descubrir.

| Fichero | Filas | Contenido |
|---|---:|---|
| `weather_territories.csv` | 59 | Provincia o isla, el nivel con el que AEMET agrupa |
| `weather_zones.csv` | 233 | Zonas: 182 terrestres y 51 costeras |
| `weather_zones.geojson` | 233 | Solo código y geometría |
| `region_aemet_codes.csv` | 19 | Código de comunidad de AEMET, por código del INE |
| `island_weather_territories.csv` | 11 | Territorio de AEMET de cada isla del INE |
| `municipality_weather_zones.csv` | 8.132 | Zona de aviso de cada municipio |

Los tres últimos son los puentes con la división del INE. Van aparte y no como una
columna más de los ficheros del INE, para que se vea qué aporta cada fuente: los CSV
del INE no los toca nadie desde aquí, solo sus importadores, que leen la columna extra
del fichero de al lado.

Herramientas necesarias: `python3` con **pyproj** (en un entorno virtual desechable) y
**pdftotext**, de poppler. No hace falta GDAL ni PostGIS.

## 1. Zonas y territorios

**Fuente**: [delimitación de las zonas del Plan Meteoalerta](https://www.aemet.es/documentos/es/eltiempo/prediccion/avisos/plan_meteoalerta/AEMET-meteoalerta-delimitacion-zonas.zip)
(1,8 MB). Contiene dos shapefiles, uno de zonas terrestres (182) y otro de zonas
costeras hasta 20 millas náuticas (51), en **EPSG:32630**.

Atributos del `.dbf`, que traen la jerarquía completa y evitan tener que deducir nada
del código de zona:

| Campo | Contenido |
|---|---|
| `COD_Z` | Código de zona, 6 dígitos, con `C` final en las costeras |
| `NOM_Z` | Nombre de la zona |
| `COD_PROV` | Código de provincia **o isla** de AEMET, 4 dígitos |
| `NOM_PROV` | Nombre de la provincia o isla |
| `COD_CCAA` | Código de comunidad de AEMET, 2 dígitos |
| `NOM_CCAA` | Nombre de la comunidad |

El `.shp` y el `.dbf` se leen con `struct` de la biblioteca estándar; son formatos
binarios sencillos y no hace falta ninguna librería geoespacial.

Ojo: **el nivel `COD_PROV` no son provincias**. 49 de las 52 aparecen tal cual, pero
Illes Balears, Las Palmas y Santa Cruz de Tenerife se parten en islas con códigos que
no son del INE. De ahí que exista `weather_territories` en vez de colgar las zonas
directamente de la provincia.

### La reproyección es la parte delicada

AEMET proyecta **toda España en el huso 30** (meridiano central −3°, banda oficial
−6°…0°). Los extremos reales del fichero:

- `−1.041.071 m` en la costa de El Hierro: 1.541 km al oeste del meridiano central,
  es decir **Δλ ≈ −15,6°**, cinco husos fuera del suyo.
- `+1.164.000 m` en la costa de Menorca: **Δλ ≈ +7,8°**.

Eso tiene dos consecuencias:

1. **Las fórmulas de Snyder/USGS se degradan.** Son series truncadas en potencias de
   Δλ, con error creciendo como Δλ⁸. Error de ida y vuelta medido: Madrid 0,0 m,
   A Coruña 0,0 m, Menorca 0,2 m, **Tenerife 10,8 m**, **El Hierro 22,7 m**. Por eso la
   reproyección se delega en **pyproj** y no se escribe a mano.
2. **El factor de escala se dispara**: 0,99964 en Madrid, 1,02193 en Tenerife,
   **1,02766 en El Hierro**. Una tolerancia en metros aplicada sobre la rejilla sería
   un 2,8 % más laxa en Canarias, y encima de forma anisótropa. De ahí la regla:
   **reproyectar primero y simplificar después**.

Lo que **no** es un problema es el datum: 32630 y 4326 son ambos WGS84, así que es un
cambio de proyección puro, sin transformación de datum ni rejillas NTv2. Si algún día
el fichero llegara en ED50 habría ~200 m de desplazamiento que corregir.

### Simplificación

Douglas-Peucker con tolerancia de **500 m** sobre el terreno, aplicada ya en grados y
corrigiendo la longitud por el coseno de la latitud media del anillo. En un mapa de
España de 1.000 px de ancho, 1 px ≈ 1 km, así que 500 m es media parte de píxel:
visualmente idéntico. Resultado: de 80.999 vértices a 30.176 en total.

Medidas de las zonas terrestres, por si hiciera falta ajustar:

| Tolerancia | Vértices | SVG en línea | Comprimido |
|---|---:|---:|---:|
| Sin simplificar | 80.999 | 1.028 KB | ~257 KB |
| 250 m | 43.232 | 549 KB | ~137 KB |
| **500 m** | **25.099** | **319 KB** | **~80 KB** |
| 1 km | 15.097 | 192 KB | ~48 KB |

**Trampa**: Douglas-Peucker degenera sobre un anillo cerrado, porque el primer y el
último punto coinciden y la recta de referencia tiene longitud cero. Hay que partir el
anillo en dos cadenas abiertas por el punto más lejano al primero, simplificar cada
una y volver a unirlas.

### Anillos y orientación

Un registro de polígono del shapefile es una lista plana de anillos; el sentido de
giro distingue el exterior de los agujeros, y **con el criterio contrario al del
GeoJSON**: en un shapefile el anillo exterior va en sentido horario, y el RFC 7946 lo
quiere antihorario. Hay que invertir todos los anillos al convertir. Las zonas con
varias islas salen como `MultiPolygon`.

Otra confusión fácil: **GeoJSON es `[lng, lat]`** mientras que el `<polygon>` de los
mensajes CAP de AEMET es `"lat,lng"`. Ambos conviven en el código.

## 2. La zona de aviso de cada municipio

**Fuente**: [detalle de municipios por zonas meteorológicas](https://www.aemet.es/documentos/es/eltiempo/prediccion/avisos/plan_meteoalerta/detalle_municipios_zonas_meteorologicas.pdf)
(24,5 MB, 221 páginas). Es la definición oficial de cada zona: el Plan Meteoalerta
define una zona como una agrupación de municipios.

El PDF alterna páginas de mapa con páginas de listado, y se distinguen por el ancho de
página:

- **Mapas**: apaisadas, 842 pt de ancho. Se descartan.
- **Listados**: verticales, 595 pt, a **dos columnas fijas que arrancan en x=53 y
  x=449**.

Leer el PDF en orden de lectura entrelaza las dos columnas y sale un churro. Hay que
extraer con coordenadas y reconstruirlas:

```
pdftotext -bbox-layout detalle_municipios_zonas_meteorologicas.pdf municipios.xml
```

Después, por cada página vertical:

1. Separar las palabras en dos grupos según su `x` sea menor o mayor que 300.
2. Dentro de cada grupo, juntar en una misma línea las palabras cuya `y` cae en la
   misma banda de 3 puntos, y ordenarlas por `x`.
3. Leer la columna izquierda entera de arriba abajo y solo después la derecha.

Una línea que empieza por seis dígitos es una cabecera de zona y se arrastra hasta la
siguiente; por cuatro dígitos, una cabecera de territorio; por cinco dígitos, un
municipio, y el resto de la línea es su nombre.

**Comprobaciones que tiene que pasar la extracción.** Si alguna falla, la
reconstrucción de columnas se ha descuadrado y el resultado no vale:

- **8.124 municipios** y cero códigos duplicados. Son los que había en 2017; los 8
  creados después se añaden a mano, ver más abajo.
- **182 zonas** distintas, que son exactamente las terrestres del shapefile. Las
  costeras no aparecen: un municipio pertenece a una única zona terrestre.
- **59 territorios** distintos.
- Los dos primeros dígitos del código de municipio coinciden con la provincia de su
  territorio, en los 8.124.

## 3. Los tres puentes con la división del INE

Las dos divisiones no coinciden, y todo lo que las relaciona son tres columnas.

**`region_aemet_codes.csv`.** El código de comunidad de AEMET no es el del INE y no se
deriva con una resta:

| INE | AEMET | | INE | AEMET |
|---|---|---|---|---|
| 01–09 Andalucía…Cataluña | 61–69 | | 11–17 Extremadura…La Rioja | 70–76 |
| **10 Comunitat Valenciana** | **77** | | 18–19 Ceuta, Melilla | 78–79 |

Hay desfase de 60 en los tramos de los extremos y de 59 en el del medio, porque AEMET
coloca la Comunitat Valenciana al final de su lista y el INE la pone en el 10. La
correspondencia **se verificó cruzando los conjuntos de provincias**: para cada
comunidad de AEMET, el conjunto de códigos INE de sus provincias coincide exactamente
con el de una comunidad del INE, en los 19 casos. Si hay que rehacerlo, ese es el
método: no fiarse de la tabla, derivarla.

**`island_weather_territories.csv`.** AEMET **fusiona Ibiza y Formentera** en un solo
territorio, así que son 11 islas del INE para 10 territorios. Esta tabla no puede salir
de ninguna fuente, porque es justo donde las dos divisiones no coinciden:

```
071 Formentera -> 6453      351 Fuerteventura -> 6592      381 Gomera, La -> 6594
072 Ibiza      -> 6453      352 Gran Canaria  -> 6590      382 Hierro, El -> 6595
073 Mallorca   -> 6454      353 Lanzarote     -> 6591      383 Palma, La  -> 6593
074 Menorca    -> 6455                                     384 Tenerife   -> 6596
```

También hace falta saber en qué provincia del INE cae cada territorio insular, que
tampoco está en el shapefile:

```
6453 6454 6455 -> 07      6590 6591 6592 -> 35      6593 6594 6595 6596 -> 38
```

**`municipality_weather_zones.csv`.** Sale del PDF de la sección anterior, que es de
2017 y trae 8.124 municipios. Los **8 creados después** se añadieron a mano, heredando
la zona del municipio del que se segregaron; la segregación está en el acuerdo del
Consejo de Gobierno andaluz de 2018 y en el BOE, salvo Usansolo, que se separó de
Galdakao en 2023:

```
11903 San Martín del Tesorillo <- 11021 Jimena de la Frontera   -> 611101
14901 Fuente Carreteros        <- 14030 Fuente Palmera          -> 611402
14902 Guijarrosa, La           <- 14060 Santaella               -> 611402
18077 Fornes                   <- 18020 Arenas del Rey          -> 611801
18916 Torrenueva Costa         <- 18140 Motril                  -> 611804
21902 Zarza-Perrunal, La       <- 21017 Calañas                 -> 612102
41904 Palmar de Troya, El      <- 41095 Utrera                  -> 614102
48916 Usansolo                 <- 48036 Galdakao                -> 754802
```

Es una decisión editorial, no un dato de AEMET: son segregaciones pequeñas y contiguas,
así que heredar la zona del municipio de origen es lo razonable. Si AEMET publica una
delimitación nueva, estas ocho filas dejan de hacer falta.

Ojo con Tharsis: aquel mismo acuerdo lo creó segregándolo de Alosno, pero **no aparece
en la relación del INE de 2026**, así que no hay que darlo de alta.

## 4. Comprobaciones de aceptación

Estas son las que dieron confianza en el resultado. Conviene repetirlas si se rehace.

**Reproyección.** Las coordenadas tienen que caer donde están las cosas de verdad:

- El Hierro entre `−18,156` y `−17,882` de longitud (la isla real va de −18,16 a −17,88).
- Menorca entre `3,792` y `4,329` (la isla real, de 3,79 a 4,33).
- Ninguna zona fuera de `[−19, 5] × [27, 45]`. Las costeras de A Coruña y Lugo llegan a
  44,12°N por las 20 millas mar adentro, así que la cota de latitud no puede ser 44.

**Las dos fuentes de AEMET, cruzadas entre sí.** El listado de municipios (PDF) y la
geometría (shapefile) son independientes, así que tienen que coincidir: para una
muestra de municipios, la zona que les asigna el PDF debe ser la misma que devuelve
`WeatherZone.containing(lat, lng)`. Se comprobó con Madrid, Sevilla, Santa Cruz de
Tenerife, Palma, Ronda, Oviedo, A Coruña y Zaragoza: **8 de 8**.

**El INE contra AEMET.** Pese a los ocho años entre las dos fuentes (el xlsx de islas
es de enero de 2025 y el PDF de agosto de 2017):

- 155 municipios insulares en el INE y 155 en los nuestros, sin sobrantes ni faltantes.
- **Cero** municipios cuya isla del INE no case con el territorio de AEMET de su zona.

**El feed contra la delimitación.** Todas las zonas sobre las que AEMET está avisando
en un momento dado tienen que existir en el shapefile. Al comprobarlo había 111 zonas
con aviso y las 111 estaban.

## 5. Constantes del mapa

`MapProjection` proyecta las zonas a coordenadas SVG con una equirectangular de
paralelo de referencia en los 40°, y traslada Canarias a un recuadro a la izquierda de
la península, a la misma escala. Las constantes se midieron sobre las zonas reales:

```ruby
STANDARD_PARALLEL = 40.0
ORIGIN_LONGITUDE  = -3.7
SCALE             = 100.0                     # píxeles por grado de latitud
CANARY_OFFSET     = [ 212.5, -778.2 ]
VIEW_BOX          = "-938 -427 1601 933"
CANARY_INSET      = { x: -933, y: 238, width: 439, height: 263 }
```

Para recalcularlas con una delimitación nueva: proyectar todas las zonas con la fórmula
de `MapProjection.project` (sin traslación), sacar la envolvente de la península con
Baleares por un lado y la de Canarias por otro, y colocar Canarias con su borde derecho
a 40 px del borde izquierdo de la península y alineada por abajo. El `viewBox` es la
envolvente de las dos con 15 px de margen.

Si al cargar hay zonas fuera del lienzo, `db/seeds/weather_zones.rb` lo avisa por la
salida de error.

## 6. Procedencia y licencia

Zonas de aviso, división territorial y asignación de municipios: Agencia Estatal de
Meteorología (AEMET), Plan Nacional de Predicción y Vigilancia de Fenómenos
Meteorológicos Adversos (Meteoalerta v6), sujetos a la
[nota legal de AEMET](https://www.aemet.es/es/nota_legal).

Obra derivada de BDLJE 2017-02-28 CC-BY [ign.es](http://ign.es) © Instituto Geográfico
Nacional de España.
