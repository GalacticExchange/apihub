class AddNameToLibraryApplicationTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :library_application_types, :name, :string
  end
end
