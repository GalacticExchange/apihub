class AwsRegion < ActiveRecord::Base

  has_many :aws_region_instance_types
  has_many :aws_instance_types, through: :aws_region_instance_types

  def to_hash
    {
        id: id,
        name: name,
        title: title,
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
