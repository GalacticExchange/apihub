class Dashboard < ActiveRecord::Base
  belongs_to :cluster

  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter


  ### content

  def fullpath
    Gexcore::Dashboards::Service.filename(self)
  end

  def dir_path
    File.join(Rails.root, "data/dashboards", "#{self.cluster_id}")
  end

  def content
    filename =  fullpath
    return nil if filename.nil?
    return '' if !File.exists? filename
    File.read(filename)
  end

  def content=(v)
    # create directory and file if not exist
    FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)

    #work
    File.open(fullpath, "w+") do |f|
      f.write(v)
    end

  end


end
