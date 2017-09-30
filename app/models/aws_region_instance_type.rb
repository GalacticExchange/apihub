class AwsRegionInstanceType < ApplicationRecord

  belongs_to :aws_region
  belongs_to :aws_instance_type

end
