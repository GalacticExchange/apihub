module Gexcore
  class VerificationService < BaseService


    def self.get_link_for_user(user, token)
      make_hub_link "verify/#{token}"
    end

  end
end

