module Optimacms
  module AdminMenu
    class AdminMenu
      include Optimacms::Concerns::AdminMenu::AdminMenu

      def self.cms_admin_page_path(u)
        '/'+Optimacms.admin_namespace+u
      end

      def self.make_page(t, u)
        {title: t, url: cms_admin_page_path(u) }
      end

      def self.get_menu_custom
        [
            {
                title: 'Users', route: nil,
                submenu:
                [
                    make_page('Users', '/users'),
                    make_page('Teams', '/teams'),
                    make_page('Invitations', '/invitations'),
                    make_page('Messages', '/messages'),
                ]
            },

            {
                title: 'Clusters', route: nil,
                submenu: [
                    make_page('Instances', '/instances'),
                    make_page('Clusters', '/clusters'),
                    make_page('Nodes', '/nodes'),
                    make_page('Containers', '/cluster_containers'),
                    make_page('Applications', '/cluster_applications'),
                    make_page('Services', '/cluster_services'),
                    make_page('Dashboards', '/dashboards'),
            ]
            },
            {
                title: 'Logs', route: nil,
                submenu: [
                    make_page('Log', '/log_debug'),
                    make_page('Current', '/log_db'),
                    make_page('Types', '/log_types'),
                    make_page('Rails logs', '/rails_logs'),

                ]
            },
          {
              title: 'Monitoring', route: nil,
              submenu: [
                  make_page('Servers', '/monitoring/servers'),
              ]
          },
          {
              title: 'Settings', route: nil,
              submenu: [
                  make_page('App settings', '/settings'),
                  make_page('Options', '/options'),
              ]
          },

          {
              title: 'Maintenance', route: nil,
              submenu: [
                  make_page('Maintenance', '/maintenance'),
                  {title: 'Backups', url: '/'+Optimacms.admin_namespace+'/backups' },
              ]
          },

          {
              title: 'Appstore-Library', route: nil,
              submenu: [
                  make_page('Applications', '/library_applications'),
                  make_page('Services', '/library_services'),
              ]
          }


        ]
      end

    end
  end
end
