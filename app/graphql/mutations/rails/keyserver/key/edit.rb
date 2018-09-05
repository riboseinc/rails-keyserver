# (c) 2018 Ribose Inc.

module Mutations
  module Rails
    module Keyserver
      module Key
        Edit = GraphQL::Relay::Mutation.define do
          name "KeyEdit"

          input_field :id, !types.ID
          input_filed :file,  !TYpes::Scalars::FileType
        end
      end
    end
  end
end
