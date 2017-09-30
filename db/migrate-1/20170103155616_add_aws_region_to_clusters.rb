class AddAwsRegionToClusters < ActiveRecord::Migration
  def change
    add_column :clusters, :aws_region, :integer
  end
end
