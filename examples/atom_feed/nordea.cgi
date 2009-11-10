#!/usr/bin/env ruby

# Based on/stolen from http://github.com/henrik/atomica -- Thanks!

require 'rubygems'
require 'nordea'
require('builder') rescue require('active_support') # gem install builder

class NordeAtom
  NAME        = "NordeAtom"
  VERSION     = "1.0"
  SCHEMA_DATE = "2009-11-02"
  
  def initialize(pnr, pin)
    @pnr, @pin = pnr, pin
  end
  
  def render
    atomize(fetch)
  end
  
protected
  
  def fetch
    transactions = nil
    Nordea.new(@pnr, @pin) do |n|
      transactions = n.accounts.map(&:transactions).flatten.sort_by(&:date).reverse
    end
    transactions
  end
  
  def atomize(items)
    updated_at = (Time.parse(items.first.date.to_s) || Time.now).iso8601

    xml = Builder::XmlMarkup.new(:indent => 2, :target => $stdout)
    xml.instruct! :xml, :version => "1.0" 

    xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do |feed|
      feed.title     "Kontohistorik för #{@pnr}"
      feed.id        "tag:nordea,#{SCHEMA_DATE}:#{@pnr}"
      feed.link      :href => 'http://www.nordea.se'
      feed.updated   updated_at
      feed.author    { |a| a.name 'Nordea' }
      feed.generator NAME, :version => VERSION

      items.each do |item|
        item_time = Time.parse(item.date.to_s)
        item_date = [%w[Sön Mån Tis Ons Tors Fre Lör][item_time.wday], item_time.strftime('%Y-%m-%d')].join(' ')
        style = item.withdrawal? ? 'color: red' : 'color: green'

        feed.entry do |entry|
          entry.id      "tag:nordea,#{SCHEMA_DATE}:#{@pnr}/#{item.account.index};" + 
                        "#{item_time.strftime('%Y-%m-%d')};#{item.text.gsub(/\W/, '')};" + 
          amount = %Q{%.2f SEK} % item.amount
          entry.title   "#{item.text} #{amount}"
                        "#{item.amount};#{}".gsub(/\s+/, '')
          entry.content %{<table>
                            <tr><th>Konto:</th>  <td>#{item.account.name}</td></tr>
                            <tr><th>Datum:</th>  <td>#{item_date}</td></tr>
                            <tr><th>Belopp:</th> <td style="#{style}">#{item.amount}</td></tr>
                          </table>}, :type => 'html'
          entry.updated item_time.iso8601
        end
      end
    end
  end
end

if __FILE__ == $0

  # HTTP Basic auth based on code from http://blogs.23.nu/c0re/2005/04/antville-7409/
  require 'base64'
 
  auth = ENV.has_key?('HTTP_AUTHORIZATION') && ENV['HTTP_AUTHORIZATION'].to_s.split
  if auth && auth[0] == 'Basic'
    pnr, pwd = Base64.decode64(auth[1]).split(':')[0..1]
    puts "Content-Type: application/atom+xml"
    puts 
    NordeAtom.new(pnr, pwd).render
  else
    puts "Status: 401 Authorization Required"
    puts %{WWW-Authenticate: Basic realm="#{NordeAtom::NAME} pnr/PIN"}
    puts "Content-Type: text/plain"
    puts
    puts "Please provide personnummer and PIN as HTTP auth username/password."
  end
end
