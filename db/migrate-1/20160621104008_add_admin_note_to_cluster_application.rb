class AddAdminNoteToClusterApplication < ActiveRecord::Migration
  def change

    add_column :cluster_applications, :admin_note, :string

  end
end
