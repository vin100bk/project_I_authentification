$: << File.dirname(__FILE__)

require 'sinatra'
require 'digest/sha1'

# Specify the port application
set :port, 9191

enable :sessions

# Index
get '/' do
	erb :index
end

# Protected section
get '/protected/?' do	
if !session[:current_user_App1].nil? || (!params['token'].nil? && !params['login'].nil? && params['token'] == Digest::SHA1.hexdigest('84cdfa71d92b23d866a7698bf7d796ed886a8826' + params['login']))
  # User connected
  session[:current_user_App1] ||= params['login']
  # Here is your protected section, put your private code
  erb :protected
elsif !params['token'].nil? && !params['login'].nil?
  # Access refused
  'You cannot access to this section !' else
  redirect 'http://localhost:9090/App1/sessions/new?origin=' + request.path
end 
end

