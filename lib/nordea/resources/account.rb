module Nordea
  class Account < Resource
    def initialize(fields = {}, command_params = {}, session = nil)
      @name, @balance, @currency, @index = fields[:name], fields[:balance], fields[:currency], fields[:index]
      @command_params = command_params
      @session = session
      @session = session if session
      yield self if block_given?
    end
    
    attr_accessor :name, :balance, :currency, :index, :session
    
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
    
    def withdraw(amount, currency = 'SEK', options = {})
      options.symbolize_keys!
      to = options[:deposit_to]

      raise ArgumentError, "options[:deposit_to] must be a Nordea::Account" unless to.is_a?(Nordea::Account)

      currency, amount  = currency.to_s, amount.to_s.sub(".", ",")
      from_account_info = [index, currency, name].join(":")
      to_account_info   = [to.index, to.currency, to.name].join(":")

      params = { :from_account_info => from_account_info,
                 :to_account_info   => to_account_info,
                 :amount            => amount,
                 :currency_code     => currency }
      
      session.request(Nordea::Commands::TRANSFER_TO_OWN_ACCOUNT_PHASE_1, params)
      session.request(Nordea::Commands::TRANSFER_TO_OWN_ACCOUNT_PHASE_2, params)
      session.request(Nordea::Commands::TRANSFER_TO_OWN_ACCOUNT_PHASE_3, {
        :currency_code             => currency,
        :from_account_number       => index,
        :from_account_name         => name,
        :to_account_number         => to.index,
        :to_account_name           => to.name,
        :amount                    => amount,
        :exchange_rate             => "0",
        :from_currency_code        => currency,
        :to_currency_code          => currency
      })

      session.accounts(true)
    end

    def deposit(amount, currency = 'SEK', options = {})
      options.symbolize_keys!
      from = options.delete(:withdraw_from)
      
      raise ArgumentError unless from.is_a?(Nordea::Account)
      
      from.withdraw(amount, currency, options.merge(:deposit_to => self))
    end

    private
    
      def self._setup_fields(xml_node)
        name     = xml_node.at("postfield[@name='account_name']")['value']
        currency = xml_node.at("postfield[@name='account_currency_code']")['value']
        index    = xml_node.at("postfield[@name='account_index']")['value']
        balance  = xml_node.next_sibling.next
        { :name => name, :currency => currency, 
          :balance => Support.dirty_currency_string_to_f(balance), :index => index }
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
