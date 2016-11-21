module GobiertoBudgets
  class Subscription < ActiveRecord::Base
    belongs_to :user

    validates :user_id, uniqueness: {scope: :place_id}

    def self.for_place(place)
      GobiertoBudgets::Subscription.where(place_id: place.id).count
    end

    def place
      INE::Places::Place.find place_id
    end
  end
end
