$(document).on('turbolinks:load', function() {

  var deckgl
  var geojsonLayer
  var CUSTOM_DOMAIN
  new SlimSelect({
    select: '#municipalities-flyTO',
    placeholder: 'Introduce un municipio'
  })

  var minValue
  var maxValue
  var spinner = document.getElementById('overlay')
  var mapMunicipalities
  var dataTOPOJSON = "https://gist.githubusercontent.com/jorgeatgu/dcb73825b02af45250c4dfa66aa0f94f/raw/86098e0372670238b03ccb46f7d9454bdc9f9d7b/municipalities_topojson.json";
  var dataMunicipalities = "https://datos.gobierto.es/api/v1/data/data.csv?sql=SELECT+*+FROM+municipios"
  var endPoint = "https://datos.gobierto.es/api/v1/data/data.csv?sql="
  var indicator = 'gasto_por_habitante'
  var year = document.getElementsByTagName('body')[0].getAttribute('data-year')
  var queryData = "SELECT+".concat(indicator, "+,place_id+FROM+indicadores_presupuestos_municipales+WHERE+year=").concat(year, "AND+").concat(indicator, "+IS+NOT+NULL");

  var urlData = "".concat(endPoint).concat(queryData);

  var indicators = document.querySelectorAll('[data-indicator]')

  var indicatorsValue = {
    gasto_por_habitante: {
      name: I18n.t('gobierto_budgets.pages.map.expense_per_inhabitant'),
      unit: '€/hab',
    },
    gasto_total: {
      name: I18n.t('gobierto_budgets.pages.map.expense'),
      unit: '€',
    },
    planned_vs_executed: {
      name: I18n.t('gobierto_budgets.pages.map.planned_vs_executed'),
      unit: '%',
    },
    debt: {
      name: I18n.t('gobierto_budgets.pages.map.debt'),
      unit: '€',
    },
    population: {
      name: I18n.t('gobierto_budgets.pages.map.population'),
      unit: ' ' + I18n.t('gobierto_budgets.pages.map.people'),
    }
  };

  var completeIndicator = indicatorsValue.gasto_por_habitante.unit
  var tooltipString = indicatorsValue.gasto_por_habitante.name

  indicators.forEach(
    function(indicator) {
      indicator.addEventListener("click", loadIndicators);
    }
  );

  var CHOROPLET_SCALE = [
    [255, 255, 201],
    [192, 229, 174],
    [117, 198, 179],
    [59, 173, 187],
    [30, 134, 181],
    [31, 83, 155],
    [14, 39, 118]
  ]

  var INITIAL_VIEW_STATE = {
    latitude: 40.416775,
    longitude: -3.703790,
    zoom: 5,
    minZoom: 5,
    maxZoom: 8
  };

  deckgl = new deck.Deck({
    canvas: 'map',
    initialViewState: INITIAL_VIEW_STATE,
    controller: true,
    getTooltip: getTooltip,
    onClick: onClick,
    onLoad: onLoad,
    onViewStateChange: function onViewStateChange(_ref) {
      var viewState = _ref.viewState;
      return deckgl.setProps({
        viewState: viewState
      });
    }
  });

  function onClick(info, event) {
    var municipality = info.object.properties.name
    var replaced = municipality.replace(/ /g, '-');
    window.location.href = "/places/" + accentsTidy(replaced) + "/" + year;
  }

  //Replace characters from the names of municipalities to build URL's
  accentsTidy = function(s){
    var r = s.toLowerCase();
    r = r.replace(/ /g, '-');
    r = r.replace(new RegExp("[àáâãäå]", 'g'),"a");
    r = r.replace(new RegExp("æ", 'g'),"ae");
    r = r.replace(new RegExp("ç", 'g'),"c");
    r = r.replace(new RegExp("[èéêë]", 'g'),"e");
    r = r.replace(new RegExp("[ìíîï]", 'g'),"i");
    r = r.replace(new RegExp("ñ", 'g'),"n");
    r = r.replace(new RegExp("[òóôõö]", 'g'),"o");
    r = r.replace(new RegExp("œ", 'g'),"oe");
    r = r.replace(new RegExp("[ùúûü]", 'g'),"u");
    r = r.replace(new RegExp("[ýÿ]", 'g'),"y");
    return r;
  };

  function getTooltip(_ref) {
    var object = _ref.object;
    if (object && object[indicator] !== undefined || NaN) {
      return {
        html: "<h3 class=tooltip-name>".concat(object.properties.name, "</h3><div class=\"pure-g\"><div class=\"pure-u-1 pure-u-md-3-5\"><span class=\"tooltip-indicator\">").concat(tooltipString, "</div> <div class=\"pure-u-1 pure-u-md-2-5\"><span class=\"tooltip-value\">").concat(object[indicator]).concat(completeIndicator, "</span></div></span></div>"),
        style: {
          backgroundColor: '#FFF',
          fontFamily: 'BlinkMacSystemFont, -apple-system',
          fontSize: '.65rem',
          borderRadius: '2px',
          padding: '0.5rem',
          boxShadow: '2px 2px 2px 1px rgba(0,0,0,0.1)'
        }
      };
    }
  }

  function onLoad() {
    spinner.style.display = 'none'
  }

  function redraw() {
    mapMunicipalities = d3.map();
    d3.csv(urlData, function(data) {

      data.forEach(function(d) {
        d.place_id = +d.place_id
        d[indicator] = +d[indicator]
        mapMunicipalities.set(d.place_id, d[indicator]);
      })

      var dataDuplicates = data

      minValue = d3.min(data, function(d) { return d[indicator] })
      maxValue = d3.max(data, function(d) { return d[indicator] })

      var dataForDomainScale

      dataForDomainScale = data.map(function (obj) {
        return obj[indicator];
      });

      //Create a dynamic domain for every value
      CUSTOM_DOMAIN = chroma.limits(dataForDomainScale, 'q', 6);

      var textMinValue = document.getElementById('map_legend_min_value')
      var textMaxValue = document.getElementById('map_legend_max_value')
      textMinValue.textContent = "".concat(minValue).concat(completeIndicator);
      textMaxValue.textContent = "".concat(maxValue).concat(completeIndicator);

      d3.json(dataTOPOJSON, function(data) {
        var MUNICIPALITIES = {}
        MUNICIPALITIES = topojson.feature(data, data.objects.municipalities);

        if (indicator === 'amount_per_inhabitant') {

          var MUNICIPALITIES_CLONE = JSON.parse(JSON.stringify(MUNICIPALITIES));

          var budgetTableFilter = MUNICIPALITIES.features;
          var budgetTableFiltered = budgetTableFilter.filter(function (el) {
            return dataDuplicates.some(function (f) {
              return f.place_id === el.properties.cp;
            });
          });

          var budgetMunicipalitiesWithoutData = dataDuplicates.filter(function (el) {
            return budgetTableFilter.some(function (f) {
              return f.properties.cp === el.place_id;
            });
          });

          //Replace object features
          MUNICIPALITIES.features = budgetTableFiltered
          var geojsonLayer = new deck.GeoJsonLayer({
            id: 'map',
            data: MUNICIPALITIES,
            stroked: true,
            lineWidthMinPixels: 0.6,
            getLineColor: getLineColor,
            filled: true,
            opacity: 1,
            getFillColor: getFillColor,
            pickable: true
          });

          var geojsonLayerWithoutData = new deck.GeoJsonLayer({
            id: 'map',
            data: MUNICIPALITIES_CLONE,
            stroked: true,
            lineWidthMinPixels: 0.6,
            getLineColor: getLineColor,
            filled: true,
            opacity: 0.1,
            pickable: true
          });
          deckgl.setProps({layers: [geojsonLayerWithoutData, geojsonLayer]});
        } else {
          var geojsonLayer = new deck.GeoJsonLayer({
            id: 'map',
            data: MUNICIPALITIES,
            stroked: true,
            lineWidthMinPixels: 0.6,
            getLineColor: getLineColor,
            filled: true,
            opacity: 1,
            getFillColor: getFillColor,
            pickable: true
          });

          deckgl.setProps({layers: [geojsonLayer]});
        }

        

        spinner.style.display = 'none'

        d3.csv(dataMunicipalities,function(data) {
          var nest = d3
            .nest()
            .key(function(d) { return d.nombre })
            .entries(data);

          nest.sort(function(a, b) {
            return d3.ascending(a.key, b.key);
          })

          var selectMunicipalities = d3.select('#municipalities-flyTO');

          selectMunicipalities
            .selectAll('option')
            .data(nest)
            .enter()
            .append('option')
            .attr('value', function(d) { return d.key })
            .text(function(d) { return d.key })

          var increaseButton = document.getElementById('increaseZoom')
          var decreaseButton = document.getElementById('decreaseZoom')

          increaseButton.addEventListener("click", increaseZoom, false)
          decreaseButton.addEventListener("click", decreaseZoom, false)

          function increaseZoom() {
            //In the first render props.viewState are undefined, so we need modify the initialViewState instead viewState
            if (!deckgl.props.hasOwnProperty('viewState')) {
              changeStateProps('initialViewState', true)
            } else {
              changeStateProps('viewState', true)
            }
          }

          function decreaseZoom() {
            if (!deckgl.props.hasOwnProperty('viewState')) {
              changeStateProps('initialViewState', false)
            } else {
              changeStateProps('viewState', false)
            }
          }

          function changeStateProps(value, increase) {
            var increaseDecrease = increase === true ? +1 : -1
            deckgl.setProps({
              viewState: {
                zoom: deckgl.props[value].zoom + increaseDecrease,
                latitude: deckgl.props[value].latitude,
                longitude: deckgl.props[value].longitude,
                maxZoom: deckgl.props[value].maxZoom,
                minZoom: deckgl.props[value].minZoom
              }
            })
          }

          selectMunicipalities.on('change', function() {
            //Get the selected municipality
            var value = d3
              .select(this)
              .property('value')

            //Filter municipalities with the selected value
            var selectElement = data.filter(function(el) {
              return el.nombre === value
            });

            //Pass coordinates to deck.gl
            deckgl.setProps({
              viewState: {
                longitude: +selectElement[0].lat,
                latitude: +selectElement[0].lon,
                zoom: 9,
                transitionInterpolator: new deck.FlyToInterpolator(),
                transitionDuration: 1500
              }
            })

            //Clone MUNICIPALITIES object
            var strokeDATA = JSON.parse(JSON.stringify(MUNICIPALITIES));

            var strokeDATAFILTER = strokeDATA.features

            //Filter by selected municipality
            var strokeSelected = strokeDATAFILTER.filter(function(el) {
              return el.properties.name === value
            });

            //Replace object features
            strokeDATA.features = strokeSelected

            //Create a new layer that contains only the selected municipality
            var selectedMunicipality = [new deck.GeoJsonLayer({
              id: 'map-stroke',
              data: strokeDATA,
              stroked: true,
              filled: true,
              lineWidthMinPixels: 2,
              opacity: 1,
              getFillColor: getFillColor,
              pickable: true
            })];

            //Update deck.gl with the old and new layer.
            deckgl.setProps({ layers: [geojsonLayer, selectedMunicipality] });
          });
        });
      });
    })
  }

  function getLineColor(d) {
    //Only changes the color of the Canarian Islands border
    if (Object.keys(d.properties).length === 0) {
      return [0,0,0]
    } else {
      return [255,255,255]
    }
  }

  function getFillColor(d) {
    if (Object.keys(d.properties).length === 0) {
      return [255,255,255,0]
    }
    var COLOR_SCALE = d3.scaleThreshold()
      .domain(CUSTOM_DOMAIN)
      .range(CHOROPLET_SCALE);
    return COLOR_SCALE(d[indicator] = mapMunicipalities.get(d.properties.cp));
  }

  function loadIndicators(e) {
    spinner.style.display = 'block'
    indicator = $('.metric.selected').data('indicator');
    if(indicator === 'gasto_por_habitante') {
      completeIndicator = indicatorsValue.gasto_por_habitante.unit
      tooltipString = indicatorsValue.gasto_por_habitante.name
    } else if (indicator === 'gasto_total') {
      completeIndicator = indicatorsValue.gasto_total.unit
      tooltipString = indicatorsValue.gasto_total.name
    } else if (indicator === 'planned_vs_executed') {
      completeIndicator = indicatorsValue.planned_vs_executed.unit
      tooltipString = indicatorsValue.planned_vs_executed.name
    } else if (indicator === 'population') {
      completeIndicator = indicatorsValue.population.unit
      tooltipString = indicatorsValue.population.name
    } else if (indicator === 'debt') {
      completeIndicator = indicatorsValue.debt.unit
      tooltipString = indicatorsValue.debt.name
    }

    var year = document.getElementsByTagName('body')[0].getAttribute('data-year');
    
    var queryData = "SELECT+".concat(indicator, "+,place_id+FROM+indicadores_presupuestos_municipales+WHERE+year=").concat(year, "AND+").concat(indicator, "+IS+NOT+NULL");
    urlData = "".concat(endPoint).concat(queryData);
    redraw();
  }

  redraw()

  $(document).on('renderBudgetLineCategory', function(e){
    var element = e.target.activeElement.dataset

    var year = document.getElementsByTagName('body')[0].getAttribute('data-year');
    var area = element.area === 'economic' ? 'e' : 'f'
    var kind = element.kind
    var code = element.categoryCode
    indicator = 'amount_per_inhabitant'

    var queryData = "SELECT+amount_per_inhabitant,place_id+FROM+presupuestos_municipales+WHERE+year%3D%27".concat(year, "%27+AND+code%3D%27").concat(code, "%27+AND+kind%3D%27").concat(kind, "%27+and+area%3D%27").concat(area, "%27");
    urlData = "".concat(endPoint).concat(queryData);
    redraw();

    completeIndicator = indicatorsValue.gasto_por_habitante.unit
    tooltipString = indicatorsValue.gasto_por_habitante.name

  });

  $('.metric').on('click', function(e){
    e.preventDefault();
    $('.metric').removeClass('selected');
    $('[data-category-code]').removeClass('active');
    $(this).addClass('selected');
  });
});
