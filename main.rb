require 'neo4j'
require 'neo4j-core'
require 'mail'

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

class UserEmail
  include Neo4j::ActiveRel

  from_class "User"
  to_class "User"

  type "sent_mail"

  property :amount, type:Integer

end

class User
  include Neo4j::ActiveNode

  id_property :mail_id, on: :mail

  property :name, type:String
  property :mail, type:String

  has_many :out, :sentmails, rel_class: UserEmail, unique: true, model_class: User
  has_many :in, :receivedmails, rel_class: UserEmail, unique: true, model_class: User

end

def createUser(name, email)
  User.create(name: name, mail: email) unless User.exists?(mail: email)
  return User.find_by(mail: email)
end

def createMail(mail)
  toArray ||= Array.new
  xto = mail.header['X-To'].to_s.split(', ')
  if (mail.to && mail.to.any?)
    mail.to.each do |to|
      toArray << createUser(to[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), to)
    end
  elsif xto && xto.any?
    xto.each do |to|
      toArray << createUser(to[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), to)
    end
  end


  fromArray ||= Array.new
  mail.from.each do |from|
    fromArray << createUser(from[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), from)
  end

  toArray.each do |user|
    fromArray.each do |from|
      if (from.sentmails.include?(user))
        from.rels(dir: :outgoing, between: user).each do |rel|
          rel.amount += 1
          rel.save
        end
      else
        UserEmail.create(from_node: from, to_node: user, amount: 1)
      end
    end
  end

  return {:fromCount => fromArray.count, :toCount => toArray.count}

end

Neo4j::Session.open(:server_db)

limit = 1000;

Dir.glob("dataset/maildir/**/sent/*") do |file|
  added = createMail(Mail.read(file))

  uname, nomail = file.match(/dataset\/maildir\/(.*)\/sent\/(\d*)/).captures

  first = "#{uname} - #{nomail}\t=>".yellow
  to = "#{added[:toCount]} users".green
  from = "#{added[:fromCount]} users".green

  puts "#{first} Parsed #{from} that sent the mail, and #{to} that received the mail"

end

