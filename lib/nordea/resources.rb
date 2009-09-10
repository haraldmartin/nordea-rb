require 'nordea/resources/resource'
require 'nordea/resources/account'
require 'nordea/resources/card'
require 'nordea/resources/fund'
require 'nordea/resources/loan'

class ResourceCollection < Array
  def [](account_name)
    if account_name.is_a?(String)
      detect { |e| e.name == account_name }
    elsif account_name.is_a?(Regexp)
      detect { |e| e.name =~ account_name }
    else
      super
    end
  end
end