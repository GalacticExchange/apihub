class AwsInstanceType < ActiveRecord::Base

  has_many :aws_region_instance_types
  has_many :aws_regions, through: :aws_region_instance_types

  scope :w_not_deprecated, -> { where(deprecated: nil) }
  scope :for_hadoop, -> { where(hadoop_compatible: true) }


  def to_hash
    {
        id: id,
        name: name,
    }
  end

  def self.get_by_id_or_name(name)
    row = nil
    if name.is_a?(String)
      row = where(name: name).first
    else
      row = where(id: name).first
    end

    row
  end


end
