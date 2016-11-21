module GobiertoHelper

  def flush_the_flash(entity = nil)
    if flash[:notice]
      css_class = 'notice success'
      msg = flash[:notice]
      icon_class = 'fa-check-circle-o'
    elsif flash[:alert]
      css_class = 'notice error'
      msg = flash[:alert]
      icon_class = 'fa-times'
    else
      return
    end

    content_tag :div, class: css_class do
      content_tag(:p, content_tag(:i, '', class: 'fa ' + icon_class) + ' ' + msg) + error_messages_for(entity)
    end
  end

  def flush_comments_flash(entity = nil)
    if flash[:comment_notice]
      css_class = 'notice success'
      msg = flash[:comment_notice]
      icon_class = 'fa-check-circle-o'
    elsif flash[:comment_alert]
      css_class = 'notice error'
      msg = flash[:comment_alert]
      icon_class = 'fa-times'
    else
      return
    end

    content_tag :div, class: css_class, id: 'comments_flash' do
      content_tag(:p, content_tag(:i, '', class: 'fa ' + icon_class) + ' ' + msg) + error_messages_for(entity)
    end
  end

  def flush_sessions_flash(entity = nil)
    if flash[:session_alert]
      css_class = 'notice error'
      msg = flash[:session_alert]
      icon_class = 'fa-times'

      content_tag :div, class: css_class, id: 'comments_flash' do
        content_tag(:p, content_tag(:i, '', class: 'fa ' + icon_class) + ' ' + msg)
      end
    end
  end

  def flush_signup_flash(entity = nil)
    if flash[:signup_alert]
      css_class = 'notice error'
      msg = flash[:signup_alert]
      icon_class = 'fa-times'

      content_tag :div, class: css_class, id: 'comments_flash' do
        content_tag(:p, content_tag(:i, '', class: 'fa ' + icon_class) + ' ' + msg) + error_messages_for(entity)
      end
    end
  end

  def pending(&block)
    yield if controller_name == 'sandbox'
  end

  def link_to_or_identify_user(name = nil, options = nil, html_options = nil, &block)
    unless logged_in?
      html_options[:data] ||= {}
      html_options[:data].merge!({menu: 'account'})
    end

    link_to(name, options, html_options, &block)
  end

  def time_until_in_words(time)
    days = (time - Time.zone.now) / (60*60*24)
    if days <= 10
      I18n.t('gobierto_participation.in_n_days', count: days.to_i)
    else
      I18n.l(time.to_date, format: :short)
    end
  end

  def current_user_name
    current_user.full_name + (impersonated_session? ? ' (admin)' : '')
  end

  def markdown(text)
    return if text.blank?

    options = {
      filter_html:     false,
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

  private

    def error_messages_for(entity)
      return '' if entity.nil? || entity.errors.empty?

      if entity.errors.any?
        content_tag :ul do
          entity.errors.full_messages.map do |msg|
            content_tag :li do
              msg
            end
          end.join("\n").html_safe
        end
      end
    end

end
