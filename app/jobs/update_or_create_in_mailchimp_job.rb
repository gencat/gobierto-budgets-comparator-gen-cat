class UpdateOrCreateInMailchimpJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    if user.in_mailchimp?
      Mailchimp.update_member(user)
    else
      Mailchimp.add_member(user)
    end 
  end
end
