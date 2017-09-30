module NgRoutes
  NODES = '/workspace#/clusters/{cluster_id}/nodes'
  NODES_INST_ONPREM = '/workspace#/clusters/{cluster_id}/nodes/install/choose'
  NODES_INST_AWS = '/workspace#/clusters/{cluster_id}/nodes/install/aws'
  NODES_INST_APP_ONLY = '/workspace#/clusters/{cluster_id}/nodes/install/app-only'
  CLUSTERS ='/clusters_manage#/clusters'
  APPLICATIONS_INFO = '/workspace#/clusters/{cluster_id}/applications/{application_id}'
  CLUSTERS_NEW_WIZARD ='/clusters_manage#/clusters/new/wizard'
  CLUSTER_STATISTIC = '/workspace#/clusters/{cluster_id}/statistics'
  SEARCH = '/search#/search/users'

  PROFILE_EDIT = '/profile_settings#/users/{username}/mainInfo'
  TEAM_EDIT = '/clusters_manage#/team/edit'
  TEAM_MEMBERS = '/clusters_manage#/team/members'

  CONTAINERS ='/workspace#/clusters/{id}/containers'
  LIBRARY_APP_LIST = '/workspace#/clusters/{cluster_id}/apphub/applications'
  APPLICATIONS = '/workspace#/clusters/{cluster_id}/applications'
end
