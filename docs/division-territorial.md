# Cómo se generaron los datos de la división territorial

Los ficheros de `db/seeds/` son la fuente de verdad de la aplicación y no se
regeneran: se obtuvieron una sola vez a partir de las publicaciones del INE. Este
documento explica de dónde salió cada columna, para poder rehacerlo el día que el
callejero cambie.

No hay scripts en el repositorio a propósito. Lo que hay aquí es el procedimiento y
los detalles que costaron trabajo descubrir.

| Fichero | Filas | Fuente |
|---|---:|---|
| `regions.csv` | 19 | [Relación de comunidades y provincias](https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm) |
| `provinces.csv` | 52 | La misma |
| `islands.csv` | 11 | [`26codislas.xlsx`](https://www.ine.es/daco/daco42/codmun/26codislas.xlsx) |
| `municipalities.csv` | 8.132 | [`26codmun.xlsx`](https://www.ine.es/daco/daco42/codmun/26codmun.xlsx); la isla, del xlsx de islas |

## Comunidades y provincias

La [relación de comunidades y provincias](https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm)
da las dos tablas de una vez: `CODAUTO` (2 dígitos, 01 a 19) con su nombre, y `CPRO`
(2 dígitos, 01 a 52) con el suyo y la comunidad a la que pertenece.

Dos detalles que despistan:

- Son **19 comunidades**, no 17: Ceuta (18) y Melilla (19) son ciudades autónomas y
  aparecen en la misma lista.
- Ceuta y Melilla **tienen dos códigos distintos**: 18 y 19 como ciudad autónoma, y
  51 y 52 como provincia. Aquí se usan los dos, cada uno en su tabla.

Los nombres van en la grafía oficial del INE, que es bilingüe en varias provincias:
`Araba/Álava`, `Alacant/Alicante`, `Castelló/Castellón`, `València/Valencia`,
`A Coruña`, `Ourense`, `Gipuzkoa`, `Bizkaia`.

La columna `time_zone` no es del INE: se añadió a mano porque Canarias va una hora por
detrás del resto del país (`Atlantic/Canary` frente a `Europe/Madrid`) y sin ella no
se puede mostrar ninguna hora en la local de cada sitio.

## Islas

**Fuente**: [`26codislas.xlsx`](https://www.ine.es/daco/daco42/codmun/26codislas.xlsx),
enlazado desde la [página de códigos de islas](https://www.ine.es/daco/daco42/codmun/cod_islas.htm).

Un `.xlsx` es un zip de XML, así que se lee con `zipfile` y `ElementTree` de la
biblioteca estándar de Python: no hace falta ninguna librería de hojas de cálculo. Los
textos están en `xl/sharedStrings.xml`, y las celdas con `t="s"` son índices a esa
tabla en vez de valores literales.

Tiene **tres hojas**, una por provincia insular (07, 35, 38), con columnas
`CPRO, CISLA, ISLA, CMUN, DC, NOMBRE`. De ahí salen las dos cosas a la vez:

- Las **11 islas**: código de tres dígitos (los dos primeros son la provincia) y
  nombre, en la grafía del INE con artículo pospuesto (`Gomera, La`, `Hierro, El`,
  `Palma, La`).
- La **isla de cada uno de los 155 municipios insulares**: el código de municipio es
  `CPRO + CMUN`.

Reparto: Mallorca 53 municipios, Tenerife 31, Gran Canaria 21, La Palma 14, Menorca 8,
Lanzarote 7, Fuerteventura 6, La Gomera 6, Ibiza 5, El Hierro 3 y Formentera 1.

## Municipios

**Fuente**: [`26codmun.xlsx`](https://www.ine.es/daco/daco42/codmun/26codmun.xlsx), la
relación de municipios a 1 de enero de 2026. Se lee igual que el de islas, pero con
**una hoja por provincia** (52) y columnas `CPRO, CMUN, DC, NOMBRE`. El código de
municipio es `CPRO + CMUN`.

Ojo con el lector de xlsx: aquí las filas traen celdas vacías salteadas, así que hay
que colocar cada celda por su atributo `r` (la referencia tipo `C15`) y no por el orden
en que aparecen. Si se hace por orden, las columnas se desplazan y no sale nada.

Son **8.132**, cada uno con su código INE de cinco dígitos, cuyos dos primeros son la
provincia. El fichero se completa con la isla para los 155 insulares; el resto la lleva
vacía.

Los nombres son los oficiales vigentes, que no siempre son los que uno espera:

- Van con el **artículo pospuesto**: `Granjuela, La`, `Oliva, La`, `Palmar de Troya, El`.
- **130 son bilingües con barra**, y el orden es el de la denominación oficial de cada
  municipio, no una regla general: `Alacant/Alicante` pero `Ayala/Aiara`.
- Hay municipios que solo tienen forma local (`Atetz`, `Novetlè`, `Maó`) y otros que
  han pasado a bilingües (`Val de Goñi/Goñerri`, `Juslapeña/Txulapain`).

`normalized_name` no viene de ninguna fuente: se calcula al importar quitando tildes y
pasando a minúsculas, para que el buscador encuentre "Málaga" escribiendo "malaga".

## Comprobaciones de aceptación

Si hay que rehacer los ficheros, esto es lo que tiene que salir:

- 19 comunidades, 52 provincias, 11 islas, 8.132 municipios.
- Cero códigos duplicados en cualquiera de las cuatro tablas.
- Los dos primeros dígitos del código de cada municipio coinciden con su provincia, en
  los 8.124.
- Los dos primeros dígitos del código de cada isla coinciden con su provincia, en las 11.
- Exactamente **155 municipios con isla**, y ninguno fuera de las provincias 07, 35 y 38.
- Cada municipio insular está en una isla de su propia provincia.

## Procedencia y licencia

Códigos y nombres de comunidades, provincias, islas y municipios: Instituto Nacional
de Estadística, CC BY 4.0.
