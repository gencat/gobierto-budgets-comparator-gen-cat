
![Gobierto](https://gobierto.es/assets/logo_gobierto.png)

Este README está disponible [en Español](README.md)

This is a fork of [Gobierto budgets comparator](https://github.com/PopulateTools/gobierto-comparador-presupuestos) for Generalitat de Catalunya. Check the live site at: http://pressupostosmunicipals.transparenciacatalunya.cat.

# Gobierto budgets comparator


**Gobierto budgets comparator** is a budgets comparison tool to enable citizens to explore, visualize, compare and contextualize the budgets of multiple municipalities/public bodies at the same time (such as those of a given Province, Autonomous Region or Country). We use data from the Consorci d'Administració Oberta de Catalunya (AOC) (view [budgeting data](https://analisi.transparenciacatalunya.cat/d/4g9s-gzp6) and [execution data](https://analisi.transparenciacatalunya.cat/d/e7ah-kha8)) and from the [INE](http://ine.es).

Gobierto is being built in the open by [Populate](http://populate.tools), a product design studio around civic engagement based in Madrid, Spain. We provide commercial services around data journalism, news products, open data... and Gobierto, of course ;)

* #todo Why we build Gobierto and our design philosophy

More info:

* Main site (spanish): [gobierto.es](http://gobierto.es)
* Blog (spanish): [gobierto.es/blog](http://gobierto.es/blog)

## Feature requests

File an [issue](https://github.com/PopulateTools/gobierto-comparador-presupuestos/issues).

## Application architecture

The application is written in the Ruby programming language and uses the Ruby on Rails framework. In the database layer uses Postgres. Also, it uses an external Elastic Search to store and process all the budgets and third-party data.

## Development

### Software Requirements

- Git
- Ruby 2.7.4
- Rubygems
- PostgreSQL
- Elastic Search
- Pow or another subdomains tool

### Setup the database and the secrets file

Once you have PostgreSQL running and have cloned the repository, do the following:

```
$ cd gobierto
$ cp config/database.yml.example config/database.yml
$ cp config/secrets.yml.example config/secrets.yml
$ bundle install
$ rake db:setup
```

### Setup Elastic Search

See [how](https://www.elastic.co/guide/en/elasticsearch/guide/current/running-elasticsearch.html)

Once it is running, make sure you enter the correct URL for your Elastic Search instance in `config/secrets.yml` under the `elastic_url` key

### Load some data

If you want to import some basic data to get started, do the following:

1. Clone this repo and follow the instructions in order to have all of the Spanish Budgetary data available to load.
2. Run `bin/rake gobierto_budgets:setup:sample_site`

This will load data for Madrid, Barcelona and Bilbao and setup a site for Madrigal de la Vera.

Alternatively, learn [how to load the data](https://github.com/PopulateTools/gobierto/wiki/Loading-Gobierto-Data) for all or some municipalities in Spain.

### Setup subdomain and start the application

When working locally, the application server should be queried through the top-level domain `.gobierto.dev`. To configure this host in your computer, the simplest way is through POW [POW](http://pow.cx/). To install:

```
curl get.pow.cx | sh
```

Then, configure the host like this:

```
cd ~/.pow
ln -s DIRECTORY/gobierto gobierto
```

Then just browse to http://presupuestos.gobierto.dev/ and the app should load.

### Setting up the site for a single public entity

Run:

```
bin/rake gobierto_budgets:setup:create_site['<Place ID>','<URL OF INSTITUTION>']
```
Where `<Place ID>` is the ID of the municipality you wish to setup the site for and the optional `<URL OF INSTITUTION>` is the URL for other municipality's website, if any.

## Bring your own data

ToDo: Document the format of budget data needed to import it.

## Contributing

Yes! See [contributing](https://github.com/PopulateTools/gobierto-comparador-presupuestos/blob/master/CONTRIBUTING_EN.md)

### Libraries/gems being used

* Gems: See [Gemfile](https://github.com/PopulateTools/gobierto-comparador-presupuestos/blob/master/Gemfile) for complete reference
* Other (CSS, JS): #ToDo (browse source meanwhile ;)

## License

Code published under AFFERO GPL v3 (see [LICENSE-AGPLv3.txt](https://github.com/PopulateTools/gobierto-comparador-presupuestos/blob/master/LICENSE-AGPLv3.txt))
