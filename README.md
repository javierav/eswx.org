# eswx.org

Red de estaciones meteorológicas automáticas personales y profesionales en tiempo real.


## Licencia

Copyright (c) 2026 Javier Aranda. Publicado bajo la licencia [AGPLv3](LICENSE).

## División territorial

Se guarda la división administrativa de España según el INE: `Region` (01-19,
comunidades y ciudades autónomas), `Province` (01-52), `Island` (071-384, solo Baleares
y Canarias) y `Municipality` (8.124, con su isla cuando la tiene).

Cada fuente vive en `db/seeds/` como un CSV con su importador del mismo nombre al
lado, y los carga `db/seeds.rb` en orden, así que `db:setup`, `db:reset` y `bin/setup`
los dejan listos:

    bin/rails db:reset          # recrea la base y carga los datos de referencia
    bin/rails db:seed           # solo recarga los datos, es idempotente

Los CSV se obtuvieron una sola vez de las tablas del INE. A partir de aquí son la
fuente y no se regeneran; el procedimiento está en
[docs/division-territorial.md](docs/division-territorial.md).

### Procedencia y licencia de los datos

Códigos y nombres de comunidades, provincias, islas y municipios: Instituto Nacional
de Estadística, CC BY 4.0.
