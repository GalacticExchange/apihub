class CreateLibraryServiceTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :library_service_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
