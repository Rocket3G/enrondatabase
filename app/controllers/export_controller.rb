class ExportController < ApplicationController
  def index

  end

  def export
    respond_to do |format|
      format.gexf do
        @users = User.query_as(:user).match("user-[rel]->(domain:Domain {domain: 'enron.com'})").pluck(:user)
        @edges ||= []
        @mails = Email.query_as(:email).match("email-[rel]->(user:User)-[rrel]->(domain:Domain {domain: 'enron.com'})").with("email, count(rel) as rc").where("rc < 10").pluck(:email)
        total = @mails.count
        count = 0
        @mails.each do |mail|
          count += 1
          mail.sentmails.each do |from|
            mail.tomail.query_as(:user).match("user-[rel]->(domain:Domain {domain: 'enron.com'})").pluck(:user).each do |to|
              edge = {from: from.mail, to: to.mail, value: 0}
              @edges << edge unless @edges.detect {| h | h[:to] == to.mail && h[:from] == from.mail}
              (@edges.find {| h | h[:to] == to.mail && h[:from] == from.mail})[:value] += 1;
            end
            mail.ccusers.query_as(:user).match("user-[rel]->(domain:Domain {domain: 'enron.com'})").pluck(:user).each do |cc|
              edge = {from: from.mail, to: cc.mail, value: 0}
              @edges << edge unless @edges.detect {| h | h[:to] == cc.mail && h[:from] == from.mail}
              (@edges.find {| h | h[:to] == cc.mail && h[:from] == from.mail})[:value] += 0.5;
            end
            mail.bccusers.query_as(:user).match("user-[rel]->(domain:Domain {domain: 'enron.com'})").pluck(:user).each do |bcc|
              edge = {from: from.mail, to: bcc.mail, value: 0}
              @edges << edge unless @edges.detect {| h | h[:to] == bcc.mail && h[:from] == from.mail}
              (@edges.find {| h | h[:to] == bcc.mail && h[:from] == from.mail})[:value] += 0.25;
            end
          end
        end

        sum = @edges.inject(0) {|sum, n| sum + n[:value]}
        max, min = @edges.minmax_by { |x| x[:value]}

        sum = sum.to_f
        max = max[:value].to_f
        min = min[:value].to_f

        @edges.each do |edge|
          edge[:value] = (edge[:value]-min) / (max-min)
        end
      end
    end
  end
end
