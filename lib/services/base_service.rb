module Services
  class BaseService

    def self.api
      Services::GexApi
    end


    def self.model_add_errors_from_response(model, res)
      if res.error?
        res.errors.each do |err|
          msg = err[:message] || err['message']
          model.errors.add(:base, msg)
        end

        return false
      end

      return true
    end

  end
end

