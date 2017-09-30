class LibraryServiceType < ApplicationRecord

  has_many :library_services, foreign_key: 'library_service_type_id'

end
