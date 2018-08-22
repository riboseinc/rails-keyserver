# frozen_string_literal: true

class GenericKeyOwner < ActiveRecord::Base
  include ActiveUUID::UUID

  # attr_accessor :type
  # def type
  #   @type
  # end

  # def type= other
  #   @type = other
  # end
end
