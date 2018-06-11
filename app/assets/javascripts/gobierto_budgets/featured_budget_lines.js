$(document).on('turbolinks:load', function() {
  $.ajax({
    url: $('.featured_budget_line').attr('data-featured-budget-line'),
    dataType: 'script'
  });
});
