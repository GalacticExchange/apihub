module FilterHelper

  def self.for_select_yes_no_visible_client
    a = [["all visible client", -1], ["yes", 1], ["no", 0]]
    a
  end

  def self.for_select_yes_no_need_notify
    a = [["all need notify", -1], ["yes", 1], ["no", 0]]
    a
  end

  def self.for_select_yes_no_enable_library_application
    a = [["all library application", -1], ["yes", 1], ["no", 0]]
    a
  end

end
