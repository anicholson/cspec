require "version_tools"

with_crystal_version "0.34.0" do
  less_than do
    require "logger"

    module CSpec
      DEBUG = Logger.new(STDERR)
    end
  end

  greater_or_equal do
    require "log"
    Log.setup_from_env

    module CSpec
      DEBUG = Log
    end
  end
end

module CSpec
  class NopDebugger
    macro method_missing(_m, &_b)
    end
  end
end
