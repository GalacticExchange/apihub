module GexApiTestCommonHelpers
  def check_error_code(res, error_name)
    err = Errors.find_by_name(error_name)

    error_code = res.error_code

    #return err[0].to_s == error_code.to_s
    return err.id.to_s == error_code.to_s
  end

  def get_error_code(error_name)
    err = Gexcore::Errors.find_by_name(error_name)
    #err[0].to_i
    err.id
  end
end
