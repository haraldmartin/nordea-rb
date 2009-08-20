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
  end
end