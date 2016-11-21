module GobiertoBudgets
  class SubscriptionsController < GobiertoBudgets::ApplicationController
    respond_to :js

    def create
      if logged_in?
        if @place = INE::Places::Place.find(params[:place_id])
          current_user.subscriptions.create place_id: @place.id
        end
      end
    end

    def destroy
      if logged_in?
        if subscription = current_user.subscriptions.find(params[:id])
          @place = INE::Places::Place.find(subscription.place_id)
          subscription.destroy
        end
      end

      render 'create'
    end
  end
end
