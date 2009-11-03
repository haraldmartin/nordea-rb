module Nordea
  class Session
    attr_accessor :pnr, :pin, :token
    attr_reader :num_requests

    def initialize(pnr, pin, &block)
      @pnr, @pin = pnr, pin
      @num_requests = 0
      if block_given?
       login
       yield self
       logout
      end
    end
    
    def login
      doc = request(Commands::LOGIN_PHASE_1, { "kundnr" => pnr, "pinkod" => pin, "sid" => "0" }).parse_xml
      begin 
        @token = (doc/'*[@name=sid]').attr("value")
        contract = (doc/'postfield[@name=contract]').attr("value")
      rescue Exception => e
        if node = doc.at("card[@title='Fel']")
          error_message = node.at("p").inner_text.strip
        else
          error_message = ""
        end
        raise Nordea::InvalidLogin, error_message
      end
      request Commands::LOGIN_PHASE_2, "bank" => "mobile_light", "no_prev" => "1", "contract" => contract
    end
    
    alias_method :login!, :login
    
    def logout
      request Commands::LOGOUT
    end
    
    alias_method :logout!, :logout
    
    def request(command, extra_params = {})
      extra_params.symbolize_keys!
      extra_params.merge!(:sid => token) unless extra_params.has_key?(:sid)
      @num_requests += 1
      Nordea::Request.new(command, extra_params)
    end
    
    def accounts(reload = false)
      if reload && @accounts
        reloaded_xml_nodes = reload_resources(Account)
        @accounts.each_with_index { |account, idx| account.reload_from_xml(reloaded_xml_nodes[idx]) }
      else
        @accounts ||= setup_resources(Account)
      end
    end
    
    private
    
      def fetch_resources(klass)
        type = klass.new.account_type_name
        doc = request(Commands::RESOURCE, "account_type_name" => type).parse_xml
        (doc/"go postfield[@name='OBJECT'][@value='#{Commands::TRANSACTIONS}']")
      end

      def reload_resources(klass)
        fetch_resources(klass).map { |field| field.parent.parent }
      end

      def setup_resources(klass)
        fetch_resources(klass).inject(ResourceCollection.new) do |all, field| 
          all << klass.new_from_xml(field.parent.parent, self)
        end
      end
  end
end
