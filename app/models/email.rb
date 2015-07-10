class Email
  include Neo4j::ActiveNode
  id_property :mail_id, on: :id

  property :mailId, type:String
  property :date, type:DateTime
  property :subject, type:String

  has_many :in, :sentmails, unique: true, model_class: "User"
  has_many :out, :tomail, model_class: "User"
  has_many :out, :ccusers, model_class: "User"
  has_many :out, :bccusers, model_class: "User"
end
