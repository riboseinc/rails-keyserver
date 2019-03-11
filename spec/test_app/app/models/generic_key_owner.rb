# frozen_string_literal: true

class GenericKeyOwner < ActiveRecord::Base
  include ActiveUUID::Model
  attribute :id, ActiveUUID::Type::BinaryUUID.new

  # attr_accessor :type
  # def type
  #   @type
  # end

  # def type= other
  #   @type = other
  # end
end
