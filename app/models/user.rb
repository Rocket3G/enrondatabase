class User
  include Neo4j::ActiveNode

  id_property :mail_id, on: :mail

  property :name, type:String
  property :mail, type:String

  has_many :out, :sentmails, unique: true, model_class: Email
  has_many :in, :tomail, unique: true, model_class: Email
  has_many :in, :ccusers, model_class: Email
  has_many :in, :bccusers, model_class: Email
  has_one  :out, :domain, unique: true, model_class: "Domain"
end
