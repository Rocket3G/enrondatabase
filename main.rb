require 'neo4j'
require 'mail'

class UserEmail
  include Neo4j::ActiveRel

  from_class "User"
  to_class "User"

  type "sent_mail"

  property :subject, type:String
  property :date, type:DateTime
end

class User
  include Neo4j::ActiveNode

  id_property :mail_id, on: :mail

  property :name, type:String
  property :mail, type:String

  has_many :out, :sentmails, rel_class: UserEmail
  has_many :in, :receivedmails, rel_class: UserEmail

end

def createUser(email)
  createUser(email[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), email)
end

def createUser(name, email)
  User.create(name: name, mail: email) unless User.exists?(mail: email)
  return User.find_by(mail: email)
end

def createMail(mail)
  mail.header['X-To'].to_s.split(', ').zip(mail.to).each do |to|
    puts createUser to[0], to[1]
  end
end

Neo4j::Session.open(:server_db)

mail = Mail.read("dataset/maildir/allen-p/sent/1")

createMail mail
