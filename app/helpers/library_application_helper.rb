module LibraryApplicationHelper

  def app_installed(lib_app)
     @current_cluster.applications.w_not_deleted.where(library_application_id: lib_app.id).first
  end


end
