class CreateLibraryApplicationTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :library_application_types do |t|

      t.timestamps
    end
  end
end
