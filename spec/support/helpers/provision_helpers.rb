module ProvisionHelpers

  def cmd_contains_param(cmd, p, v)
    return true if cmd =~ /\"#{p}\"[:\=\>]*\"?#{v}\"?/
    return true if cmd =~ /#{p}=[\"\']?#{v}[\"\']?/

    false
  end

  def cmd_contains_param_name(cmd, p)
    return true if cmd =~ /\"#{p}\"/
    return true if cmd =~ /#{p}=/

    false
  end

  def cmd_cap_contains_param_name(cmd, p)
    return true if cmd =~ /#{p}=/

    false
  end

end
