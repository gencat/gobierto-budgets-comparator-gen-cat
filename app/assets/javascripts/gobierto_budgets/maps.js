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
    if(window.placesScope.length)
      return " i.place_id IN (" + window.placesScope + ")";
    else
      return " 1=1";
  }

  function filterOutliers(someArray) {
    // Copy the values, rather than operating on references to existing values
    var values = someArray.concat();

    // Then sort
    values.sort( function(a, b) {
            return a - b;
         });

    /* Then find a generous IQR. This is generous because if (values.length / 4)
     * is not an int, then really you should average the two elements on either
     * side to find q1.
     */
    var q1 = values[Math.floor((values.length / 4))];
    // Likewise for q3.
    var q3 = values[Math.ceil((values.length * (3 / 4)))];
    var iqr = q3 - q1;

    // Then find min and max values
    var maxValue = q3 + iqr*1.5;
    var minValue = q1 - iqr*1.5;

    // Then filter anything beyond or beneath these values.
    var filteredValues = values.filter(function(x) {
        return (x < maxValue) && (x > minValue);
    });

    // Then return
    return filteredValues;
  }

  function renderMapIndicator(layer, vis){
    $('[data-indicator]').click(function(e){
      var year = $('body').data('year');
      var indicator = $('.metric.selected').data('indicator');
      layer.show();

      var sql = new cartodb.SQL({ user: 'gobierto' });
      sql.execute("SELECT {{indicator}} as value FROM indicators_{{year}} as i WHERE" + placesScopeCondition(), { indicator: indicator, year: year })
        .done(function(data) {
          if(indicator === 'debt' || indicator === 'planned_vs_executed')
            colors = colors.reverse();

          // push all the values into an array
          var values = [];
          data.rows.forEach(function(row,i) {
            values.push(row['value']);
          });
          values = filterOutliers(values);

          var clusters = ss.ckmeans(values, colors.length);
          var ranges = clusters.map(function(cluster){
            return [cluster[0],cluster.pop()];
          });

           var css = "#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; } ";
           if(indicator === 'debt'){
             css = "#indicators_2016 [ value = 0]  { polygon-fill: "+colors[0]+"; } ";
           }
           console.log('Ranges: ' + ranges);
           ranges.forEach(function(range,i){
             var value = range[0];
             if(i === 0)
               value = 0;
             var color = colors[i];
             css += "#indicators_2016 [value>"+value + "] {polygon-fill:" + color + "}\n";
           });
           console.log(css);

           var query = "select i.cartodb_id, t.place_id, t.nameunit as name, t.the_geom, t.the_geom_webmercator, i."+indicator+" as value from ign_spanish_adm3_municipalities_displaced_canary as t full join indicators_"+year+" as i on i.place_id = t.place_id WHERE" + placesScopeCondition();
           console.log(query);
           layer.setSQL(query);

           layer.setCartoCSS(css);
           layer.show();
        })
      .error(function(errors) {
        // errors contains a list of errors
        console.log("errors:" + errors);
      });
      $('#legend-container').html($('#legend').html());
    });
  }

  function renderMapBudgetLine(layer, vis){
    $(document).on('renderBudgetLineCategory', function(e){
      $('.metric').removeClass('selected');
      var year = $('body').data('year');

      layer.show();

      var sql = new cartodb.SQL({ user: 'gobierto' });
      sql.execute("SELECT i.amount_per_inhabitant as value FROM planned_budgets_{{year}} as i WHERE code='"+e.code+"' AND kind='" + e.kind + "' AND area='" + e.area[0] + "' AND" + placesScopeCondition(), { year: year })
        .done(function(data) {
          // push all the values into an array
          var values = [];
          data.rows.forEach(function(row,i) {
            values.push(row['value']);
          });

          var clusters = ss.ckmeans(values, colors.length);
          var ranges = clusters.map(function(cluster){
            return [cluster[0],cluster.pop()];
          });

           var css = "#indicators_2016 [ value = 0]  { polygon-fill: #ffffff; } ";
           ranges.forEach(function(range,i){
             var value = range[0]
             var color = colors[i];
             css += "#indicators_2016 [value>"+value + "] {polygon-fill:" + color + "}\n";
           });
           console.log(css);

           var query = "select i.cartodb_id, t.place_id, t.nameunit as name, t.the_geom, t.the_geom_webmercator, i.code, i.kind, i.area, i.amount, i.amount_per_inhabitant as value from ign_spanish_adm3_municipalities_displaced_canary as t full join planned_budgets_"+year+" as i on i.place_id = t.place_id" +
               " WHERE code='"+e.code+"' AND kind='" + e.kind + "' AND area='" + e.area[0] + "' AND" + placesScopeCondition();

           console.log(query);
           layer.setSQL(query);

           layer.setCartoCSS(css);
           layer.show();
        })
      .error(function(errors) {
        // errors contains a list of errors
        console.log("errors:" + errors);
      });

      $('#legend-container').html($('#legend').html());
    });
  }

  if($('#map').length){

    var colors = [ '#d73027', '#f79272', '#fff2cc', '#8cce8a', '#1a9850'];

    cartodb.createVis('map', 'https://gobierto.carto.com/api/v2/viz/205616b2-b893-11e6-b070-0e233c30368f/viz.json', {
        shareable: false,
        title: false,
        description: false,
        search: false,
        tiles_loader: true,
        center_lat: window.mapSettings.centerLat,
        center_lon: window.mapSettings.centerLon,
        zoom: window.mapSettings.zoomLevel,
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
