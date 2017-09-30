=begin
class ActionMailer::MessageDelivery
  alias :base_deliver_later :deliver_later

  def deliver_later(options={})
    gex_logger.debug_msg("sending email: #{self.inspect}, content: text: #{self.text_part.body.decoded}, html:#{self.html_part.body.decoded}")

    # super
    if ActionMailer::Base.perform_deliveries
      res = deliver_now
    else
      res = base_deliver_later(options)
    end

    res
  end


end
=end

class BaseMailer < ActionMailer::Base


end
