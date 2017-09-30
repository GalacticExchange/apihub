module Gexcore
  class LogService < BaseService
    def self.create_filter_from_params(params, _session, opts={})
      #
      filter = SimpleSearchFilter::Filter.new(_session, 'log_search_', {})

      if !(opts[:save_session].nil?) && opts[:save_session]==false
        filter.clear_all

      end

      # input
      # TODO: fix - x=y if a || b, || when???

      limit = params['limit'] || (params['filter']['itemsPerPage'] if params['filter']) || 10
      skip = params[:skip] || 0

      date_from = Gexcore::Common.parse_date(params['dateFrom'])

      date_to = Gexcore::Common.parse_date(params['dateTo'])
      date_to = DateTime.new(date_to.year, date_to.month, date_to.day, 23, 59, 59) unless date_to.nil?

      # user
      user_id = params['user_id'] || (params['filter']['user_id'] if params['filter']) || nil
      if user_id.nil?
        username = params['username'] || (params['filter']['user'] if params['filter']) || nil
        if username.present?
          user = User.get_by_username username
        end
      else
        user = User.find(user_id) if user_id.to_i > 0
      end

      # team
      team_id = params['team_id'] || (params['filter']['team_id'] if params['filter']) || nil

      # node
      node_uid = params['nodeID'] || nil
      node_name = params['node'] || (params['filter']['node'] if params['filter']) || nil
      if node_uid
        node = Node.get_by_uid(node_uid)
        node_id = node.id if node.present?
      elsif node_name
        node = Node.get_by_name(node_name)
        node_id = node.id if node.present?
      end

      # source
      source_name = params['source'] || (params['filter']['source'] if params['filter']) || nil
      source = LogSource.get_by_name(source_name) if source_name

      # type
      type_name = params['type'] || (params['filter']['type'] if params['filter']) || nil
      type = Gexcore::LogFromElasticsearch.log_type_search_by_id_or_name(nil, type_name) if type_name
      #type = LogType.get_by_name(type_name) if type_name

      # cluster
      cluster_name = params['cluster'] || (params['filter']['cluster'] if params['filter']) || nil
      cluster = Cluster.get_by_name(cluster_name) if cluster_name

      #
      if params['minLevel']
        level_name = Gexcore::GexLogger.level_base_name params['minLevel']
        min_level = (Gexcore::GexLogger.level_number level_name).to_i
      elsif params['filter']
        level_name = Gexcore::GexLogger.level_base_name params['filter']['min_level']
        #min_level = (params['filter']['min_level']).to_i
        min_level = (Gexcore::GexLogger.level_number level_name).to_i
      else
        min_level = 0
      end

      #
      q = params['q'] || (params['filter']['q'] if params['filter']) || nil



      # define filter
      filter.set_default_order 'id', 'desc'

      filter.field 'q', :string,  :text, {
                                label: 'Search all',
                                default_value: '', ignore_value: '', condition: :empty
                            }

      filter.field 'team_id', :int, :text, {
                                label: 'Team',
                                default_value: 0, ignore_value: 0
                            }


      filter.field 'user_id', :int, :text, {
                                label: 'User',
                                default_value: 0, ignore_value: 0
                                }

      filter.field 'min_level', :int, :text, {
                                  label: 'Level',
                                  default_value: 0, ignore_value: 0,
                                  condition: :custom, condition_where: 'level >= ?'}

      filter.field 'source_id', :int, :text, {
                                  label: 'Source',
                                  default_value: 0, ignore_value: 0,
                                }

      filter.field 'type_id', :int, :text, {
                                  label: 'Type',
                                  default_value: 0, ignore_value: 0,
                                }

      filter.field 'node_id', :int, :text, {
                                  label: 'Node',
                                  default_value: 0, ignore_value: 0,
                                }

      filter.field 'cluster_id', :int, :text, {
                                  label: 'Cluster',
                                  default_value: 0, ignore_value: 0,
                                }

      filter.field 'date_from', :string, :text, {
                                  label: 'Date from',
                                  default_value: '', ignore_value: '',
                                  condition: :custom, condition_where: 'created_at >= ?'}

      filter.field 'date_to', :string, :text, {
                                  label: 'Date to',
                                  default_value: '', ignore_value: '',
                                  condition: :custom, condition_where: 'created_at <= ?'}

      filter.field 'visible_client', :int, :text, {
                                  label: 'Visible client',
                                  default_value: 0, ignore_value: 0,
                              }

      # set values
      filter.set 'skip', skip
      filter.set 'limit', limit
      # pg
      filter.page = params['pg'] || (params['filter']['pg'] if params['filter']) || 1
      # per_page
      #filter.per_page = limit

      if user.present?
        filter.set 'user_id', user.id
      else
        if username.present?
          filter.set 'user_id', -1
        end
      end

      filter.set 'team_id', team_id if team_id.present?

      filter.set 'node_id', node.id if node.present?

      filter.set 'min_level', min_level if min_level.present?

      filter.set 'type_id', type.id if type.present?

      filter.set 'cluster_id', cluster.id if cluster.present?

      filter.set 'q', q

      filter.set 'source_id', source.id if source.present?

      filter.set 'date_from', date_from if date_from.present?
      filter.set 'date_to', date_to if date_to.present?


      # order
      filter.set_order 'id', 'desc'

      #
      filter
    end



    def self.search_by_user(user, params, _session)
      # check permissions
      return Response.res_error_forbidden('forbidden', 'No permissions to view log') unless user.can?(:view_log, user.team)

      #
      if params['username']
        return Response.res_error_badinput('badinput', 'User does not exist') unless User.get_by_username params['username']
      end

      #
      filter = create_filter_from_params(params, _session)

      # team
      team = user.team
      filter.set 'team_id', team.id

      # visible_client
      filter.set 'visible_client', 1

      # get
      res_es, items = Gexcore::LogDebugSearchService.search_by_filter(filter)

      Response.res_data(Gexcore::LogDebugSearchService.to_hash(res_es))

    end

  end
end
