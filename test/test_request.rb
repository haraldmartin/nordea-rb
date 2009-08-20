require "test_helper"

class TestRequest < Test::Unit::TestCase
  context "a request in general" do
    setup do
      @http = mock("Net::HTTP")
      @response = mock("Net::HTTPResponse")
      @response.stubs(:body => 'the body')
      @http.stubs(:use_ssl= => true, :post => @response)
      Net::HTTP.stubs(:new).returns(@http)
    end
    
    should "use create a new Net:HTTP instance" do
      Net::HTTP.expects(:new).returns(@http)
      request = Nordea::Request.new('foo')
    end
    
    should "use ssl" do
      @http.expects(:use_ssl=).with(true)
      request = Nordea::Request.new('foo')
    end
    
    context "the query string" do
      should "include the command as OBJECT" do
        request = Nordea::Request.new('foo')
        assert_match /OBJECT=foo/, request.query
      end
      
      should "include extra params if sent" do
        request = Nordea::Request.new('cmd', { :foo => 'bar', :boo => 'far' })
        assert_match /OBJECT=cmd/, request.query
        assert_match /foo=bar/, request.query
        assert_match /boo=far/, request.query
      end
    end
    
    should "parse the xml" do
      Hpricot.expects(:XML).with("foo")
      @response.stubs(:body).returns("foo")
      request = Nordea::Request.new('cmd')
      request.parse_xml
    end
  end
end
