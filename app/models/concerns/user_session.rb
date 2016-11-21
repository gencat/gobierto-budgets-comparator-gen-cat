module UserSession
  extend ActiveSupport::Concern

  module ClassMethods
    # Returns the hash digest of the given string.
    def digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end
  end

  def remember
    self.remember_token = generate_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def generate_password_reset_token!
    self.password_reset_token = generate_token
    save!
  end

  def generate_verification_token
    self.verification_token = generate_token
  end

  private

  def generate_token
    SecureRandom.urlsafe_base64
  end

end
