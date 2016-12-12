var AUTOCOMPLETE_DEFAULTS = function(){
  return {
    dataType: 'json',
    minChars: 3,
    showNoSuggestionNotice: true,
    noSuggestionNotice: I18n.t('layout.autocomplete_no_results'),
    preserveInput: true,
    autoSelectFirst: true,
    triggerSelectOnValidInput: false,
    preventBadQueries: false,
    tabDisabled: true
  };
};
