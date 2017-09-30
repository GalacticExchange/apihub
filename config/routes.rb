Rails.application.routes.draw do
  resources :application_images

  get '/sysinfo/:action', to: 'sysinfo#action'
  get '/debug/:action', to: 'debug#action'
  get '/ping', to: 'ping#ping'

  # optimacms devise
  devise_for :cms_admin_users, Optimacms::Devise.config


  # devise for our users
  devise_for :users ,
             :controllers => {:sessions => "sessions", :passwords=>'passwords'},
             :skip => [:registrations, :confirmation],
             :path => '/',
             :path_names => {
                 :sign_in  => 'signin', :sign_out => 'signout',
             }


  # sidekiq Web UI
  #, lambda { |u| u.cms_admin_user? }
  authenticate :cms_admin_user do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end


  # internal gex routes
  scope '/gex' do
    get '/clusters/info', to: 'gex_tests#clusters_number_of', as: 'test_clusters_number_of'
    get '/nodes/number_of', to: 'gex_tests#nodes_number_of', as: 'test_nodes_number_of'
  end









  # api
  match '/auth_access_cluster', to: 'auth#auth_access_cluster', via: [:post, :get]


  ### site


  # users
  resources :users, only: [:new, :create]#, except: :index
  get '/user/:name', to: 'users#show', as: 'user'

  # teams - public
  #resources :teams, only: [:index]
  get '/team/:name', to: 'teams_public#show', as: 'team'

  # teams
  get '/teamInfo', to: 'teams#show_info'
  put '/teamInfo', to: 'teams#update'



  # clusters
  #resources :clusters, only: [:index]
  get '/cluster/:name', to: 'clusters#show', as: 'cluster'
  get '/cluster', to: 'clusters#info', as: 'cluster_info'


  get '/clusters', to: 'clusters#index', as: 'clusters'


  ### dashboard
  get '/dashboard', to: 'dashboard#index', as: 'dashboard'

  ### stats

  # html
  #get '/statistics', to: 'clusters#statistics', as: 'cluster_statistics'
  get '/statistics/nodes/:uid', to: 'nodes#statistics', as: 'node_statistics'

  # json
  scope constraints: { format: 'json' } do
    get '/stats/nodes', to: 'stats#nodes', as: 'stats_nodes'
    get '/stats/nodes_history/:uid/:type', to: 'stats#node_history', as: 'stats_node_history'
    get '/stats/nodes/:uid/:type/:last_time/:interval', to: 'stats#node', as: 'stats_node'
  end

  # monitoring
  scope constraints: { format: 'json' } do
    get '/checks/nodes', to: 'monitoring_checks#list_for_nodes', as: 'mon_checks_nodes'
    get '/checks/containers', to: 'monitoring_checks#list_for_containers', as: 'mon_checks_containers'
    get '/checks/services', to: 'monitoring_checks#list_for_services', as: 'mon_checks_services'

    # todo
    get '/checks/node/:nodeId', to: 'monitoring_checks#node', as: 'mon_checks_node'
    get '/checks/container/:containerId', to: 'monitoring_checks#container', as: 'mon_checks_container'
  end



  # search - API
  get '/search', to: 'search#index', as: 'search'
  get '/search/counters', to: 'search#search_counts', as: 'search_counts'
  get '/search/users', to: 'users#search'
  get '/search/clusters', to: 'clusters#search'
  get '/search/teams', to: 'teams_public#search'


=begin
# my
new_user_session GET      /login(.:format)                            sessions#new
                  user_session POST     /login(.:format)                            sessions#create
          destroy_user_session DELETE   /logout(.:format)                           sessions#destroy
                 user_password POST     /password(.:format)                         passwords#create
             new_user_password GET      /password/new(.:format)                     passwords#new
            edit_user_password GET      /password/edit(.:format)                    passwords#edit
                               PATCH    /password(.:format)                         passwords#update
                               PUT      /password(.:format)                         passwords#update



# original
    new_user_session GET      /users/sign_in(.:format)                    sessions#new
        user_session POST     /users/sign_in(.:format)                    sessions#create
