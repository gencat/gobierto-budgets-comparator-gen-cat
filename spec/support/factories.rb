module Factories
  def create_user(attrs = {})
    attrs[:email]     ||= "foo@example.com"
    attrs[:password]  ||= "foo123456"
    attrs[:password_confirmation] ||= attrs[:password]
    attrs[:place_id] ||= 28079
    attrs[:terms_of_service] ||= true
    User.new(attrs).tap do |u|
      u.save!
      u.clear_verification_token
      u.save!
    end
  end

  def create_commenter(attrs = {})
    create_user({email: 'comenter@example.com'}.merge(attrs))
  end


  def create_admin(attrs = {})
    create_user email: 'admin@example.com', password:'adminadmin', admin: true
  end

  def create_site(attrs = {})
    site = Site.create! name: 'Órgiva Participa', domain: 'orgiva.' + Settings.gobierto_host, location_name: 'Órgiva', location_type: 'INE::Places::Place',
  external_id: 18147, institution_url: 'http://orgiva.es', institution_type: 'Ayuntamiento'
    site.configuration.links = ['http://orgiva.es']
    site.configuration.logo = 'http://www.aytoorgiva.org/web/sites/all/themes/aytoorgiva_COPSEG/logo.png'
    site.configuration.modules = ['GobiertoParticipation', 'GobiertoBudgets', 'GobiertoCms']
    site.save!
    site
  end

end
