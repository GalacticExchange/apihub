class RemoveAwsRegionFromClusters < ActiveRecord::Migration
  def change
    remove_column :clusters, :aws_region, :integer
  end
end
