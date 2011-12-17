# encoding: utf-8
require 'sinatra'
require 'connexionz'
require 'haml'
require 'tropo-webapi-ruby'
require 'json'

set :sender_phone, ENV['SC_PHONE']
set :va_phone, ENV['VA_PHONE']
set :char_phone, ENV['CHAR_PHONE']
set :spanish_sc, ENV['SPANISH_SC']
set :spanish_va, ENV['SPANISH_VA']
set :spanish_char, ENV['SPANISH_CHAR']

use Rack::Session::Pool

post '/index.json' do

  v = Tropo::Generator.parse request.env["rack.input"].read

  session[:from] = v[:session][:from]
  session[:to_phone] = v[:session][:to][:name]
  session[:network] = v[:session][:to][:network]
  session[:channel] = v[:session][:to][:channel]

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

  if session[:to_phone] == settings.va_phone
    stop = get_et_info('va', answer)
  elsif session[:to_phone] == settings.char_phone
    stop = get_et_info('char', answer)
  else
    stop = get_et_info('sc', answer)
  end

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
                Press 1 for yes; Press 2 to end this call."}],
        :choices => { :value => "true(1), false(2)"}

    t.on  :event => 'continue', :next => '/index.json'
    t.on  :event => 'hangup', :next => '/hangup.json'

  t.response
end


post '/spanish.json' do

  v = Tropo::Generator.parse request.env["rack.input"].read

  session[:from] = v[:session][:from]
  session[:to_phone] = v[:session][:to][:name]
  session[:network] = v[:session][:to][:network]
  session[:channel] = v[:session][:to][:channel]

  t = Tropo::Generator.new

  t.say "Bienvenido al bus yak", :voice =>"esperanza"

  t.ask :name => 'digit',
        :timeout => 60,
        :say => {:value => "Introduzca los cinco dígitos del número parada de autobús"},
        :voice => "esperanza",
        :choices => {:value => "[5 DIGITS]"},
        :recognizer => "es-mx"

  t.on :event => 'continue', :next => '/continue_spanish.json'

  t.response

end

post '/continue_spanish.json' do

  v = Tropo::Generator.parse request.env["rack.input"].read

  t = Tropo::Generator.new

  answer = v[:result][:actions][:digit][:value]

  if session[:to_phone] == settings.spanish_va
    stop = get_et_info('va', answer)
  elsif session[:to_phone] == settings.spanish_char
    stop = get_et_info('char', answer)
  else
    stop = get_et_info('sc', answer)
  end

  if stop == "No bus stop found"
    stop = "No encuentra la parada de autobús"
  elsif stop == "No arrivals for next 30 minutes"
    stop = "No hay llegadas para los próximos 30 minutos"
  elsif stop == "No arrival for next 45 minutes"
    stop = "No hay llegadas para los próximos 45 minutos"
  else
    stop = stop.gsub('Destination', 'Destino')
    stop = stop.gsub('Route', 'Ruta')
    stop = stop.gsub('minutes', 'minutos')
  end

  t.say(:value => stop, :voice =>"esperanza")

  t.on  :event => 'continue', :next => '/next_spanish.json'

  t.response

end

post '/next_spanish.json' do
  v = Tropo::Generator.parse request.env["rack.input"].read

  t = Tropo::Generator.new
  t.ask :name => 'next', :bargein => true, :timeout => 60, :attempts => 1,
        :say => [{:event => "nomatch:1", :value => "Que no era una respuesta válida. "},
                {:value => "¿Te gustaría escuchar otra parada de autobús?
                  Presione 1 para sí, Pulse 2 para poner fin a esta convocatoria."}],
        :choices => { :value => "true(1), false(2)"},
        :voice => "esperanza",
        :recognizer => "es-mx"


    t.on  :event => 'continue', :next => '/spanish.json'
    t.on  :event => 'hangup', :next => '/hangup.json'

  t.response
end

post '/sms_incoming.json' do

  t = Tropo::Generator.new

  v = Tropo::Generator.parse request.env["rack.input"].read

  from = v[:session][:to][:id]
  initial_text = v[:session][:initial_text]


  if from == settings.va_phone.tr('+','')
    stop = get_et_info('va', initial_text)
  elsif from == settings.char_phone.tr('+','')
    stop = get_et_info('char', initial_text)
  else
    stop = get_et_info('sc', initial_text)
  end

  t.say(:value => stop)

  t.hangup

  t.on  :event => 'hangup', :next => '/hangup.json'

  t.response

end

post '/spanish_sms.json' do

  t = Tropo::Generator.new

  v = Tropo::Generator.parse request.env["rack.input"].read

  from = v[:session][:to][:id]
  initial_text = v[:session][:initial_text]


  if from == settings.spanish_va.tr('+','')
    stop = get_et_info('va', initial_text)
  elsif from == settings.spanish_char.tr('+','')
    stop = get_et_info('char', initial_text)
  else
    stop = get_et_info('sc', initial_text)
  end

  if stop == "No bus stop found"
    stop = "No encuentra la parada de autobús"
  elsif stop == "No arrivals for next 30 minutes"
    stop = "No hay llegadas para los próximos 30 minutos"
  elsif stop == "No arrival for next 45 minutes"
    stop = "No hay llegadas para los próximos 45 minutos"
  else
    stop = stop.gsub('Destination', 'Destino')
    stop = stop.gsub('Route', 'Ruta')
    stop = stop.gsub('minutes', 'minutos')
  end

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

  begin
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
      elsif @platform_info.route_position_et.platform.route.is_a?(Array)
        @platforms = @platform_info.route_position_et.platform.route
        @platforms.each do |platform|
          if platform.destination.is_a?(Array)
            platform.destination.each do |dest|
              sms_message += "#{platform.route_no}-#{dest.name}"
              sms_message += "-ETA:#{multi_eta(dest.trip)} "
            end
        else
          sms_message += "#{platform.route_no}-#{platform.destination.name}"
          sms_message += "-ETA:#{multi_eta(platform.destination.trip)} "
        end
      end
    else
      route_no = @platform_info.route_position_et.platform.route.route_no
      destination = @platform_info.route_position_et.platform.route.destination.name
      eta = multi_eta(@platform_info.route_position_et.platform.route.destination.trip)
      sms_message = "#{route_no}-#{destination}-ETA:#{eta}"
    end
  end

  rescue
    sms_message = "An error has occured please try again"
  end
    sms_message.rstrip
end

def multi_eta(eta)
  multi_eta = ""
  arr_eta = []
  if eta.is_a?(Array)
    eta.each do |mult_eta|
      arr_eta.push(mult_eta.eta)
      multi_eta = arr_eta.join(',')
    end
  else
    multi_eta = eta.eta
  end
  multi_eta
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


