class Mailchimp
  LIST_URL = Settings.mailchimp_list
  API_KEY = Rails.application.secrets.mailchimp_api_key

  def self.is_member?(user)
    return if LIST_URL.blank?

    email_digest = Digest::MD5.hexdigest user.email.downcase

    req = Faraday.new(url: "#{LIST_URL}#{email_digest}")
    req.basic_auth('anystring',API_KEY)
    response = req.get

    response.status == 200
  end

  def self.add_member(user)
    return if LIST_URL.blank?

    conn = Faraday.new(url: LIST_URL)
    conn.basic_auth('anystring',API_KEY)

    response = conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = request_body(user)
    end
  end

  def self.update_member(user)
    return if LIST_URL.blank?

    email_digest = Digest::MD5.hexdigest user.email.downcase

    conn = Faraday.new(url: "#{LIST_URL}#{email_digest}")
    conn.basic_auth('anystring',API_KEY)

    response = conn.put do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = request_body(user, :update)
    end
  end

  private

  def self.request_body(user, action = :add)
    body = {
      "email_address": user.email,
      "merge_fields": {
        "FNAME": (user.first_name || ''),
        "LNAME": (user.last_name || ''),
        "MUNICIPIO": (user.place_id.present? ? INE::Places::Place.find(user.place_id).name : 'Sin especificar'),
        "MMERGE4": (user.pro? ? 'Profesional de Administración Local' : 'Ciudadano')
      }
    }

    body.merge!("status": "subscribed", "email_type": "html", "language": "es") if action == :add
    body.to_json
  end
end
