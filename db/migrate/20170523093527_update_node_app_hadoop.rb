class UpdateNodeAppHadoop < ActiveRecord::Migration[5.0]
  def up
    nodes = Node.w_not_deleted.all
    nodes.each do |node|
      puts "updating node #{node.id}"
      node.hadoop_app_id = node.cluster.hadoop_app_id
      node.save!
    end
  end

  def down
  end
end
