class AddDescriptionToLibraryApplication < ActiveRecord::Migration
  def change

    add_column :library_applications, :description, :string

  end
end
