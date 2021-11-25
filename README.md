
<a href="https://github.com/PopulateTools/gobierto"><img src="https://gobierto.es/assets/logo_gobierto.png" width="250" height="auto"></a>

Estás viendo un fork del proyecto [Gobierto · Comparador de presupuestos](https://github.com/PopulateTools/gobierto-comparador-presupuestos) para la Generalitat de Catalunya. El site está funcionando en http://pressupostosmunicipals.transparenciacatalunya.cat.

# Gobierto · Comparador de presupuestos

El comparador de presupuestos de Gobierto es una herramienta de exploración, comparación y visualización de presupuestos municipales (u otros niveles administrativos). Utilizamos datos abiertos del Consorci d'Administració Oberta de Catalunya (AOC) (ver datos del [presupuesto](https://analisi.transparenciacatalunya.cat/d/4g9s-gzp6) y de la [ejecución](https://analisi.transparenciacatalunya.cat/d/e7ah-kha8)) y del [INE](http://ine.es).

**Gobierto comparador de presupuestos** es una herramienta de exploración, comparación y visualización de los presupuestos municipales. Utilizamos datos abiertos del Ministerio de Hacienda (tenemos un [repositorio](https://github.com/PopulateTools/gobierto-budgets-data) donde publicamos los datos ya limpios y procesados) y del [INE](http://ine.es).

Puedes ver una instancia de este proyecto funcionando en [https://presupuestos.gobierto.es](https://presupuestos.gobierto.es).

Gobierto es un proyecto abierto de [Populate](http://populate.tools), un estudio que diseña desde Madrid productos digitales alrededor de la Participación Ciudadana. Además de trabajar en Gobierto, también ofrecemos servicios en torno a datos abiertos, periodismo de datos, sostenibilidad, etc.

* #todo Por qué Gobierto y nuestra filosofía de Diseño

Más información:

* Website de Gobierto: [gobierto.es](http://gobierto.es)
* Blog: [gobierto.es/blog](http://gobierto.es/blog)

## Arquitectura de la aplicación

La aplicación está escrita en Ruby y usa el framework Ruby on Rails. Para la Base de Datos usa PostgreSQL y también usa ElasticSearch para almacenar toda la información de presupuestos y otros datos de terceros.

## Desarrollo

### Requerimientos de Software

- Git
- Ruby 2.7.4
- Rubygems
- PostgreSQL
- Elastic Search
- Pow or another subdomains tool

### Prepara la base de datos y el archivo secrets.yml

Una vez tengas PostgreSQL corriendo y hayas clonado este repo, haz lo siguiente en el terminal:

```
$ git clone git@github.com:PopulateTools/gobierto-comparador-presupuestos.git
$ cd gobierto-comparador-presupuestos
$ cp config/database.yml.example config/database.yml
$ cp config/secrets.yml.example config/secrets.yml
$ cp .env.example .env
$ ln -s .env .rbenv-vars # if you use Rbenv
$ bundle install
$ bin/rails db:setup
```

### Monta una instancia de Elastic Search

Aquí puedes ver [cómo](https://www.elastic.co/guide/en/elasticsearch/guide/current/running-elasticsearch.html)

Una vez esté corriendo, asegúrate de configurar la URL correcta para tu instancia de Elastic Search en el archivo `config/secrets.yml` bajo la clave `elastic_url`

### Carga algunos datos

Si simplemente quieres cargar unos cuantos datos para empezar a trabajar, haz lo siguiente:

1. Clona [este repo](https://github.com/PopulateTools/gobierto-budgets-data) y sigue las instrucciones para que tengas todos los datos de los municipios españoles disponibles para importar.
2. Después, ejecuta `bin/rake gobierto_budgets:setup:sample_site`

Esto cargará los datos para Madrid, Barcelona y Bilbao y activará el Site de Municipio de prueba para Madrigal de la vera.

Alternativamente, aquí puedes ver [cómo cargar los datos](https://github.com/PopulateTools/gobierto/wiki/Loading-Gobierto-Data) para más municipios de España.

### Crea el subdominio y lanza la aplicación

Cuando trabajes en local, al servidor de aplicaciones se debería acceder a través del dominio `.gobierto.dev`. Para configurar esto en tu entorno, la manera más sencilla es usando [POW](http://pow.cx/). Para instalarlo:

```
curl get.pow.cx | sh
```

Después, configura el servidor así:

```
cd ~/.pow
ln -s DIRECTORIO/gobierto-comparador-presupuestos gobierto-comparador-presupuestos
```

Y simplemente navega a http://gobierto-comparador-presupuestos.test/ para cargar la aplicación.

### Montando el site para una sóla entidad pública

Ejecuta lo siguiente:

```
bin/rake gobierto_budgets:setup:create_site['<Place ID>','<URL OF INSTITUTION>']
```
Donde `<Place ID>` es el ID del municipio que quieres montar y `<URL OF INSTITUTION>` es la URL opcional del posible site oficial de ese municipio.

## Trae tus propios datos

ToDo: Documentar el formato de datos para importar

## Contribuir

Claro! Mira [cómo contribuir](https://github.com/PopulateTools/gobierto-comparador-presupuestos/blob/master/CONTRIBUTING_ES.md)

### Librerías/gemas

* Gemas: Echa un vistazo a [Gemfile](https://github.com/PopulateTools/gobierto-comparador-presupuestos/blob/master/Gemfile) para una referencia completa
* Otras (CSS, JS): #ToDo (explora el código de momento;)

## Licencia

Software publicado bajo la licencia de código abierto AFFERO GPL v3 (ver [LICENSE-AGPLv3.txt](https://github.com/PopulateTools/gobierto-comparador-presupuestos/blob/master/LICENSE-AGPLv3.txt))
