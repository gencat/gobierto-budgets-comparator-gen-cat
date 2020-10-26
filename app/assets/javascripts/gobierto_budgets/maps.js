$(document).on('turbolinks:load', function() {

  var deckgl
  var geojsonLayer
  var CUSTOM_DOMAIN
  new SlimSelect({
    select: '#municipalities-flyTO',
    placeholder: 'Introduce un municipio'
  })

  var spinner = document.getElementById('overlay')
  var mapMunicipalities = d3.map();
  var dataTOPOJSON = "https://gist.githubusercontent.com/jorgeatgu/dcb73825b02af45250c4dfa66aa0f94f/raw/18a9f2fa108c56454556abc7e08b64eb2a0dc4d8/municipalities_topojson.json";
  var dataMunicipalities = "https://datos.gobierto.es/api/v1/data/data.csv?sql=SELECT+*+FROM+municipios"
  var endPoint = "https://datos.gobierto.es/api/v1/data/data.csv?sql="
  var indicator = 'gasto_por_habitante'
  var year = document.getElementsByTagName('body')[0].getAttribute('data-year')
  var queryData = "SELECT+".concat(indicator, "+,place_id+FROM+indicadores_presupuestos_municipales+WHERE+year=").concat(year, "AND+").concat(indicator, "+IS+NOT+NULL");

  var urlData = "".concat(endPoint).concat(queryData);

  var indicators = document.querySelectorAll('[data-indicator]')

  var completeIndicator = '€/Hab'
  var tooltipString = 'Gasto por habitante'

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
    window.location.href = "/places/" + accentsTidy(replaced) + "/" + year;
  }

  function getTooltip(_ref) {
    var object = _ref.object;
    if (object) {
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
    d3.csv(urlData, function(data) {
      data.forEach(function(d) {
        d.place_id = +d.place_id
        d[indicator] = +d[indicator]
        mapMunicipalities.set(d.place_id, d[indicator]);
      })

      var minValue = d3.min(data, function(d) { return d[indicator] })
      var maxValue = d3.max(data, function(d) { return d[indicator] })

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

        var MUNICIPALITIES = topojson.feature(data, data.objects.municipalities);
        var geojsonLayer = new deck.GeoJsonLayer({
          id: 'map',
          data: MUNICIPALITIES,
          stroked: true,
          lineWidthMinPixels: 0.4,
          getLineColor: [255,255,255],
          filled: true,
          opacity: 1,
          getFillColor: getFillColor,
          pickable: true
        });

        deckgl.setProps({layers: [geojsonLayer]});

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

  function getFillColor(d) {
    var COLOR_SCALE = d3.scaleThreshold()
      .domain(CUSTOM_DOMAIN)
      .range(CHOROPLET_SCALE);
    return COLOR_SCALE(d[indicator] = mapMunicipalities.get(d.properties.cp));
  }

  function getValuesIndicators() {
    var populationAndCostQuery = "SELECT+SUM%28population%29+AS+population%2C+SUM%28gasto_total%29+AS+gasto_total+FROM+indicadores_presupuestos_municipales+WHERE+year=".concat(year);
    var populationAndCostData = "".concat(endPoint).concat(populationAndCostQuery);
    d3.csv(populationAndCostData, function (data) {
      var totalCost = +data[0].gasto_total;
      var totalPopulation = +data[0].population;
      var costPerHabitant = totalCost / totalPopulation;
    });
    var debtQuery = "SELECT+sum%28debt%29+AS+debt+FROM+indicadores_presupuestos_municipales+WHERE+year=".concat(year);
    var debtData = "".concat(endPoint).concat(debtQuery);
    d3.csv(debtData, function (data) {
      var totalDebt = +data[0].debt;
    });
  }

  function loadIndicators(e) {
    spinner.style.display = 'block'
    indicator = $('.metric.selected').data('indicator');
    if(indicator === 'gasto_por_habitante') {
      completeIndicator = '€/Hab'
      tooltipString = 'Gasto por habitante'
    } else if (indicator === 'gasto_total') {
      completeIndicator = '€'
      tooltipString = 'Gasto total'
    } else if (indicator === 'planned_vs_executed') {
      completeIndicator = '%'
      tooltipString = 'Planeado vs Ejecutado'
    } else if (indicator === 'population') {
      completeIndicator = ' personas'
      tooltipString = 'Población'
    } else if (indicator === 'debt') {
      completeIndicator = '€'
      tooltipString = 'Deuda'
    }
    var year = document.getElementsByTagName('body')[0].getAttribute('data-year');
    
    var queryData = "SELECT+".concat(indicator, "+,place_id+FROM+indicadores_presupuestos_municipales+WHERE+year=").concat(year, "AND+").concat(indicator, "+IS+NOT+NULL");
    urlData = "".concat(endPoint).concat(queryData);
    redraw();
  }

  redraw()
  getValuesIndicators()

  $('.metric').on('click', function(e){
    e.preventDefault();
    $('.metric').removeClass('selected');
    $('[data-category-code]').removeClass('active');
    $(this).addClass('selected');
  });
});
