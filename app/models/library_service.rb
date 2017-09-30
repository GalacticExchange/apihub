class LibraryService < ActiveRecord::Base

  has_many :services, class_name: 'ClusterService'
  belongs_to :type, class_name: 'LibraryServiceType', foreign_key: 'library_service_type_id'

  # paging
  paginates_per 10

  ### search
  searchable_by_simple_filter

  ### get

  def self.get_by_name(name)
    where(name: name).first
  end


  ### scopes
  scope :w_big_data, -> { where(library_service_type.name == 'big_data') }
  #scope :w_search_visualize, -> { where('status = ?', statuses[:active]) }
  #scope :w_transform, -> { where('status = ?', statuses[:active]) }

end
