class AddLibraryServiceTypeToLibraryServices < ActiveRecord::Migration[5.0]
  def change
    add_reference :library_services, :library_service_type, foreign_key: true
  end
end
