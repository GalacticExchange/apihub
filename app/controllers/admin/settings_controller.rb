class Admin::SettingsController < Admin::MyAdminBaseController

  def index


    @gex_config = Gexcore::Settings.gex_config
  end
end
