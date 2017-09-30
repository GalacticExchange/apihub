class LogSourcesController < AccountBaseController
  autocomplete :log_source, :name, {display_id: 'name', display_value: 'name'}
  #autocomplete :log_source, :name, {display_value: 'name'}

end

