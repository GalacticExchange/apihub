class LibraryApplicationType < ApplicationRecord

  has_many :library_applications

  def self.get_id_by_name(name)
    obj = get_by_name(name)
    obj ? obj.id : nil
  end

  def self.get_by_name(name)
    self.where(name: name).first
  end

  def self.method_missing(method_sym, *arguments, &block)
    case method_sym
      when /^id_/ then
        type_name = method_sym.to_s.remove('id_')
        a =  self.send(get_id_by_name(type_name))
        p a
      else
        return nil
    end
  end








end
