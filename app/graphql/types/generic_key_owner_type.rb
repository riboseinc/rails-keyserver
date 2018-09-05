# (c) 2018 Ribose Inc.

Types::GenericKeyOwnerType = GraphQL::ObjectType.define do
  name "GenericKeyOwner"
  description "A key's owner"

  field :id, !types.ID do
    description "Unique ID for the key owner"
    # resolve ->(obj, args, ctx) {
    #   obj.id
    # }
  end

  field :keys, !types[types.Key] do
    description "the owner's Keys"
    # resolve ->(obj, args, ctx) {
    #   obj.keys
    # }
  end

  field :created_at, types.String do
    description "Creation datetime of the key owner"
    # resolve ->(obj, args, ctx) {
    #   obj.created_at
    # }
  end

  field :updated_at, !types.String do
    description "Last update datetime of the key owner"
    # resolve ->(obj, args, ctx) {
    #   obj.updated_at
    # }
  end

end
