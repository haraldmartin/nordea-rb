require 'test_helper'

class TestAccount < Test::Unit::TestCase
  context Nordea::Account do
    setup do
      @session = Nordea::Session.new('foo', 'bar')
      @account = Nordea::Account.new(:name => "savings account", :balance => 1234.50, :currency => 'EUR')
      @account.session = @session
    end
  
    context "each Account instance" do
      should "have a description of the account for #to_s" do
        assert_equal 'savings account: 1234.50 EUR', @account.to_s
      end
    
      should "have a pointer to the current session object" do
        assert_equal @session, @account.session
      end
      
      should "request the transactions from the server" do
        response = mock(:parse_xml => Hpricot.XML(fixture_content('account')))
        @session.expects(:request).with('KF11TW', {}).returns(response)
        @account.transactions
      end
    end
  
    context "the list of transactions" do
      setup do
        response = stub(:parse_xml => Hpricot.XML(fixture_content('account')))
        @session.stubs(:request).with('KF11TW', {}).returns(response)
        @transactions = @account.transactions
      end
    
      should "find the accounts's transactions" do
        assert_equal 20, @transactions.length
      end
  
      should "create an array with all transactions" do
        assert_instance_of Array, @transactions
      end
  
      should "setup each transaction class" do
        assert_instance_of Nordea::Transaction, @transactions.first
      end
  
      should "set transaction's date" do
        assert_equal "2009-08-16", @transactions.first.date.to_s
      end

      should "set transaction's amount" do
        assert_equal -52.70, @transactions.first.amount
      end

      should "set transaction's text" do
        assert_equal "Res. köp", @transactions.first.text
      end
    end
  
    context "creating a new Account object from XML" do
      setup do
        @xml_node = <<-END
          <card title="&#214;versikt">
        	  <p>
              <anchor title="Kontoutdrag">Sparkonto
                <go method="get" href="https://gfs.nb.se/bin2/gfskod">
                  <postfield name="OBJECT" value="KF11TW"/>
                  <postfield name="sid" value="123456789"/>
                  <postfield name="account_name" value="Sparkonto"/>
                  <postfield name="account_index" value="1"/>
                  <postfield name="account_type" value="001"/>
                  <postfield name="account_currency_code" value="SEK"/>
                  <postfield name="top_page" value="1"/>
                </go>
              </anchor>
        	    <br/>&#160;&#160;2.000,00&#160;SEK<br/>
        	  </p>
          </card>
        END
        @account = Nordea::Account.new_from_xml(@xml_node, Nordea::Session.new('foo', 'bar'))
      end
    
      should "create a new Account instance" do
        assert_instance_of Nordea::Account, @account
      end
      
      should "set the session object" do
        assert_instance_of Nordea::Session, @account.session
      end
      
      should "have a name" do
        assert_equal "Sparkonto", @account.name
      end
    
      should "have a currency" do
        assert_equal "SEK", @account.currency
      end
    
      should "have a balance" do
        assert_equal 2000.0, @account.balance
      end
      
      should "have an index" do
        assert_equal "1", @account.index
      end
    end
  end
end