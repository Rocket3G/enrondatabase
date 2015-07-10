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

def domain(email)
  return email.split('@')[1]
end

def createDomain(email)
  Domain.create(domain: domain(email)) unless Domain.exists?(domain: domain(email))
  return Domain.find_by(domain: domain(email))
end

def createUser(name, email)
  User.create(name: name, mail: email) unless User.exists?(mail: email)

  usr = User.find_by(mail: email)
  dmn = createDomain(email)
  usr.domain = dmn
  dmn.users << usr unless dmn.users.include?(usr)
  return usr
end

def createEmail(mail)
  Email.create(mailId: mail.message_id, subject: mail.subject, date: mail.date) unless Email.exists?(mailId: mail.message_id)

  email = Email.find_by(mailId: mail.message_id)

  toArray ||= Array.new
  ccArray ||= Array.new
  bccArray ||= Array.new
  fromArray ||= Array.new

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
  xcc = mail.header['X-cc'].to_s.split(', ')
  if (mail.cc && mail.cc.any?)
    mail.cc.each do |cc|
      ccArray << createUser(cc[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), cc)
    end
  elsif xcc && xcc.any?
    xcc.each do |cc|
      ccArray << createUser(cc[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), cc)
    end
  end
  xbcc = mail.header['X-bcc'].to_s.split(', ')
  if (mail.bcc && mail.bcc.any?)
    mail.bcc.each do |bcc|
      bccArray << createUser(bcc[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), bcc)
    end
  elsif xbcc && xbcc.any?
    xbcc.each do |bcc|
      bccArray << createUser(bcc[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), bcc)
    end
  end

  fromArray ||= Array.new
  mail.from.each do |from|
    fromArray << createUser(from[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' '), from)
  end


  fromArray.each do |from|
    from.sentmails << email unless from.sentmails.include?(email)
    email.sentmails << from unless email.sentmails.include?(from)
  end
  toArray.each do |to|
    to.tomail << email unless to.tomail.include?(email)
    email.tomail << to unless email.tomail.include?(to)
  end
  ccArray.each do |cc|
    cc.ccusers << email unless cc.ccusers.include?(email)
    email.ccusers << cc unless email.ccusers.include?(cc)
  end
  bccArray.each do |bcc|
    bcc.bccusers << email unless bcc.bccusers.include?(email)
    email.bccusers << bcc unless email.bccusers.include?(bcc)
  end

  return { mail: email, toCount: toArray.length + ccArray.length + bccArray.length, fromCount: fromArray.length };
end


Neo4j::Session.open(:server_db)

limit = 50000

Dir.glob("dataset/maildir/**/sent/**") do |file|
  if (--limit < 0)
    puts "Exceeded the limit"
    return
  end
  added = createEmail(Mail.read(file))

  uname, nomail = file.match(/dataset\/maildir\/(.*)\/sent\/(\d*)/).captures

  first = "#{uname} - #{nomail}\t=>".yellow
  to = "#{added[:toCount]} users".green
  from = "#{added[:fromCount]} users".green

  puts "#{first} Parsed #{from} that sent the mail, and #{to} that received the mail"

end

