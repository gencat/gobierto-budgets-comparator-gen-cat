module SiteHelper

  def site_name
    if @site
      @site.institution_type + ' de ' + @site.location_name
    else
      'Gobierto Presupuestos Municipales'
    end
  end

  def site_url
    if @site
      @site.domain
    else
      'presupuestos.gobierto.es'
    end
  end

  def url_host(url)
    URI.parse(url).host
  rescue
    url
  end

  def class_if(class_name, condition)
    if condition
      class_name
    else
      ''
    end
  end

  def hide_if(condition)
    show_if(!condition)
  end

  def show_if(condition)
    unless condition
      "style=\"display: none;\"".html_safe
    end
  end

end
