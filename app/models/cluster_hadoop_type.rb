class ClusterHadoopType < ActiveRecord::Base
  DEFAULT_NAME='cdh'

  #
  has_many :clusters

  scope :w_enabled, -> { where('enabled=1') }


  def to_hash
    {
        name: self.name,
        title: self.title
    }
  end

  def self.get_by_name(name)
    row = where(name: name).first
    row
  end

  def self.get_id_by_name(name)
    row = where(name: name).first
    return nil if row.nil?

    row.id
  end
end
