module Nordea
  class Support
    def self.dirty_currency_string_to_f(string)
      string.to_s.strip.gsub(/(\302|\240)/, "").gsub('.', '').gsub(',', '.').delete('SEK').to_f
    end
  end
end

def quietly
  v = $VERBOSE
  $VERBOSE = nil
  yield
ensure
  $VERBOSE = v
end

# quietly { OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE }

class Net::HTTP
  alias_method :old_initialize, :initialize
  def initialize(*args)
    old_initialize(*args)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

class Symbol
  def to_proc
    Proc.new { |obj, *args| obj.send(self, *args) }
  end
end

# from ActiveSupport
class Hash
  def stringify_keys
    inject({}) do |options, (key, value)|
      options[key.to_s] = value
      options
    end
  end

  def stringify_keys!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end

  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end

  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end

  alias_method :to_options,  :symbolize_keys
  alias_method :to_options!, :symbolize_keys!
end