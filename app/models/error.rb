class Error < ActiveRecord::Base
  after_save :invalidate_cache

  private
  def invalidate_cache
    keys = ["errors:by_name:#{self.name}"]

    keys.each do |key|
      Rails.cache.delete(key)
    end

  end

end
