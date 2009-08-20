require File.join(File.dirname(__FILE__), *%w".. lib nordea")
require 'shoulda'
gem 'mocha', '=0.9.5'
require 'mocha'
require "test/unit"
require 'ostruct'

class FakedConnection
  def initialize(command)
    @command = command
  end
  
  def post(script, query, headers)
    @fixture = {
      Nordea::Commands::LOGIN_PHASE_1 => 'login',
      Nordea::Commands::RESOURCE      => 'accounts',
      Nordea::Commands::TRANSACTIONS  => 'account'
    }[@command]
    @query = query
    OpenStruct.new(:body => _body_from_fixture)
  end
  
  def _body_from_fixture
    @fixture = case @query
      when /account_name=Betalkonto/ then fixture = 'account'
      when /account_name=Huvudkonto/ then fixture = 'account_10_transactions'
      when /account_name=Sparkonto/  then fixture = 'account_5_transactions'
    end if @fixture == 'account'
    @fixture ? fixture_contents(@fixture) : ""
  end
  
  # yes we redefined this for now
  def fixture_contents(fixture)
    IO.read(File.join(File.expand_path(File.join(File.dirname(__FILE__), "fixtures")), "#{fixture}.wml"))
  end
end

class Test::Unit::TestCase
  FIXTURES_PATH = File.expand_path(File.join(File.dirname(__FILE__), "fixtures")) unless defined?(FIXTURES_PATH)
  
  def fixture_content(filename)
    IO.read(File.join(FIXTURES_PATH, "#{filename}.wml"))
  end
  
  # From Rails ActiveSupport::Testing::Declarative
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end
