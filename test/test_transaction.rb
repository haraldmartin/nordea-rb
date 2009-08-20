require 'test_helper'

class TestTransaction < Test::Unit::TestCase
  def setup
    @xml_node = <<-END
    <anchor>090816&#160;&#160;-52,70
			<go href="#trans">
				<setvar name="date" value="2009-08-16"/>
				<setvar name="amount" value="-52,70"/>
				<setvar name="text" value="Res. k&#246;p"/>
			</go>
		</anchor>
    END
    @transaction = Nordea::Transaction.new_from_xml(@xml_node)
  end
  
  should "create a new transaction from a XML node" do
    assert_instance_of Nordea::Transaction, @transaction
  end

  should "have a date" do
    assert_instance_of Date, @transaction.date
    assert_equal "2009-08-16", @transaction.date.to_s
  end
  
  should "have an amount" do
    assert_equal -52.70, @transaction.amount
  end
  
  should "have a text" do
    assert_equal "Res. köp", @transaction.text
  end
  
  # should "allow to create a Transaction using a hash for params" do
  #   transaction = Nordea::Transaction.new(:date => '2009-10-11', :text => "foo", :amount => -13.37)
  #   assert_equal '2009-10-11', transaction.date.to_s
  #   assert_equal 'foo', transaction.text
  #   assert_equal -13.37, transaction.amount
  # end

  should "raise an ArgumentError if not enough arguments are given" do
    assert_raise(ArgumentError) { Nordea::Transaction.new }
    assert_raise(ArgumentError) { Nordea::Transaction.new('foo') }
    assert_raise(ArgumentError) { Nordea::Transaction.new('foo', 'bar') }
  end
  
  should "know if it is a withdrawal" do
    t = Nordea::Transaction.new('2009-01-01', -100.00, 'ACME Store')
    assert t.withdrawal?
    assert !t.deposit?
  end

  should "know if it is a deposit" do
    t = Nordea::Transaction.new('2009-01-01', 10.00, 'Salery')
    assert t.deposit?
    assert !t.withdrawal?
  end
end
