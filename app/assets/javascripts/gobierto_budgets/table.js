$(document).on('turbolinks:load', function() {
  $('.js-table-rows-toggle').on('click', function (e) {
    e.stopPropagation();

    $(this).closest('table').toggleClass('top-10');

    ($(this).closest('table').hasClass('top-10')) ?
      $(this).text(I18n.t('gobierto_budgets.places.show.related_entities_budget.see_all', { number: 123 })) :
      $(this).text(I18n.t('gobierto_budgets.places.show.related_entities_budget.see_less'));
  })
});
