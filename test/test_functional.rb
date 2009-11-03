require "test_helper"

class FunctionalTest < Test::Unit::TestCase
  context "functional testing" do
    class ::Nordea::Request
      alias_method :orig_connection, :connection
      def faked_connection
        FakedConnection.new(@command)
      end
    end
    
    setup do
      Nordea::Request.send :alias_method, :connection, :faked_connection
    end

    teardown do
      Nordea::Request.send :alias_method, :connection, :orig_connection
    end
    
    should "login and display the number of accounts" do
      def assert_requests_made(session, num_requests = 1, msg = nil, &blk)
        before = session.num_requests
        yield
        after = session.num_requests
        assert_equal before + num_requests, after, msg
      end
      
      Nordea.new('1234567890', '0987') do |n|
        
        # logging in
        assert_equal 2, n.num_requests # requires 2 requests to login
        
        # listing the accounts
        assert_requests_made(n, 1) { n.accounts.size }
        assert_requests_made(n, 0) do
          assert_equal %w[Sparkonto Huvudkonto Betalkonto], n.accounts.map(&:name)
        end
        
        assert_requests_made(n, 1, "reloading the accounts cache") { n.accounts(true) }
        
        # getting one of the account's transactions
        assert_requests_made(n, 2) do
          assert_equal 5, n.accounts.first.transactions.size # we use the same ficture so all accounts have 20 transactions
        end
        
        # re-ask for the num of transactions
        assert_requests_made(n, 0) do
          assert_equal 5, n.accounts['Sparkonto'].transactions.size
        end
        
        assert_requests_made(n, 2, "reload the cached transactions list") { 
          n.accounts['Sparkonto'].transactions(true).size 
        }
        
        # ask for the other accounts's transactions
        assert_requests_made(n, 4) do
          assert_equal 10, n.accounts['Huvudkonto'].transactions.size
          assert_equal 20, n.accounts['Betalkonto'].transactions.size
        end
      end
    end
  end
end