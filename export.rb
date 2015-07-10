require 'rubygems'
require 'neo4j'
require 'neo4j-core'
require 'gexf'

graph = GEXF::Graph.new
graph.define_node_attribute(:name)
graph.define_node_attribute(:mail)
graph.define_node_attribute(:label)
graph.define_edge_attribute(:amount)

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
end

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

class Domain
  include Neo4j::ActiveNode

  id_property :domain_id, on: :domain_id

  property :domain, type:String

  has_many :in, :users, unique: true, model_class: User

end

def userExport
  User.all do |user|
    puts user.name.pink
  end
end
