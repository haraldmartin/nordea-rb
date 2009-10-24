require 'open-uri'
require 'net/https'
begin
  require 'hpricot'
rescue LoadError
  puts "Hpricot is missing. Run `gem install hpricot` to install"
  exit
end

require "nordea/request"
require "nordea/resources"
require "nordea/session"
require "nordea/support"
require "nordea/transaction"
require "nordea/version"

module Nordea
  class InvalidLogin < StandardError; end
  
  module Commands
    LOGIN_PHASE_1 = "WAP00"
    LOGIN_PHASE_2 = "KK10"
    OVERVIEW      = "WAP11TW"
    PAYMENTS      = "FB00TW"
    LOGOUT        = "LL99"
    RESOURCE      = "KF00TW"
    MAIN_MENU     = "WAPL10"
    TRANSACTIONS  = "KF11TW"
    TRANSFERS     = "WAP12TW"
    TRANSFER_TO_OWN_ACCOUNT_PHASE_1 = "OF00TW"
    TRANSFER_TO_OWN_ACCOUNT_PHASE_2 = "OF10TW"
    TRANSFER_TO_OWN_ACCOUNT_PHASE_3 = "OF12TW"
  end
  
  def Nordea.new(pnr_or_hash, pin_or_options = {}, &block)
    pnr, pin = extract_login_details(pnr_or_hash, pin_or_options)
    raise ArgumentError unless pnr.length == 10 && pin.length == 4
    Session.new(pnr.to_s, pin.to_s, &block)
  end
  
  private
  
    # TODO clean up
    def self.extract_login_details(pnr_or_hash, pin_or_options)
      if pnr_or_hash.is_a?(Hash)
        pnr_or_hash.symbolize_keys!
        pnr = pnr_or_hash[:pnr]
        pin = pnr_or_hash[:pin]
      elsif pnr_or_hash.is_a?(Symbol)
        if pnr_or_hash == :keychain
          options = { :label => 'Nordea' }.merge(pin_or_options.symbolize_keys)
          pnr, pin = account_details_from_keychain(options)
        end
      elsif pnr_or_hash.is_a?(String) && pin_or_options.is_a?(String)
        pnr = pnr_or_hash
        pin = pin_or_options
      else
        raise ArgumentError
      end
      [pnr.to_s.gsub(/\D+/, ''), pin.to_s.gsub(/\D+/, '')]
    end
  
    def Nordea.account_details_from_keychain(options)
      command = "security find-generic-password -l '#{options[:label]}' -g"
      command << " #{options[:keychain_file].inspect}" if options[:keychain_file]
      command << " 2>&1"
      `#{command}`.scan(/password: "(\d{4})"|"acct"<blob>="(\d{10})"/).flatten.compact.reverse
    end
end