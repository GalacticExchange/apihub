module Gexcore
  class TokenGenerator < BaseService
    VERIFICATION   = 1
    INVITATION     = 2
    CLUSTER        = 3
    CONTAINER     = 4
    NODE     = 5
    SHARE          = 6
    PASSWORD       = 7
    KEY            = 8


    def self.random_string_digits(n)
      (0...n).map { ('0'..'9').to_a[rand(10)] }.join
    end

    def self.generate_verification_token
      d = Date.today
      VERIFICATION.to_s + d.strftime('%y%j') + random_string_digits(7)
    end

    def self.generate_team_uid
      d = Date.today
      CLUSTER.to_s + d.strftime('%y%j') + random_string_digits(7)
    end


    def self.generate_invitation_token
      d = Date.today
      INVITATION.to_s + d.strftime('%y%j') + random_string_digits(7)
    end

    def self.generate_invitation_uid
      generate_invitation_token
    end

    def self.generate_cluster_uid
      d = Date.today
      #d.strftime('%y%j') + Common.random_string_digits(11)
      CLUSTER.to_s + d.strftime('%y%j') + random_string_digits(10)
    end

    def self.generate_application_uid
      d = Date.today
      d.strftime('%y%j') + random_string_digits(11)
    end

    def self.generate_container_uid
      d = Date.today
      CONTAINER.to_s + d.strftime('%y%j') + Gexcore::Common.random_string_digits(11)
    end



    def self.generate_share_uid
      d = Date.today
      SHARE.to_s + d.strftime('%y%j') + random_string_digits(7)
    end

    def self.generate_password_uid
      d = Date.today
      PASSWORD.to_s + d.strftime('%y%j') + random_string_digits(7)
    end

    def self.generate_key_uid
      d = Date.today
      KEY.to_s + d.strftime('%y%j') + random_string_digits(7)
    end


    def self.generate_node_agent_token
      d = Date.today
      PASSWORD.to_s + d.strftime('%y%j') + random_string_digits(11)
    end

    def self.generate_guid
      require 'securerandom'
      SecureRandom.uuid
    end

  end


end