destroy_user_session DELETE   /users/sign_out(.:format)                   sessions#destroy
=end



  # verify user
  get '/verify/:token', to: 'users#verify', as: :verify_user
  post '/users/verify', to: 'users#verify', as: :verify_user_api

  ## reset password
  get '/resetpassword/:token', to: redirect("/password/edit?reset_password_token=%{token}"), id: /[A-Za-z\d]+/
  #get "/users/password/edit", to: 'users#editpassword', as: 'editpassword'
  #put '/users/password/update', to: 'users#updatepassword', as: 'updatepassword'


  # bad token page
  get '/users_bad_token', to: 'users#bad_token', as: 'users_bad_token'



  # user thank you pages
  get '/users/created', to: 'users#result_created', as: 'user_result_created'
  get '/users/verified', to: 'users#result_verified', as: 'user_result_verified'
  get '/users/resetpasswordlinksent', to: 'users#result_resetpwdlink_sent', as: 'user_result_resetpwdlink_sent'
  get '/users/passwordchanged', to: 'users#result_password_changed', as: 'user_result_passwordchanged'


  # invite
  #get '/inviteaccept/:token', to: redirect('/userInvitations/accept/?invitationToken=%{token}'), id: /[A-Za-z\d]+/
  #get '/userInvitations/accept', to: 'invitations#accept'
  get '/inviteaccept/:token', to: 'invitations_accept#accept', as: :accept_invitation


  # clusters

  # nodes
  get "/nodes", to: 'nodes#index', as: 'nodes'
  #get '/nodes/statuses', to: 'nodes#index_performance', as: :nodes_statuses
  #get '/nodes/performance', to: 'nodes#index_performance', as: :nodes_performance
  get '/nodes/:nodeID/info', to: 'nodes#show', as: 'node'
  post '/nodes/:nodeID/uninstall', to: 'nodes#uninstall', as: 'uninstall_node'
  delete '/nodes/:id', to: 'nodes#destroy', as: :delete_node
  get '/nodes/:nodeID/settings', to: 'nodes#edit', as: 'edit_node'
  get '/nodes/:nodeID/send_command', to: 'nodes#send_command', as: 'send_command_node'

  get '/nodes/check_name', to: 'nodes#check_name', as: 'check_node_name'
  get '/nodes/get_name', to: 'nodes#get_name', as: 'get_name'




  ### autocomplete
  get '/autocomplete_log_type_name' => 'log_types#autocomplete_log_type_name', as: 'autocomplete_log_type_name'
  get '/autocomplete_log_source_name' => 'log_sources#autocomplete_log_source_name', as: 'autocomplete_log_source_name'
  get '/autocomplete_user_username' => 'users#autocomplete_user_username', as: 'autocomplete_user_username'
  get '/autocomplete_team_name' => 'teams#autocomplete_team_name', as: 'autocomplete_team_name'
  get '/autocomplete_cluster_name' => 'clusters#autocomplete_cluster_name', as: 'autocomplete_cluster_name'
  get '/autocomplete_node_name' => 'nodes#autocomplete_node_name', as: 'autocomplete_node_name'


  # profile
  scope '/profile' do
    ## PROFILE
    #get "/show", to: 'profiles#show', as: 'profileshow'
    get "/edit", to: 'profiles#edit', as: 'profileedit'
    put '/update', to: 'profiles#update', as: 'profileupdate'
    get "/password/edit", to: 'profiles#editpassword', as: 'profileeditpassword'
    put '/password/update', to: 'profiles#updatepassword', as: 'profileupdatepassword'
    get "/edit_avatar", to: 'profiles#edit_avatar', as: 'avataredit'
    put '/update_avatar', to: 'profiles#update_avatar', as: 'avatarupdate'

    #get "/test", to: 'profiles#testupl', as: 'test'


    ## team
    #get '/team/show', to: 'profiles#show_team', as: 'team_show'
    get "/team/edit", to: 'profiles#edit_team', as: 'edit_team'
    put '/team/update', to: 'profiles#update_team', as: 'update_team'
    get "/team/edit_avatar", to: 'profiles#edit_avatar_team', as: 'avataredit_team'
    put '/team/update_avatar', to: 'profiles#update_avatar_team', as: 'avatarupdate_team'
    get "/team/members", to: 'profiles#team_members', as: 'members_team'
    get "/team/invitations", to: 'profiles#team_inv', as: 'team_invitations'


    ## cluster
    get "/cluster/my_clusters", to: 'profiles#my_clusters', as: 'my_clusters'
    get "/cluster/shared_clusters", to: 'profiles#shared_clusters', as: 'shared_clusters'
    get "/cluster/all_clusters", to: 'profiles#cluster_all', as: 'all_clusters'
    get "/cluster/show", to: 'profiles#show_cluster', as: 'show_cluster'
    get "/cluster/show_shared", to: 'profiles#show_shared_cluster', as: 'show_shared_cluster'



    ## messages, dialogs
    get '/dialogs', to: 'dialogs#index', as: 'dialogs'
    get "/dialogs/show", to: 'dialogs#show', as: 'dialog'

    #
    resources :messages, only: [:new, :create, :destroy]


  end



  ### HADOOP APP

  get '/hadoop_spark', to: 'hadoop_applications#hadoop_spark', as: 'hadoop_spark'



  ### APPSTORE


  # apphub

  get '/apphub/search', to: 'apphub#index', as: 'apphub'
  get '/apphub/app', to: 'apphub#show', as: 'apphub_app'
  get '/apphub/app/install', to: 'apphub#install', as: 'apphub_app_install'


  resources :library_application

  get '/appstore/applications', to: 'library_applications#index', as: 'appstore'
  get '/appstore/application/:name', to: 'library_applications#show', as: 'show_app_appstore'


  ### cluster applications
  get '/clusters/:cluster_uid/applications', to: 'cluster_applications#index', as: 'cluster_applications'
  get '/clusters/:cluster_uid/applications/:uid', to: 'cluster_applications#show', as: 'cluster_application'

  #get '/applications/:uid', to: 'cluster_applications#show', as: 'cluster_application'
  #get 'clusters/:cluster_id/applications/:uid/:include_images', to: 'cluster_applications#show', as: 'cluster_application'

  delete '/applications', to: 'cluster_applications#destroy', as: 'destroy_cluster_application'
  get '/applications/:uid/panel', to: 'cluster_applications#panel', as: 'cluster_application_panel'
  get '/clusters/:cluster_uid/applications/:uid/settings', to: 'cluster_applications#edit', as: 'cluster_application_edit'

  #get '/applications/new', to: 'cluster_application#create', as: 'applications'

  # todo: finish install_compose_app and install_apphub_app and remove it
  post '/applications', to: 'cluster_applications#create', as: 'create_application'
  post '/applications_new', to: 'cluster_applications#create_new', as: 'create_application_new'

  post '/gex_applications', to: 'cluster_applications#create_gex_app', as: 'create_gex_app'

  get '/clusters/:cluster_id/applications/:name/install_config', to: 'cluster_applications#install_config', as: 'install_config_application'
  #post '/clusters/:cluster_id/applications/:name/install_config_update', to: 'cluster_applications#install_config_create', as: 'install_config_create_application'

  get '/check_app_requirements', to: 'cluster_applications#check_requirements', as: 'app_check_requirements'


  get '/clusters/:cluster_id/apps/install_config_external', to: 'cluster_applications#install_config_external', as: 'install_config_external_application'

  post '/applications/:uid/uninstall', to: 'cluster_applications#uninstall', as: 'uninstall_app'

  post '/applications/update_comments', to: 'cluster_applications#update_comments', as: 'cluster_application_update_comments'
  #get '/applications/:id/edit', to: 'cluster_application#edit'
  #put '/applications/:id', to: 'cluster_application#update'



  ### cluster containers
  get '/clusters/:cluster_uid/containers/:uid', to: 'cluster_containers#show', as: 'cluster_container'
  get '/clusters/:cluster_uid/containers/:uid/settings', to: 'cluster_containers#edit', as: 'cluster_container_edit'
  get '/clusters/:cluster_uid/containers/', to: 'cluster_containers#index', as: 'cluster_containers'


  # files
  get '/files', to: 'files#list'
  get '/files/download', to: 'files#download'


  ### API

  scope constraints: { format: 'json' } do
    # auth
    post '/login', to: 'auth#login'
    match '/logout', to: 'auth#logout', via: [:post, :delete]
    post '/tokens/refresh', to: 'auth#refresh_token'


    # log
    post '/log', to: 'log_create#create' # remove later
    post '/logs', to: 'log_create#create'
    match '/logs', to: 'log#index', via: [:get]
    match '/logs/search', to: 'log#index', via: [:post]


    # users
    #post '/users', to: 'users#create'
    #post '/users/verify', to: 'users#verify'
    get '/userInfo', to: 'users#show_info'
    put '/userInfo', to: 'users#update'
    delete '/users', to: 'users#destroy'
    put '/users/roles', to: 'users#update_role'

    get '/teamUsers', to: 'users#list_of_team'
    
    post '/users/password/resetlink', to: 'users#send_password_resetlink'
    put '/users/password', to: 'users#update_password'

    get '/groupList', to: 'teams#group_list'

    # clusters
    get '/clusters/new', to: 'clusters#new'
    post '/clusters', to: 'clusters#create', as: 'create_cluster'
    delete '/clusters', to: 'clusters#destroy'
    delete '/clusters_full', to: 'clusters#destroy_all'
    get '/teamClusters', to: 'clusters#list_of_team'
    get '/clusters/:clusterID/info', to: 'clusters#show_info'
    get '/clusterInfoContainersAll', to: 'clusters#show_info_containers_all'
    get '/no_cluster',  to: 'clusters#no_cluster'
    get '/clusters/wizard',  to: 'clusters#wizard'



    get '/clusters/components',  to: 'clusters#components_list'
    get '/clusters/:clusterID/components', to: 'clusters#components'

    # keys
    get '/keys',  to: 'keys#index'
    post '/key/add/:type',  to: 'keys#create'
    delete '/keys',  to: 'keys#remove'

    # nodes
    post '/nodes', to: 'nodes#create'
    post '/nodes/add', to: 'nodes#add'
    put '/nodes', to: 'nodes#update'
    put '/gexd/nodes', to: 'nodes_agent#update'
    delete '/nodes', to: 'nodes#destroy'

    get '/nodePropertiesInstall', to: 'nodes#show_properties_install'
    get '/nodeInfoContainersAll', to: 'nodes#show_info_containers_all'
    #get '/nodes/performance', to: 'nodes#list_performance'



    # node agents
    post '/nodeAgentInfo', to: 'node_agent#update_agent_info'
    get '/nodeAgentInfo', to: 'node_agent#get_agent_info'
    get '/nodeAgents', to: 'node_agent#get_agents'

    # properties
    get '/properties', to: 'properties#show'
    get '/hadoopTypes', to: 'properties#hadoop_types_list'


    # services
    get '/services', to: 'cluster_services#index'
    #get '/serviceInfo', to: 'cluster_services#show_info'

    # containers
    get '/containers', to: 'cluster_containers#index'
    put '/containers', to: 'cluster_containers#update'


    # service ip
    get '/serviceIp', to: 'dns#resolve'
    post '/serviceIp', to: 'dns#update_ip'



    # invitations
    post '/userInvitations', to: 'invitations#create'
    post '/shareInvitations', to: 'invitations#create_share'
    post '/userInvitations/validate', to: 'invitations_accept#validate'
    get '/userInvitations', to: 'invitations#index'
    get '/shareInvitations', to: 'invitations#index_share'
    delete '/invitations', to: 'invitations#destroy', as: "invitation_delete"

    # notifications
    post '/notify', to: 'notifications#create'

    # messages
    post '/messages', to: 'messages#create'
    get '/messages', to: 'messages#index'
    get '/messages/unread/count', to: 'messages#count_unread'
    get '/messagedialogs', to: 'api_dialogs#list'
    get '/messagedialogInfo', to: 'api_dialogs#show_info'


    # packages
    get '/packages', to: 'packages#list_installed'
    get '/packages/supported', to: 'packages#list_supported'

    # shares
    post '/shares', to: 'shares#create', as: 'shares_create'
    delete '/shares', to: 'shares#destroy'

    get '/userShares', to: 'shares#list_users', as: 'shares_list_users'
    get '/clusters/shared', to: 'shares#list_clusters', as: 'shares_list_clusters'
    get '/pendingShares', to: 'shares#list_pending', as: 'shares_list_pending'

    #todo: deprecated
    get '/clusterShares', to: 'shares#list_clusters', as: 'shares_list_clusters_old'

    # permissions
    get '/permissions/check/:operation', to: "permissions#check"

    # instances
    post '/applicationRegistrations', to: 'instances#create'#, as: 'instances_create'

  end


  get '/shares', to: 'shares#main', as: 'shares_main'
  get "/shares/new", to: 'shares#new', as: 'shares_new'
  get "/share_del/:username", to: 'shares#destroy', as: 'share_del'


  get "/aws/instance_types", to: "aws#instance_types", as: 'aws_instance_types'


  #get "/inv_del/:id", to: 'invitations#destroy', as: 'inv_del'
  #TMP!
  #resources :library_applications


  # with redirect
  get 'profile/change_current_cluster', to: 'account_base#change_current_cluster', :as => :profile_change_current_cluster
  # json version
  post 'clusters/change', to: 'base#change_current_cluster', :as => :change_current_cluster


  # youtrack
  get 'utrack/users', to: 'utrack#users', as: 'utrack_users'


  ### admin
  scope '/'+Optimacms.admin_namespace do
    #scope module: 'admin', as: 'admin' do
    #get '/my', to: 'log_system#my', as: :my
    # get '/papa', to: 'log_system#papa', as: :papa
    #end
    scope module: 'admin', as: 'admin' do
      resources :log_debug, only: [:index] do
        collection do
          post 'search'
        end
        #get 'show_data', to: 'log_debug#show_data', on: :member
        #get '/log_debug/:pid/show_data', to: 'log_debug#show_data'

        get 'show_data', on: :member
      end

      #post '/log_debug', to: 'log_debug#index'

      resources :log_db, only: [:index] do
        collection do
          post 'search'
        end
        get 'show_data', on: :member
      end


      # for teams
      resources :teams, only: [:index, :show] do
        collection do
          post 'search'
          get 'autocomplete_team_name'
        end
      end

      # for users
      resources :users, only: [:index, :show, :new, :create] do
        collection do
          post 'search'
          get 'autocomplete_user_username'

          get 'generate'
        end

        member do
          get 'get_token'
          get 'show_nodes_perf'
        end
      end

      # user_status_for_admin
      get '/edit_user_status/:id', to: 'users#edit_status', as: 'edit_user_status'
      put '/edit_user_status/:id', to: 'users#update_status', as: 'update_user_status'

      # user_note_for_admin
      get '/edit_user_admin_notes/:id', to: 'users#edit_notes', as: 'edit_user_notes'
      put '/edit_user_admin_notes/:id', to: 'users#update_notes', as: 'update_user_notes'

      # change user password for admin
      get '/password_edit/:id', to: 'users#editpassword_from_admin', as: 'admineditpassword'
      put '/password_edit/:id', to: 'users#updatepassword_from_admin', as: 'adminupdatepassword'

      # login as user
      get '/sign_in_as_user', to: 'users#login_as_user', as: 'login_as_user'

      # verify user from another country (not [US, UA])
      get '/verify_user', to: 'users#verify_user', as: 'verify_user'

      # for clusters
      resources :clusters, only: [:show, :index] do
        collection do
          post 'search'
          get 'autocomplete_cluster_name'
        end

        member do
          get 'nodes_performance', to: 'monitoring#show_nodes'
          get 'run_operation'
          get 'run_provision_script'
          get 'get_info_containers'
          get 'run_fix_status'
          get 'commands/test', to: 'clusters#cmd_test'
        end
      end

      # cluster_note_for_admin
      get '/edit_cluster_admin_notes/:id', to: 'clusters#edit_notes', as: 'edit_cluster_notes'
      put '/edit_cluster_admin_notes/:id', to: 'clusters#update_notes', as: 'update_cluster_notes'

      # cluster_options_for_admin
      get '/edit_cluster_options/:id', to: 'clusters#edit_options', as: 'edit_cluster_options'
      put '/edit_cluster_options/:id', to: 'clusters#update_options', as: 'update_cluster_options'

      # monitoring
      get 'monitoring/servers', to: 'monitoring#show_servers'


      # for nodes
      resources :nodes, only: [:show, :index] do
        collection do
          post 'search'
          get 'autocomplete_node_name'
        end

        member do
          get 'send_command'
          get 'get_info_containers'
        end
      end

      # for invitations
      resources :invitations, only: [:index] do
        collection do
          post 'search'
        end
      end

      # for messages
      resources :messages, only: [:index] do
        collection do
          post 'search'
        end
      end

      # for message_dialogs
      resources :message_dialogs, only: [:index] do
        collection do
          post 'search'
          get 'autocomplete_message_dialog_name'
        end
      end

      # log_sources
      resources :log_sources do
        collection do
          post 'search'
          get 'autocomplete_log_source_name'

        end
      end


      # for log_types
      resources :log_types do
        collection do
          post 'search'
          get 'autocomplete_log_type_name'

        end
      end

      # settings
      resources :settings, only: [:index] do

      end

      # for Maintenance
      resources :maintenance, only: [:index] do
        collection do
          post 'search'
          #get 'refresh_index'
          get 'import_index'
          get 'pull_ansible'
          get 'import_log_debug_index'
          get 'import_library_application_index'
          get 'git_pull_chef'

          get 'yt_update_users'
          get 'yt_force_update_users'

          get 'add_models_to_elastic'
        end

      end


      # for rails_logs
      resources :rails_logs, only: [:index] do
        #get 'get_dev_logs', on: :member
      end
      get 'get_log/:name', to: "rails_logs#get_logs", as: 'get_log'

      # for cluster_containers
      resources :cluster_containers, only: [:index, :show] do
        collection do
          post 'search'
          get 'autocomplete_cluster_container_name'
        end
      end

      # for cluster_applications
      resources :cluster_applications, only: [:index, :show] do
        collection do
          post 'search'
          get 'autocomplete_cluster_application_name'
        end

        member do
          get 'send_command'
        end

      end

      # for cluster_services
      resources :cluster_services, only: [:index, :show] do
        collection do
          post 'search'
        end
      end

      # cluster services
      get '/cluster_service_connect_webproxy', to: 'cluster_services#connect_webproxy', as: :cluster_service_connect_webproxy

      # for cluster_dashboards
      resources :dashboards do
        collection do
          post 'search'
        end
      end


      # for library_applications
      resources :library_applications do

        #put '', to: 'admin/library_applications#update', :as => :update

        collection do
          post 'search'
          get 'autocomplete_library_application_name'
        end
      end

      # for library_services
      resources :library_services do
        collection do
          post 'search'
          get 'autocomplete_library_service_name'
        end
      end

      # for instances
      resources :instances do
        collection do
          post 'search'
          get 'autocomplete_instance_uid'
        end

        member do
          # instances admin_notes for admin
          get 'edit_admin_notes'#, to: 'instances#edit_admin_notes', as: 'edit_admin_notes'
          put 'update_admin_notes'#, to: 'instances#update_admin_notes', as: 'update_admin_notes'
        end
      end

      # instances admin_notes for admin
      #get '/edit_instance_admin_notes/:id', to: 'instances#edit_admin_notes', as: 'edit_admin_notes'
      #put '/edit_instance_admin_notes/:id', to: 'instances#update_admin_notes', as: 'update_admin_notes'

    end

  end



  # for names
  root to: "home#index"
  get "/teampl", to: 'home#teampl', as: 'teampl'
  get "/info/license_agreement", to: 'public#license', as: 'license_agreement'


  get "/workspace", to: 'workspace#index', as: 'workspace_index'
  get "/profile_settings", to: 'profile_settings#index', as: 'profile_settings_index'
  get "/clusters_manage", to: 'clusters_manage#index', as: 'clusters_manage_index'


  get "/customer_email", to: 'users#customer_email', as: 'customer_email'





  # NODE INSTALL
  get "/node_install", to: 'node_install#main', as: 'node_install'


  #resources :base do
  #  get "/change_current_cluster", :to => "base#change_current_cluster", :as => "change_current_cluster"
  #end


  # optimaCMS modules
  mount OptimacmsOptions::Engine => "/", :as => 'cms_options'
  mount OptimacmsBackups::Engine => "/", :as => "cms_backups"

  # !!! LAST row
  mount Optimacms::Engine => "/", :as => "cms"


  #get '*not_found', to: 'errors#error_404'

  ## ok - 2016-02-24
  match '*unmatched_route', :to => 'api_base#raise_not_found!', :via => :all



end
