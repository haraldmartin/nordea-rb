require "test_helper"

class TestSession < Test::Unit::TestCase
  context "a session in general" do
    setup do
      user, code = "1234567890", "1234"
      @session = Nordea::Session.new(user, code)
      @phase1_params = { :kundnr => user, :pinkod => code, :sid => "0" }
      @response = stub(:parse_xml => '<foo></foo>')
    end
    
    context "logging in" do
      setup do
        @xml_fixture = fixture_content('login')
        @xml_data = Hpricot.XML(@xml_fixture)
        @response.stubs(:parse_xml).returns(@xml_data)
        Nordea::Request.stubs(:new).returns(@response)
      end
      
      should "send the first request (login phase #1)" do
        Nordea::Request.expects(:new).with('WAP00', @phase1_params).returns(@response)
        @session.login
      end
      
      should "parse the response xml" do
        @response.expects(:parse_xml).returns(@xml_data)
        @session.login
      end
      
      should 'set the token from the response xml' do
        @session.login
        assert_equal "123456789", @session.token
      end
      
      should "make the second request (login phase #2)" do
        Nordea::Request.expects(:new).with('KK10', {
          :bank => "mobile_light", :sid => '123456789', 
          :no_prev => "1", :contract => "0000000:HI:FOO+BAR" })
        @session.login
      end
    end
    
    context "invalid login" do
      setup do
        @xml_fixture = fixture_content('error')
        @xml_data = Hpricot.XML(@xml_fixture)
        @response.stubs(:parse_xml).returns(@xml_data)
        Nordea::Request.stubs(:new).returns(@response)
      end
      
      should "raise Nordea::InvalidLogin if login is invalid" do
        assert_raise(Nordea::InvalidLogin) { @session.login }
      end
      
      should "get the error message from the xml doc" do
        begin
          @session.login
        rescue Nordea::InvalidLogin => e
          assert_equal "Pinkoden ni angivit är spärrad", e.message
        end
      end
    end
    
    should "use the sid param as token if set" do
      Nordea::Request.expects(:new).with('cmd', { :sid => 't0k3n' })
      @session.request('cmd', { :sid => 't0k3n' })
    end
    
    should "request a token unless there is one" do
      @session.expects(:token).returns('my-token')
      Nordea::Request.expects(:new).with('cmd', { :sid => 'my-token' })
      @session.request('cmd')
    end

    should "logout" do
      Nordea::Request.expects(:new).with('LL99', { :sid => 'token'})
      @session.token = 'token'
      @session.logout
    end
  end
  
  context "creating the account objects" do
    setup do
      @session = Nordea::Session.new('1234567890', '1234')
      @response = stub(:parse_xml => Hpricot.XML(fixture_content('accounts')))
      Nordea::Request.stubs(:new).returns(@response)
    end
  
    should "should setup the accounts" do
      assert_equal 3, @session.accounts.size
    end
  
    should "set each account's name" do
      names = @session.accounts.map(&:name)
      assert_equal ["Betalkonto", "Huvudkonto", "Sparkonto"], names.sort
    end
  
    should "find each accounts's balance" do
      balances = { "Sparkonto"  => 2000.00,
  			           "Huvudkonto" => 5643.50,
  			           "Betalkonto" =>  179.05 }
      @session.accounts.each do |account|
        assert_equal balances[account.name], account.balance
      end
    end
  
    should "find each accounts's currency" do
      assert_equal ["SEK"], @session.accounts.map(&:currency).uniq
    end
    
    should "respond to #to_command_params with the extra parameters" do
      assert_equal({
        'account_name'          => 'Sparkonto',
        'account_index'         => '1',
        'account_type'          => '001',
        'account_currency_code' => 'SEK',
        'top_page'              => '1'
      }, @session.accounts.first.to_command_params)
    end
    
    should "access the account by name using #[]" do
      assert_equal @session.accounts[1], @session.accounts["Huvudkonto"]
    end

    should "find the account's name by pattern when using #[] with a regexp" do
      assert_equal @session.accounts[1], @session.accounts[/huvud/i]
    end
  end
end
