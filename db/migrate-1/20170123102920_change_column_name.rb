class ChangeColumnName < ActiveRecord::Migration
  def change
    rename_column :library_applications, :ETA, :release_date
  end
end
