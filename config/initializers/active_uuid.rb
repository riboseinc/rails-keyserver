module ActiveSupport
  class Deprecation

    warn "[WW] Rails deprecation warning messages suppressed by #{__FILE__}"
    def warn(*_args); end

  end
end
