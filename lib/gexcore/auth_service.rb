module Gexcore
  class AuthService < BaseService
    TOKEN_TTL_HOURS = 24*30

    #### auth

    ### auth with DB -> return JWT
    def self.auth(username, pwd, data={})
      username||=''
      return Response.res_error('', 'no credentials provided', "username is empty",  400) if username.blank?

      #
      user = User.get_by_username_or_email(username)
      return Response.res_error('', 'user not found', "user not found: username=#{username}",  400) if !user

      # auth with DB
      if pwd.blank?
        return Response.res_error_badinput('', 'Password empty')
      end

      # authenticate by DB
      res_auth = user.valid_password?(pwd)
      return Response.res_error('', 'Bad username or password', 'bad username or pwd', 401) if !res_auth

      # should be active
      if user && !user.active?
        return Response.res_error('auth_not_verified', 'user not verified', "user not verified: status=#{user.status}",  401)
      end

      #
      token = jwt_generate user

      # update data
      Gexcore::ClustersAccessService.redis_update_clusters_access(user)

      # response
      Response.res_data(
          {
              token: token,
              teamID: user.team.uid
          }
      )
    end



    ###
    def self.get_new_token(user)
      token = jwt_generate user

      # update data
      Gexcore::ClustersAccessService.redis_update_clusters_access(user)


      token
    end

    ### user

    def self.can_user_login(user)
      return false unless user.active?

      true
    end

    ##### validate token

    # returns Response
    def self.validate_token(token)
      data = jwt_decode(token)

      res = Response.new
      res.sysdata[:data] = data

      return res.set_error('token_invalid', 'Token invalid', 'cannot parse token') if data.nil?

      # expiration
      if token_expired?(data)
        return res.set_error('token_expired', 'Token expired', 'token expired')
      end


      # invalidated
      if jwt_invalidated?(token)
        return res.set_error('token_invalid', 'Token invalid', 'token was invalidated')
      end

      # data
      if data['username'].nil?
        return res.set_error('token_invalid', 'Token invalid', 'bad data in token')
      end

      # user is active
      user = User.get_by_username_or_email(data['username'])
      if user.nil? || !user.active?
        return res.set_error('token_invalid', 'User is deleted', 'token for deleted user')
      end

      # Ok
      res.set_data(
          {
              username:  data['username']
          }
      )
    end

    def self.refresh(token, node_agent_token)
      res = Response.new

      # try to decode token
      data = jwt_decode(token)
      return res.set_error_badinput('token_invalid', 'Token invalid', '') if data.nil?

      #
      username = data['username']
      user = User.get_by_username(username)

      # find node
      node = Node.get_by_agent_token node_agent_token
      return res.set_error_badinput('node_agent_token_invalid', 'Node agent token invalid', 'cannot find node by token') if node.nil?

      # check node belongs to user
      cluster = Cluster.get_by_id(node.cluster_id)
      if user.team_id != cluster.team_id
        return res.set_error_forbidden('', 'Wrong node', '')
      end


      # OK. => generate new token
      token = jwt_generate user


      # response
      Response.res_data(
          {
              token: token
          }
      )
    end


    ### invalidate token
    def self.invalidate_token(token)
      jwt_invalidate(token)

      #
      Response.res_data
    end


    ### expiration
    def self.exp_from_now(ttl_hours = TOKEN_TTL_HOURS)
      ttl_hours.hours.from_now.to_i
    end

    def self.token_expired?(token_data)
      t = Time.at(token_data['exp'].to_i)
      if t.past?
        return true
      end
      return false
    end


    #### JWT token

    def self.jwt_encode(payload, ttl_hours = TOKEN_TTL_HOURS)
      payload = payload.dup
      payload['exp'] = exp_from_now(ttl_hours)
      JWT.encode(payload, config.jwt_secret)
    end

    def self.jwt_decode(token)
      res = nil
      begin
        res = JWT.decode(token, config.jwt_secret, true, {verify_expiration: false}).first
      rescue => e
        res = nil
      end

      res
    end


    def self.jwt_generate(user)
      jwt_encode({username: user.username, user_id: user.id}, TOKEN_TTL_HOURS)
    end

    def self.jwt_invalidate(token)
      key = redis_key_tokens_blacklist
      exp = exp_from_now

      $redis.zadd key, exp, token

      return true
    end

    def self.jwt_invalidated?(token)
      key = redis_key_tokens_blacklist
      now = Time.now.utc.to_i

      # remove old
      $redis.zremrangebyscore key, 0, now

      #
      v = $redis.zscore key, token

      return false if v.nil?

      return true
    end

    def self.redis_key_tokens_blacklist
      config.redis_prefix+':tokens:blacklist'
    end



    ### agent token
    def self.validate_agent_token(agent_token)
      res = Gexcore::Response.new

      if agent_token.nil? || agent_token.empty?
        return res.set_error_forbidden('','Authorization token not set', "Token not set")
      end

      # validate token
      is_valid = false

      # find node by token
      node = Node.get_by_agent_token(agent_token)
      if node && !node.removed?
        is_valid = true
      end

      if !is_valid
        gex_logger.debug 'debug_auth_agent_token_invalid', 'Invalid agent token', {agent_token: agent_token}

        return res.set_error_forbidden('auth_agent_token_invalid', 'Invalid agent token', "Token invalid")
      end


      return res.set_data(
          {
            node_id: node.id,
            node_uid: node.uid
          })
    end


  end
end

