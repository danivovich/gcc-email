require 'bundler/setup'
require 'uri'
require 'csv'
require 'fileutils'

class EmailUpdate
  def run!
    @import = CSV.parse(File.read("eclipse.csv"))
    @cleaned = CSV.parse(File.read("cleaned.csv"))
    @unsubscribed = CSV.parse(File.read("unsubscribed.csv"))
    @subscribed = CSV.parse(File.read("subscribed.csv"))
    generate!
  end

  def contains?(file, email)
    found =
      file.find do |row|
        match_row?(row, email)
      end

    found != nil
  end

  def match_row?(row, email)
    data_email = row[0].downcase.strip
    return true if email == data_email
  end

  def in_subscribed?(email)
    contains?(@subscribed, email)
  end

  def in_unsubscribed?(email)
    contains?(@unsubscribed, email)
  end

  def in_cleaned?(email)
    contains?(@cleaned, email)
  end

  def valid_email?(email)
    email =~ URI::MailTo::EMAIL_REGEXP
  end

  def generate!
    out = CSV.open("update.csv", "wb")
    master = CSV.open("master_list.csv", "wb")
    #out << ["email", "first name", "last name"]
    @import.each do |row|
      email = row[6].downcase.strip.gsub(" ", "")
      valid = valid_email?(email) == 0
      cleaned = in_cleaned?(email)
      unsubscribed = in_unsubscribed?(email)
      subscribed = in_subscribed?(email)
      if valid && !cleaned && !unsubscribed && !subscribed
        out << [email, row[0], row[1]]
        master << [email, row[0], row[1]]
      end
      if subscribed
        master << [email, row[0], row[1]]
      end
    end
    out.close
    master.close
  end
end

updater = EmailUpdate.new
updater.run!
