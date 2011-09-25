require 'sinatra'
require 'connexionz'
require 'haml'
require 'tropo-webapi-ruby'
require 'json'

set :sender_phone, ENV['SMS_PHONE']
set :va_phone, ENV['VA_PHONE']
set :char_phone, ENV['CHAR_PHONE']

post '/index.json' do

  v = Tropo::Generator.parse request.env["rack.input"].read

  t = Tropo::Generator.new

  t.say "Welcome to yak bus"

  t.ask :name => 'digit',
        :timeout => 60,
        :say => {:value => "Enter the five digit bus stop number"},
        :choices => {:value => "[5 DIGITS]",:mode => "dtmf"}

  t.on :event => 'continue', :next => '/continue.json'

  t.response

end

post '/continue.json' do

  v = Tropo::Generator.parse request.env["rack.input"].read

  t = Tropo::Generator.new

  answer = v[:result][:actions][:digit][:value]

  stop = get_et_info('sc', answer)

  t.say(:value => stop)

  t.on  :event => 'continue', :next => '/next.json'

  t.response

end

post '/next.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read

  t = Tropo::Generator.new
  t.ask :name => 'next', :bargein => true, :timeout => 60, :attempts => 1,
        :say => [{:event => "nomatch:1", :value => "That wasn't a valid answer. "},
                {:value => "Would you like hear another bus stop?
                Press 1 or say 'yes'; Press 2 or say 'no' to conclude this session."}],
        :choices => { :value => "true(1,yes), false(2,no)"}

    t.on  :event => 'continue', :next => '/index.json'
    t.on  :event => 'hangup', :next => '/hangup.json'

  t.response
end

post '/sms_incoming.json' do

  t = Tropo::Generator.new

  v = Tropo::Generator.parse request.env["rack.input"].read

  initialText = v[:session][:initial_text]

  stop = get_et_info('sc', initialText)

  t.say(:value => stop)

  t.hangup

  t.on  :event => 'hangup', :next => '/hangup.json'

  t.response

end

post '/hangup.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read
  puts " Call complete (CDR received). Call duration: #{v[:result][:session_duration]} second(s)"
end

def get_et_info(location,platform)

  if location == "va"
    @client = Connexionz::Client.new({:endpoint => "http://realtime.commuterpage.com"})
  elsif location == "char"
   @client = Connexionz::Client.new({:endpoint => "http://avlweb.charlottesville.org"})
  else
    @client = Connexionz::Client.new({:endpoint => "http://12.233.207.166"})
  end

   @platform_info = @client.route_position_et({:platformno => platform})

   if @platform_info.route_position_et.platform.nil?
     sms_message = "No bus stop found"
   else
      name = @platform_info.route_position_et.platform.name
      arrival_scope = @platform_info.route_position_et.content.max_arrival_scope
      sms_message = ""
      eta = ""
      if @platform_info.route_position_et.platform.route.nil?
        sms_message = "No arrivals for next #{arrival_scope} minutes"
      elsif @platform_info.route_position_et.platform.route.class == Array
        @platforms = @platform_info.route_position_et.platform.route
        @platforms.each do |platform|
          sms_message += "Route #{platform.route_no}-Destination #{platform.destination.name}-ETA #{platform.destination.trip.eta } minutes "
        end
      else
        route_no = @platform_info.route_position_et.platform.route.route_no
        destination = @platform_info.route_position_et.platform.route.destination.name
        if @platform_info.route_position_et.platform.route.destination.trip.is_a?(Array)
         @platform_info.route_position_et.platform.route.destination.trip.each do |mult_eta|
           eta += "#{mult_eta.eta} min "
         end
       else
         eta = "#{@platform_info.route_position_et.platform.route.destination.trip.eta} min"
       end
       sms_message = "Route #{route_no} " + "-Destination #{destination} " + "-ETA #{eta}"
      end
   end
  sms_message
 end


##################
### WEB ROUTES ###
##################
get '/' do
  haml :root
end

get '/sc/:name' do
   #matches "GET /sc/19812"
   get_et_info('sc',params[:name])
 end

 get '/va/:name' do
   #matches "GET /va/41215"
   get_et_info('va',params[:name])
 end

get '/char/:name' do
   #matches "GET /char/19812"
   get_et_info('char',params[:name])
 end


