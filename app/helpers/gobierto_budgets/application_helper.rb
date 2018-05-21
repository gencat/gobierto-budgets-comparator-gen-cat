module GobiertoBudgets
  module ApplicationHelper
    def pending(&block)
      if controller_name == 'sandbox'
        yield
      end
    end

    def sign(v1, v2 = nil)
      return 'sign-neutral' if v1.blank? || v2.blank?
      diff = v1 - v2
      if diff > 0
        'sign-up'
      elsif diff < 0
        'sign-down'
      else
        'sign-neutral'
      end
    rescue
      'sign-neutral'
    end

    def format_currency(n, absolute_value = false)
      return nil if n.blank?
      n = n.to_f
      n = n.abs if absolute_value

      if n.abs > 1_000_000
        "#{helpers.number_with_precision(n.to_f / 1_000_000.to_f, precision: 1, strip_insignificant_zeros: true)}M€"
      else
        helpers.number_to_currency(n, precision: 1, strip_insignificant_zeros: true)
      end
    end

    def delta_percentage(current_year_value, old_value)
      number_with_precision(((current_year_value.to_f - old_value.to_f)/old_value.to_f) * 100, precision: 2).to_s + "%"
    end

    def percentage_of_total(value, total)
      number_with_precision((value.to_f / total.to_f) * 100, precision: 2) + '%'
    end

    def area_class(area, kind)
      return GobiertoBudgets::FunctionalArea if (area == 'functional' && %{income i}.exclude?(kind.downcase))
      GobiertoBudgets::EconomicArea
    end

    def budget_line_denomination(area, code, kind, capped = -1)
      area = area_class area, kind
      if area.all_items[kind][code].nil?
        res = " - "
      else
        res = area.all_items[kind][code][0..capped]
        res += "..." if capped < res.length && capped > -1
      end
      res
    end

    def budget_line_description(area_name, code, kind)
      area = area_class area_name, kind
      description = area.all_descriptions[I18n.locale][area_name][kind][code.to_s]
      name = area.all_items[kind][code]
      if description != name
        return description
      elsif description.present?
        kind_what = kind == 'I' ? t('common.incomes') : t('common.expenses')

        I18n.t('helpers.budget_line_description', kind_what: kind_what, description: description.downcase, link: link_to(budget_line_denomination(area_name, code[0..-2], kind), gobierto_budgets_budget_line_path(@place.slug, params[:year],code[0..-2], kind, area_name))).html_safe
      end
    end

    def kind_literal(kind, plural = true)
      if kind == 'I'
        plural ? t('common.incomes') : t('common.income')
      else
        plural ? t('common.expenses') : t('common.expense')
      end
    end

    def area_literal(area)
      area == 'functional' ? 'Funcional' : 'Económica'
    end

    def other_kind(kind)
      kind == 'I' ? 'G' : 'I'
    end

    def budget_line_crumbs(budget_line, type)
      crumbs = [budget_line]
      parent_code = budget_line['parent_code']

      while parent_code.present? do
        p = GobiertoBudgets::BudgetLine.find(ine_code: budget_line['ine_code'], code: parent_code, year: budget_line['year'], kind: budget_line['kind'], type: type)
        break if p.nil?
        crumbs.unshift(p)
        parent_code = p['parent_code']
      end

      return crumbs
    end

    def link_to_parent_comparison(places, year, kind, area_name, parent_code)
      options = {}
      options[:parent_code] = parent_code[0..-2] if parent_code.length > 1
      link_to('« anterior', gobierto_budgets_places_compare_path(places.map(&:slug).join(':'),year,kind,area_name, options))
    end

    def lines_chart_api_path(what, compared_level, places, year, kind, parent_code = nil, area_name = 'economic')
      place_ids = places.map(&:id).join(':')
      path = if compared_level > 1
        gobierto_budgets_api_data_compare_budget_lines_path(place_ids, year, what, kind, parent_code, area_name, format: :json )
      else
        gobierto_budgets_api_data_compare_path(place_ids, year, what, kind: kind, format: :json)
      end
      path
    end

    def items_in_level(budget_lines, level, parent_code)
      budget_lines.select {|bl| bl['level'] == level && bl['parent_code'] == parent_code }.uniq{|bl| bl['code'] }
    end

    def categories_in_level(area, kind, level, parent_code)
      area = area_class area, kind
      area.all_items[kind].select{|k,v| k.length == level && k.starts_with?(parent_code.to_s)}.sort_by{|k,v| k}
    end

    def filter_location_name
      name = ""
      if @filter.location?
        name = @filter.location.name
        if @filter.location.is_a?(INE::Places::Province)
          name += " (Provincia)"
        elsif @filter.location.is_a?(INE::Places::AutonomousRegion)
          name += " (CCAA)"
        end
      end

      name
    end

    def data_attributes
      attrs = []
      if @place
        # TODO:
        attrs << %Q{data-bubbles-data="https://gobierto-populate-staging.s3.eu-west-1.amazonaws.com/gobierto_budgets/8121/data/bubbles.json"}
        attrs << %Q{data-track-url="#{gobierto_budgets_place_path(@place.slug, @year || GobiertoBudgets::SearchEngineConfiguration::Year.last)}"}
        attrs << %Q{data-place-slug="#{@place.slug}"}
        attrs << %Q{data-place-name="#{@place.name}"}
      end
      if action_name == 'compare' and controller_name == 'places'
        attrs << %Q{data-comparison-name="#{@places.map{|p| p.name }.join(' + ')}"}
        attrs << %Q{data-comparison-track-url="#{request.path}"}
        attrs << %Q{data-comparison-slug="#{params[:slug_list]}"}
      end
      attrs << %Q{data-year="#{@year || GobiertoBudgets::SearchEngineConfiguration::Year.last}"}
      attrs << %Q{data-kind="#{@kind || 'expense'}"}
      attrs << %Q{data-area="#{@area_name || 'economic'}"}
      attrs << %Q{data-action="#{action_name}"}
      attrs << %Q{data-no-turbolink="true"} if action_name == 'map'
      attrs.join(' ').html_safe
    end

    def ranking_variable(what)
      if what == 'amount_per_inhabitant'
        @code.present? ? what : 'total_budget_per_inhabitant'
      elsif what == 'amount'
        @code.present? ? what : 'total_budget'
      elsif what == 'population'
        'value'
      end
    end

    def compare_slug(place, year)
      "#{place.name}|#{gobierto_budgets_place_path(place, year)}|#{place.slug}"
    end

    def place_name(ine_code)
      INE::Places::Place.find(ine_code).try(:name)
    end

    def places_for_select
      INE::Places::Place.all.map do |place|
        [place.name, place.id]
      end
    end

    def rankings_select
      array = []
      array.concat([[t('gobierto_budgets.pages.home.whole_spain'),'']]) if !GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
      array.concat(INE::Places::AutonomousRegion.all.sort_by(&:name).map do |ar|
        [ar.name, ar.id]
      end)
    end

    def parent_code(code)
      if code.present?
        if code.include?('-')
          code.split('-').first
        else
          code[0..-2]
        end
      end
    end

    def twitter_share(message, url)
      short_url_length = 24
      total_message_length = 140
      signature = "#{I18n.t('helpers.in')} #{Settings.twitter_account}: "
      max_message_length = total_message_length - short_url_length - signature.length

      to_share = signature
      to_share += (message.length > max_message_length) ? message.slice(0, max_message_length - 3) + "..." : message
      to_share += " "+url
      to_share
    end

    def gobierto_budgets_answers_path_with_params(question_id, answer_text)
      gobierto_budgets_answers_path(answer: {
        question_id: question_id, answer_text: answer_text,
        place_id: @place.id, year: @year, kind: @kind, area_name: @area_name, code: @code
      })
    end

    def markdown(text)
      return if text.blank?

      options = {
        filter_html:     true,
        hard_wrap:       true,
        link_attributes: { rel: 'nofollow', target: "_blank" },
        space_after_headers: true,
        fenced_code_blocks: true
      }

      extensions = {
        autolink:           true,
        superscript:        true,
        disable_indented_code_blocks: true
      }

      renderer = Redcarpet::Render::HTML.new(options)
      markdown = Redcarpet::Markdown.new(renderer, extensions)

      markdown.render(text).html_safe
    end

  end
end
