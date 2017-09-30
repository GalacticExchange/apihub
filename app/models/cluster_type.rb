class ClusterType < ActiveRecord::Base
  ##
  DEFAULT_NAME = 'onprem'
  ONPREM = 'onprem'
  AWS = 'aws'

  ###
  has_many :clusters, foreign_key: 'cluster_type_id'

  ### callbacks
  after_save :invalidate_cache

  ###
  def self.cache_prefix
    "cluster_types:"
  end


  ### get

  def self.get_by_id(id)
    r = Rails.cache.fetch("#{cache_prefix}by_id:#{id}", expires_in: 24.hours) do
      where(id: id).first
    end
  end
  def self.get_by_name(name)
    r = Rails.cache.fetch("#{cache_prefix}by_name:#{name}", expires_in: 24.hours) do
      row = where(name: name).first
    end
  end

  def self.get_by_name_with_default(name)
    name ||= DEFAULT_NAME
    get_by_name(name)
  end



  private
  def invalidate_cache
    keys = [
        "#{cache_prefix}by_name:#{self.name}",
        "#{cache_prefix}by_id:#{self.id}",
    ]

    keys.each do |key|
      Rails.cache.delete(key)
    end

  end

end
