module Rails
  module Keyserver
    class Engine < ::Rails::Engine
      isolate_namespace Rails::Keyserver
    end
  end
end
