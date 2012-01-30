require File.dirname(__FILE__) + '/spec_helper'

describe 'Yakbus Application' do

  before(:all) do
    set :sender_phone, '555-555-1212'
    set :va_phone, '+15711234567'
    set :char_phone, '15551234567'
    set :spanish_va, '+15715551234'
    set :spanish_char, '+14345551234'
  end


  describe '/index.json' do
    it "should respond to an incoming call" do
      json = '{"session":
                {"id":"d7a7f84ee0b497e73d152a62c99b1fc9",
                  "accountId":"12345",
                  "timestamp":"2011-09-25T18:36:30.737Z",
                  "userType":"HUMAN",
                  "initialText":null,
                  "callId":"abc123",
                  "to":{
                    "id":"6615551234",
                    "name":"+16615551234",
                    "channel":"VOICE",
                    "network":"SIP"
                    },
                  "from":{
                    "id":"661-4444-5555",
                    "name":"+16614445555",
                    "channel":"VOICE",
                    "network":"SIP"
                    }
                  }
              }'

      post '/index.json',json
      last_response.body.should == "{\"tropo\":[{\"say\":[{\"value\":\"Welcome to yak bus\"}]},{\"ask\":{\"name\":\"digit\",\"timeout\":60,\"say\":{\"value\":\"Enter the five digit bus stop number\"},\"choices\":{\"value\":\"[5 DIGITS]\",\"mode\":\"dtmf\"}}},{\"on\":{\"event\":\"continue\",\"next\":\"/continue.json\"}}]}"
    end
  end

  describe '/continue.json' do
    it "should return the arrival times for a phone call" do
      json = '{"result":
                {"sessionId":"d7a7f84ee0b497e73d152a62c99b1fc9",
                  "callId":"abc123",
                  "state":"ANSWERED",
                  "sessionDuration":7,
                  "sequence":1,
                  "complete":true,
                  "error":null,
                  "actions":{
                    "name":"digit",
                    "attempts":1,
                    "disposition":"SUCCESS",
                    "confidence":100,
                    "interpretation":"10246",
                    "utterance":"1 0 2 4 6",
                    "value":"10246",
                    "xml":"<?xml version=\"1.0\"?>\r\n<result grammar=\"0@3c442890.vxmlgrammar\">\r\n <interpretation grammar=\"0@3c442890.vxmlgrammar\" confidence=\"100\">\r\n \r\n <input mode=\"dtmf\">dtmf-1 dtmf-0 dtmf-2 dtmf-4 dtmf-6<\/input>\r\n <\/interpretation>\r\n<\/result>\r\n"
                    }
                  }
                }'

      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10246").
        to_return(:status => 200, :body => fixture("route_et.xml"))

      post '/continue.json', json
      last_response.body.should == "{\"tropo\":[{\"say\":[{\"value\":\"1-Castaic-ETA:24 4-LARC-ETA:19 6-Shadow Pines-ETA:17 14-Plum Cyn-ETA:11\"}]},{\"on\":{\"event\":\"continue\",\"next\":\"/next.json\"}}]}"
    end
  end

  describe '/next.json' do
    it "should respond to true or false" do
      json = '{"result":
                {"sessionId":"97365531b728cc3e2a18dcc48119289a",
                  "callId":"abc123",
                  "state":"ANSWERED",
                  "sessionDuration":23,
                  "sequence":2,"complete":true,
                  "error":null
                  }
              }'

    post '/next.json', json
    last_response.body.should == "{\"tropo\":[{\"ask\":{\"name\":\"next\",\"bargein\":true,\"timeout\":60,\"attempts\":1,\"say\":[{\"event\":\"nomatch:1\",\"value\":\"That wasn't a valid answer. \"},{\"value\":\"Would you like hear another bus stop?\\n                Press 1 for yes; Press 2 to end this call.\"}],\"choices\":{\"value\":\"true(1), false(2)\"}}},{\"on\":{\"event\":\"continue\",\"next\":\"/index.json\"}},{\"on\":{\"event\":\"hangup\",\"next\":\"/hangup.json\"}}]}"

    end
  end

  describe '/sms_incoming.json' do
    it "should respond to an incoming text message for Santa Clarita" do
      json = '{
                "session":{
                  "id":"1aa06515183223ec0894039c2af433f2",
                  "accountId":"33932",
                  "timestamp":"2010-02-18T19:07:36.375Z",
                  "userType":"HUMAN",
                  "initialText":"10246",
                  "to":{
                    "id":"155551234",
                    "name":"unknown",
                    "channel":"TEXT",
                    "network":"SMS"
                      },
                  "from":{
                    "id":"16615551234",
                    "name":null,
                    "channel":"TEXT",
                    "network":"SMS"
                      }
                  }
            }'
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10246").
        to_return(:status => 200, :body => fixture("route_et.xml"))
      post '/sms_incoming.json',json
      last_response.body.should =="{\"tropo\":[{\"say\":[{\"value\":\"1-Castaic-ETA:24 4-LARC-ETA:19 6-Shadow Pines-ETA:17 14-Plum Cyn-ETA:11\"}]},{\"hangup\":null},{\"on\":{\"event\":\"hangup\",\"next\":\"/hangup.json\"}}]}"
    end
  end

  describe '/sms_incoming.json' do
    it "should respond to an incoming text message for Arlington, VA" do
      json = '{
                "session":{
                  "id":"1aa06515183223ec0894039c2af433f2",
                  "accountId":"33932",
                  "timestamp":"2010-02-18T19:07:36.375Z",
                  "userType":"HUMAN",
                  "initialText":"87017",
                  "to":{
                    "id":"15711234567",
                    "name":"unknown",
                    "channel":"TEXT",
                    "network":"SMS"
                      },
                  "from":{
                    "id":"16615551234",
                    "name":null,
                    "channel":"TEXT",
                    "network":"SMS"
                      }
                  }
            }'
      stub_request(:get, "http://realtime.commuterpage.com/rtt/public/utility/file.aspx?Name=RoutePositionET.xml&contenttype=SQLXML&platformno=87017").
        to_return(:status => 200, :body => fixture("va_single.xml"))
      post '/sms_incoming.json',json
      last_response.body.should == "{\"tropo\":[{\"say\":[{\"value\":\"87-Shirlington Station-ETA:17\"}]},{\"hangup\":null},{\"on\":{\"event\":\"hangup\",\"next\":\"/hangup.json\"}}]}"
    end
  end

  describe '/spanish_sms.json' do
    it "should respond to an incoming text message for Santa Clarita" do
      json = '{
                "session":{
                  "id":"1aa06515183223ec0894039c2af433f2",
                  "accountId":"33932",
                  "timestamp":"2010-02-18T19:07:36.375Z",
                  "userType":"HUMAN",
                  "initialText":"10246",
                  "to":{
                    "id":"155551234",
                    "name":"unknown",
                    "channel":"TEXT",
                    "network":"SMS"
                      },
                  "from":{
                    "id":"16615551234",
                    "name":null,
                    "channel":"TEXT",
                    "network":"SMS"
                      }
                  }
            }'
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10246").
        to_return(:status => 200, :body => fixture("route_et.xml"))
      post '/spanish_sms.json',json
      last_response.body.should =="{\"tropo\":[{\"say\":[{\"value\":\"1-Castaic-ETA:24 4-LARC-ETA:19 6-Shadow Pines-ETA:17 14-Plum Cyn-ETA:11\"}]},{\"hangup\":null},{\"on\":{\"event\":\"hangup\",\"next\":\"/hangup.json\"}}]}"
    end
  end


  describe "hangup.json" do
    it "should return the hangup info" do
      json = '{"result":
                {"sessionId":"d7a7f84ee0b497e73d152a62c99b1fc9",
                  "callId":"abc123",
                  "state":"DISCONNECTED",
                  "sessionDuration":22,
                  "sequence":2,
                  "complete":true,
                  "error":null
                  }
              }'
    post '/hangup.json', json
    last_response.should be_ok
    end
  end

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
      last_response.body.should == "2-Val Verde-ETA:20"
    end

    it "should return the time for the next arrival" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10246").
        to_return(:status => 200, :body => fixture("route_et.xml"))
      get '/sc/10246'
      last_response.body.should == "1-Castaic-ETA:24 4-LARC-ETA:19 6-Shadow Pines-ETA:17 14-Plum Cyn-ETA:11"
    end

    it "should return the time for the same stop with multiple arrivals" do
      stub_request(:get, "http://avlweb.charlottesville.org/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10687").
        to_return(:status => 200, :body => fixture("charlotesville.xml"))
      get '/char/10687'
      last_response.body.should == "ULA-University Loop via Stadium-ETA:1,16"
    end

    it "should return the times for Tri Delta" do
      stub_request(:get, "http://70.232.147.132/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=812262").
        to_return(:status => 200, :body => fixture("tri_delta_multi.xml"))
      get '/tri/812262'
      last_response.body.should == "392-Eastbound Hillcrest Park & Ride-ETA:38,44"
    end

    it "should return the results for Arlington County, VA" do
      stub_request(:get, "http://realtime.commuterpage.com/rtt/public/utility/file.aspx?Name=RoutePositionET.xml&contenttype=SQLXML&platformno=87017").
          to_return(:status => 200, :body => fixture("va_single.xml"))
      get '/va/87017'
      last_response.body.should == "87-Shirlington Station-ETA:17"
    end
  end
end

