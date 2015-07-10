class Domain
  include Neo4j::ActiveNode

  id_property :domain_id, on: :domain_id

  property :domain, type:String

  has_many :in, :users, unique: true, model_class: User
end
