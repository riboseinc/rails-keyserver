module Rails
  module Keyserver
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
