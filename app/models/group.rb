class Group < ActiveRecord::Base
  has_many :user_groups

  def self.group_superadmin
    # TODO: cache
    Group.where(name: 'superadmin').first
  end

  def self.group_admin
    # TODO: cache
    Group.where(name: 'admin').first
  end

  def self.group_user
    # TODO: cache
    Group.where(name: 'user').first
  end

  def to_hash
    {
        id: id,
        name: name,
        title: title
    }
  end




=begin
  def self.group_external
    # TODO: cache
    Group.where(name: 'external').first
  end
=end


  #### get

  def self.get_by_name(name)
    where(name: name).first
  end
end
