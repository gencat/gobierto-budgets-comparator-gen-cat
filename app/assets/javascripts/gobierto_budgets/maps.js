$(function () {
  CSS['gasto_por_habitante'] = "\
#indicators_2016 [ value <= 700]  { polygon-fill: #d73027; }\
#indicators_2016 [ value > 700]   { polygon-fill: #f79272; }\
#indicators_2016 [ value > 1200]  { polygon-fill: #fff2cc; }\
#indicators_2016 [ value > 1500]  { polygon-fill: #8cce8a; }\
#indicators_2016 [ value > 3000 ] { polygon-fill: #1a9850; }\
#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; }\
    ";

    CSS['gasto_total'] = "\
#indicators_2016 [ value <= 700000] { polygon-fill: #d73027; }\
#indicators_2016 [ value >  700000] { polygon-fill: #f79272; }\
#indicators_2016 [ value > 1200000] { polygon-fill: #fff2cc; }\
#indicators_2016 [ value > 1500000] { polygon-fill: #8cce8a; }\
#indicators_2016 [ value > 3000000] { polygon-fill: #1a9850; }\
#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; }\
    ";

    CSS['budgets'] = "\
#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; }\
#indicators_2016 [ value <=  10]  { polygon-fill: #d73027; }\
#indicators_2016 [ value >   10]  { polygon-fill: #f79272; }\
#indicators_2016 [ value >  800]  { polygon-fill: #fff2cc; }\
#indicators_2016 [ value > 1500] { polygon-fill: #8cce8a; }\
#indicators_2016 [ value > 3000] { polygon-fill: #1a9850; }\
    ";

    CSS['planned_vs_executed'] = "\
#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; }\
#indicators_2016 [ value <= 100000]  { polygon-fill: #d73027; }\
#indicators_2016 [ value >  100000]  { polygon-fill: #f79272; }\
#indicators_2016 [ value > 8000000]  { polygon-fill: #fff2cc; }\
#indicators_2016 [ value > 15000000] { polygon-fill: #8cce8a; }\
#indicators_2016 [ value > 30000000] { polygon-fill: #1a9850; }\
    ";

    CSS['population'] = "\
#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; }\
#indicators_2016 [ value <= 1000]   { polygon-fill: #d73027; }\
#indicators_2016 [ value >  1000]    { polygon-fill: #f79272; }\
#indicators_2016 [ value > 10000]   { polygon-fill: #fff2cc; }\
#indicators_2016 [ value > 100000]  { polygon-fill: #8cce8a; }\
#indicators_2016 [ value > 1000000] { polygon-fill: #1a9850; }\
    ";

    CSS['debt'] = "\
#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; }\
#indicators_2016 [ value <= 1000]   { polygon-fill: #d73027; }\
#indicators_2016 [ value >  1000]    { polygon-fill: #f79272; }\
#indicators_2016 [ value > 10000]   { polygon-fill: #fff2cc; }\
#indicators_2016 [ value > 100000]  { polygon-fill: #8cce8a; }\
#indicators_2016 [ value > 1000000] { polygon-fill: #1a9850; }\
    ";

  function placesScopeCondition(){
    return " t.place_id IN (" + window.placesScope + ")";
  }

  function renderMapIndicator(layer, vis){
    $('[data-indicator]').click(function(e){
      var year = $('body').data('year');
      var indicator = $('.metric.selected').data('indicator');
      layer.show();

      var query = "select i.cartodb_id, t.place_id, t.nameunit as name, t.the_geom, t.the_geom_webmercator, i."+indicator+" as value from ign_spanish_adm3_municipalities_displaced_canary as t full join indicators_"+year+" as i on i.place_id = t.place_id WHERE" + placesScopeCondition();
      console.log(query);
      layer.setSQL(query);

      // var css = "#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; } ";
      // $.getJSON("https://gobierto.cartodb.com/api/v2/sql?q=SELECT MAX('"+indicator+"'), MIN('"+indicator+"') FROM indicators_"+year,function(response){
      //   var range=max-min;
      //   var colors = [ '#d73027', '#f79272', '#fff2cc', '#8cce8a', '#1a9850'];

      //   //get the incremental value for each step based on the range
      //   var step = range/colors.length;

      //   colors.forEach(function(color,i){
      //     var value = min + (step * i);
      //     var color = colors[i];
      //     css += "#indicators_2016 [value<=" + value + "] {polygon-fill:" + color + "}; ";
      //   });
      // });

      // console.log(css);

      var css = CSS[indicator];
      layer.setCartoCSS(css);
      // $('#legend').html($('#legend_' + indicator).html());
    });
  }

  function renderMapBudgetLine(layer, vis){
    $(document).on('renderBudgetLineCategory', function(e){
      $('.metric').removeClass('selected');
      var year = $('body').data('year');

      layer.show();

      var query = "select i.cartodb_id, t.place_id, t.nameunit as name, t.the_geom, t.the_geom_webmercator, i.code, i.kind, i.area, i.amount, i.amount_per_inhabitant as value from ign_spanish_adm3_municipalities_displaced_canary as t full join planned_budgets_"+year+" as i on i.place_id = t.place_id" +
        " WHERE code='"+e.code+"' AND kind='" + e.kind + "' AND area='" + e.area[0] + "' AND" + placesScopeCondition();
      console.log(query);
      layer.setSQL(query);

      var css = CSS['budgets'];
      layer.setCartoCSS(css);
      // $('#legend').html($('#legend_' + indicator).html());
    });
  }

  if($('#map').length){

    var breakpoint = 770;

    if($(window).width() >= breakpoint) {
      var home_map_zoom_level = 6;
      var home_map_center_lat = 39.3;
      var home_map_center_lon = -5.6;
    }
    else {
      var home_map_zoom_level = 5;
      var home_map_center_lat = 38.3;
      var home_map_center_lon = -4.0;
    }

    cartodb.createVis('map', 'https://gobierto.carto.com/api/v2/viz/205616b2-b893-11e6-b070-0e233c30368f/viz.json', {
        shareable: false,
        title: false,
        description: false,
        search: false,
        tiles_loader: true,
        center_lat: home_map_center_lat,
        center_lon: home_map_center_lon,
        zoom: home_map_zoom_level,
        zoomControl: true,
        loaderControl: false
        })
    .done(function(vis, layers) {
      var sublayer = layers[1].getSubLayer(0);
      vis.addOverlay({
        type: 'tooltip',
        layer: sublayer,
        template: $('#infowindow_template').html(),
        position: 'bottom|right',
        fields: [{ name: 'name', value: 'value' }]
      });
      sublayer.setInteractivity('name, value');
      renderMapIndicator(sublayer, vis);
      renderMapBudgetLine(sublayer, vis);
      $('[data-indicator].selected').click();
    })
    .error(function(err) {
      console.log(err);
    });

    $('.metric').on('click', function(e){
      e.preventDefault();
      $('.metric').removeClass('selected');
      $(this).addClass('selected');
    });
  }
});
