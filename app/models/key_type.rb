class KeyType < ApplicationRecord

  def self.get_by_name(name)
    where(name: name).first
  end

end
