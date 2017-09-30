class Admin::MyAdminBaseController < BaseController
  before_action :authenticate_cms_admin_user!

  layout 'optimacms/admin/layouts/main'



end
