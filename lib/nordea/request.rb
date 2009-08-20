module Nordea
  class Request
    HOST_NAME   = 'gfs.nb.se'
    HOST_PORT   = 443
    SCRIPT_NAME = '/bin2/gfskod'
    USER_AGENT  = 'Nokia9110/1.0'
    
    def initialize(command, extra_params = {})
      @command, @extra_params = command, extra_params
      request
    end
    
    def connection
      http = Net::HTTP.new(HOST_NAME, HOST_PORT)
      http.use_ssl = true
      http
    end
    
    def parse_xml 
      Hpricot.XML(response)
    end
    
    def request
      res = connection.post(SCRIPT_NAME, query, headers)
      @result = res.body
    end
    
    def headers
      { "User-Agent"  => USER_AGENT }
    end
    
    def response
      @result
    end
    
    def query
      @extra_params.merge({ "OBJECT" => @command }).
        inject([]) { |all, (key, value)| all << "#{key}=#{value}" }.
        join("&")
    end
  end
end
