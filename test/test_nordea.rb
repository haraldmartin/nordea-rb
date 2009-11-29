require 'test_helper'

class TestNordea < Test::Unit::TestCase
  context "Setting personnummer and pincode" do
    should "raise an error if no pnr and pin code are given" do
      assert_raise(ArgumentError) { Nordea.new }
    end
  
    should "raise an ArgumentError if pnr is not exactly 10 digits" do
      assert_raise(ArgumentError) { Nordea.new({ :pnr => "1234", :pin => "1234" }) }
    end
  
    should "raise an ArgumentError if the pin code is not exactly 4 digits" do
      assert_raise(ArgumentError) { Nordea.new({ :pnr => "1234567890", :pin => "1" }) }
    end
  
    should "allow to set the pnr and pin code using two arguments" do
      n = Nordea.new("1234567890", "1234")
      assert_equal "1234567890", n.pnr
      assert_equal "1234", n.pin
    end
  
    should "allow to set the pnr and pin using a hash" do
      n = Nordea.new({ :pnr => '1234567890', :pin => '1234' })
      assert_equal "1234567890", n.pnr
      assert_equal "1234", n.pin
    end
  
    should "set the pnr and pin as strings" do
      n = Nordea.new({ :pnr => 1234567890, :pin => "1234" })
      assert_equal "1234567890", n.pnr
      assert_equal "1234", n.pin
    end

    should "allow to set the pnr with seperators" do
      n = Nordea.new({ :pnr => "12-34 56-7890", :pin => "1234" })
      assert_equal "1234567890", n.pnr
    end

    should "allow to set the pin with seperators" do
      n = Nordea.new({ :pnr => "1234567890", :pin => "12 - 34" })
      assert_equal "1234", n.pin
    end
    
    should "raise an error if there is no pin provided" do
      assert_raise(ArgumentError) { Nordea.new("1234567890") }
    end
    
    should "raise an error when using a symbol other than :keychain" do
      assert_raise(ArgumentError) { Nordea.new(:foo) }
    end

    context "getting the account details from the OS X Keychain" do
      setup do
        @return_value = <<-EOF
  keychain: "/Users/me/Library/Keychains/login.keychain"
  class: "genp"
  attributes:
      0x00000001 <blob>="Nordea"
      0x00000002 <blob>=<NULL>
      "acct"<blob>="1234567890"
      "cdat"<timedate>=0x11111111111111111111111111111111  "111111111111111\000"
      "crtr"<uint32>=<NULL>
      "cusi"<sint32>=<NULL>
      "desc"<blob>=<NULL>
      "gena"<blob>=<NULL>
      "icmt"<blob>=<NULL>
      "invi"<sint32>=<NULL>
      "mdat"<timedate>=0x22222222222222222222222222222222  "222222222222222\000"
      "nega"<sint32>=<NULL>
      "prot"<blob>=<NULL>
      "scrp"<sint32>=<NULL>
      "svce"<blob>="Nordea"
      "type"<uint32>=<NULL>
  password: "1337"
        EOF
        Nordea.stubs(:`).with(anything).returns(@return_value)
      end
      
      should "call the security commando on OS X to retreive the password" do
        Nordea.expects(:`).with(anything).returns(@return_value)
        Nordea.new(:keychain)
      end

      should "find pnr with dashes" do
        @return_value.gsub!('"acct"<blob>="1234567890"', '"acct"<blob>="123456-7890"')
        assert_equal "1234567890", Nordea.new(:keychain).pnr
      end

      should "find pnr with spaces" do
        @return_value.gsub!('"acct"<blob>="1234567890"', '"acct"<blob>=" 123456 7890"')
        assert_equal "1234567890", Nordea.new(:keychain).pnr
      end
    end
  end
end