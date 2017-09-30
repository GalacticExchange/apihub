class Admin::MaintenanceController < Admin::MyAdminBaseController

  def index

  end

  def import_index
    Maintenance::Maintenance.es_import_index

    respond_to do |format|
      format.html {      }
      format.json{
        render :json=>{:res=> 1, :output => 'users, teams, clusters is indexed'}
      }
    end
  end

  def pull_ansible
    res_output = Maintenance::Maintenance.update_ansible_dir

    respond_to do |format|
      format.html {      }
      format.json{        render :json=>{:res=> 1, :output => res_output}      }
    end
  end

  def import_log_debug_index
    Maintenance::Maintenance.es_import_log

    respond_to do |format|
      format.html {      }
      format.json{        render :json=>{:res=> 1, :output => 'log_debug is indexed'}      }
    end
  end


  def import_library_application_index
    Maintenance::Maintenance.es_import_library_apps

    respond_to do |format|
      format.html {      }
      format.json{        render :json=>{:res=> 1, :output => 'library_application is indexed'}      }
    end
  end

  def git_pull_chef
    ##
    cmd = ("cd " + "#{Gexcore::Settings.chef_dir}" + " 2>&1" + " && git pull origin master" + " 2>&1")
    res_output = %x[#{cmd}]
    exit_code = $?.exitstatus

    if exit_code.to_i>0
      output = "exit_code = #{exit_code}; message: #{res_output}"
    else
      output = "exit_code = #{exit_code}; message: #{res_output}"
    end

    output

    respond_to do |format|
      format.html {      }
      format.json{        render :json=>{:res=> 1, :output => res_output}      }
    end
  end


  def yt_update_users
    res = Maintenance::Maintenance.run_rake_task('youtrack:update_all')

    respond_to do |format|
      format.html {      }
      format.json{        render :json=>{:res=> 1, :output => res}      }
    end

  end

  def yt_force_update_users
    res = Maintenance::Maintenance.run_rake_task('youtrack:force_update_all')

    respond_to do |format|
      format.html {      }
      format.json{        render :json=>{:res=> 1, :output => res}      }
    end

  end

  def add_models_to_elastic
    res = Maintenance::Maintenance.run_rake_task('logs:add_models_to_elactic')

    respond_to do |format|
      format.html {      }
      format.json{        render :json=>{:res=> 1, :output => res}      }
    end

  end


end
