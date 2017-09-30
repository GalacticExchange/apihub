module NodeJobsState
  extend ActiveSupport::Concern


  included do

  end

  JOB_STATE_NOTSTARTED=0
  JOB_STATE_STARTED=1
  JOB_STATE_DONE=2
  JOB_STATE_FINISHED=JOB_STATE_DONE
  JOB_STATE_ERROR=3


  def reload
    super

    # invalidate my attributes
    @jobs_state_hash = nil

  end

  def jobs_state_hash
    return @jobs_state_hash unless @jobs_state_hash.nil?

    @jobs_state_hash = JSON.parse(self.jobs_state) rescue {}
    @jobs_state_hash ||= {}
    @jobs_state_hash
  end

  def save_jobs_state
    Gexcore::GexLogger.debug("node_update", "Update node jobs state - start", {node_id: id, state: jobs_state_hash.to_json})

    self.jobs_state = jobs_state_hash.to_json

    res = save

    if !res
      Gexcore::GexLogger.error("node_update", "Cannot update node in DB: save_jobs_state", {node_id: id})
    end


    # invalidate
    @jobs_state_hash = nil

    res
  end


  def update_jobs_state(job, task, new_state)
    reload

    # TODO: lock
    #self.with_lock do
      a = jobs_state_hash
      @jobs_state_hash[job] ||={}
      @jobs_state_hash[job][task] = new_state

      # update in DB
      save_jobs_state
    #end

    # reload from DB
    self.reload

    # callbacks
    after_job_state_changed(job, task, new_state)
  end

  ###
  def add_job_task(job, task)
    update_jobs_state(job, task, JOB_STATE_NOTSTARTED)
  end

  def start_job_task(job, task)
    update_jobs_state(job, task, JOB_STATE_STARTED)
  end

  def finish_job_task(job, task)
    update_jobs_state(job, task, JOB_STATE_DONE)
  end

  def set_error_job_task(job, task)
    update_jobs_state(job, task, JOB_STATE_ERROR)
  end


  ### get state for task
  def job_task_finished?(job, task)
    v = job_task_state(job, task)
    return false if v.nil?

    v = v.to_i
    v==JOB_STATE_DONE
  end

  def job_task_started?(job, task)
    v = job_task_state(job, task)
    return false if v.nil?

    v = v.to_i
    v==JOB_STATE_STARTED
  end

  def job_task_not_finished?(job, task)
    v = job_task_state(job, task)
    return false if v.nil?

    v = v.to_i
    [JOB_STATE_NOTSTARTED, JOB_STATE_STARTED].include? v
  end

  def job_task_error?(job, task)
    v = job_task_state(job, task)
    return nil if v.nil?

    v = v.to_i
    v==JOB_STATE_ERROR
  end


  ###
  def job_state(job)
    return (jobs_state_hash[job] rescue nil)
  end

  def job_task_state(job, task)
    return (jobs_state_hash[job][task] rescue nil)
  end


  ### methods for install state


  def job_finished?(job_name)
    v = job_state(job_name)
    return false if v.nil?

    #
    n = v.values.count
    n_finished = v.values.count{|x| x==Node::JOB_STATE_DONE}

    if n_finished!=n
      return false
    end

    true
  end


  def job_errors?(job_name)
    v = job_state(job_name)
    return nil if v.nil?


    n_errors = v.values.count{|x| x==Node::JOB_STATE_ERROR}

    if n_errors > 0
      return true
    end

    false
  end


  ### callbacks

  def after_job_state_changed(job_name, task_name, task_state)
    reload

    #
    Gexcore::GexLogger.info "node_job_changed", "after_job_state_changed", {node_id: id, job: job_name, task: task_name, state: task_state}

    if job_name=='install'
      return Gexcore::Nodes::Service.do_after_install_job_changed(self, task_name, task_state)
    end
    if job_name=='uninstall'
      return Gexcore::Nodes::Service.do_after_uninstall_job_changed(self, task_name, task_state)
    end

    true
  end

end



