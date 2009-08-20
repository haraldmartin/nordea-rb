module Nordea
  class Account < Resource
    def initialize(fields = {}, command_params = {}, session = nil)
      @name, @balance, @currency = fields[:name], fields[:balance], fields[:currency]
      @command_params = command_params
      @session = session
    end
    
    attr_accessor :name, :balance, :currency, :session
    
    def account_type_name; 'konton' end

    def to_command_params
      @command_params
    end
    
    # TODO move shared transaction fetching to Nordea::Resource and call super
    def transactions(reload = false)
      @transactions = nil if reload
      @transactions ||= begin
        doc = session.request(Commands::TRANSACTIONS, to_command_params).parse_xml
        doc.search('go[@href="#trans"]').inject([]) do |all, node|
          all << Transaction.new_from_xml(node)
        end
      end
    end
    
    def to_s
      "#{name}: #{balance_to_s} #{currency}"
    end
    
    def balance_to_s(decimals = 2)
      %Q{%.#{decimals}f} % balance
    end

    def self.new_from_xml(xml_node, session)
      xml_node = Hpricot(xml_node) unless xml_node.class.to_s =~ /^Hpricot::/
      xml_node = xml_node.at("anchor") unless xml_node.name == 'anchor'
      new _setup_fields(xml_node), _setup_command_params(xml_node), session
    end
    
    private
    
      def self._setup_fields(xml_node)
        name = xml_node.at("postfield[@name='account_name']")['value']
        currency = xml_node.at("postfield[@name='account_currency_code']")['value']
        balance  = xml_node.next_sibling.next
        { :name => name, :currency => currency, :balance => Support.dirty_currency_string_to_f(balance) }
      end
    
      def self._setup_command_params(xml_node)
        command_params = (xml_node/'postfield').to_a.inject({}) do |all, postfield|
          name = postfield['name']
          all[name] = postfield['value'] unless name =~ /sid|OBJECT/
          all
        end
      end
  end
end
