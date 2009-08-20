require 'date'

module Nordea  
  class Transaction
    def initialize(date, amount, text)
      @date, @amount, @text = date, amount, text
    end
    
    attr_accessor :date, :amount, :text
    
    def withdrawal?
      amount < 0
    end

    def deposit?
      amount > 0
    end
    
    def self.new_from_xml(xml)
      node   = xml.is_a?(String) ? Hpricot.XML(xml) : xml
      date   = Date.parse(node.at("setvar[@name='date']")['value'])
      amount = Support.dirty_currency_string_to_f(node.at("setvar[@name='amount']")['value'])
      text   = node.at("setvar[@name='text']")['value']
      new date, amount, text
    end
  end
end