require 'sinatra'
require 'connexionz'
require 'haml'
require 'tropo-webapi-ruby'
require 'json'

#Manage the web session coookies
use Rack::Session::Pool

post '/index.json' do

  v = Tropo::Generator.parse request.env["rack.input"].read

  session[:from] = v[:session][:from]
  session[:network] = v[:session][:to][:network]
  session[:channel] = v[:session][:to][:channel]

  t = Tropo::Generator.new

  if v[:session][:initial_text]
      # Add an 'ask' WebAPI method to the JSON response with appropriate options
      t.ask :name => 'initial_text', :choices => { :value => "[ANY]"}
      session[:stop_number] = v[:session][:initial_text]
  else
    t.ask :name => 'digit',
        :timeout => 60,
        :say => {:value => "Enter the five digit bus stop number"},
        :choices => {:value => "[5 DIGITS]", :mode => "keypad"}
  end

  t.on :event => 'continue', :next => '/continue.json'

  t.response

end

post '/continue.json' do

  v = Tropo::Generator.parse request.env["rack.input"].read

  t = Tropo::Generator.new

  if session[:stop_number]
    answer = session[:stop_number]
  else
    answer = v[:result][:actions][:digit][:value]
  end

  stop = get_et_info('sc', answer)

  if session[:network] == "SMS"
    t.message({
        :to => session[:from],
        :network => "SMS",
        :say => {:value => stop}})
  else
    t.say(:value => stop)
  end

  t.response

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


