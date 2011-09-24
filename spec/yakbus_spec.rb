require File.dirname(__FILE__) + '/spec_helper'

describe 'Yakbus Application' do

  describe "the home page" do
    it "Should return the home page" do
      get '/'
      last_response.should be_ok
    end
  end

  describe "route_et" do
    it "should return no bus stop found" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10000").
        to_return(:status => 200, :body => fixture("no_platform.xml"))
      get '/sc/10000'
      last_response.should be_ok
      last_response.body.should == 'No bus stop found'
    end

    it "should return no arrivals for scope" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=15414").
        to_return(:status => 200, :body => fixture("no_arrivals.xml"))
      get '/sc/15414'
      last_response.should be_ok
      last_response.body.should == "No arrivals for next 30 minutes"
    end

    it "should return the time for the one arrival" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10656").
        to_return(:status => 200, :body => fixture("one_arrival.xml"))
      get '/sc/10656'
      last_response.should be_ok
      last_response.body.should =="Route 2 -Destination Val Verde -ETA 20 min"
    end

    it "should return the time for the next arrival" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10246").
        to_return(:status => 200, :body => fixture("route_et.xml"))
      get '/sc/10246'
      last_response.body.should == "Route 1-Destination Castaic-ETA 24 minutes Route 4-Destination LARC-ETA 19 minutes Route 6-Destination Shadow Pines-ETA 17 minutes Route 14-Destination Plum Cyn-ETA 11 minutes "
    end

    it "should return the time for the same stop with multiple arrivals" do
      stub_request(:get, "http://avlweb.charlottesville.org/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10687").
        to_return(:status => 200, :body => fixture("charlotesville.xml"))
      get '/char/10687'
      last_response.body.should == "Route ULA -Destination University Loop via Stadium -ETA 1 min 16 min "
    end

    it "should return the results for Arlington County, VA" do
      stub_request(:get, "http://realtime.commuterpage.com/rtt/public/utility/file.aspx?Name=RoutePositionET.xml&contenttype=SQLXML&platformno=87017").
          to_return(:status => 200, :body => fixture("va_single.xml"))
      get 'va/87017'
      last_response.body.should == "Route 87 -Destination Shirlington Station -ETA 17 min"
    end
  end
end

