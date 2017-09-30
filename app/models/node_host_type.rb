class NodeHostType < ActiveRecord::Base
  ###
  DEFAULT_NAME = 'virtualbox'
  DEDICATED = 'dedicated'
  VIRTUALBOX = 'virtualbox'

  ###
  has_many :nodes, foreign_key: 'host_type_id'


  ### callbacks
  after_save :invalidate_cache


  ###

  def self.cache_prefix
    "node_host_types:"
  end

  ### get

  def self.get_by_id(id)
    Rails.cache.fetch("#{cache_prefix}by_id:#{id}", expires_in: 24.hours) do
      where(id: id).first
    end
  end
  def self.get_by_name(name)
    Rails.cache.fetch("#{cache_prefix}by_name:#{name}", expires_in: 24.hours) do
      where(name: name).first
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
