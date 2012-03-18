$: << File.dirname(__FILE__)

require 'sinatra'
require 'digest/sha1'

# Specify the port application
set :port, 9292

enable :sessions

# Index
get '/' do
	erb :index
end

# Protected section
get '/protected/?' do
if !session[:current_user_App2].nil? || (!params['token'].nil? && !params['login'].nil? && params['token'] == Digest::SHA1.hexdigest('71a5c88006a424c1bf0514cf9963f3366498c041' + params['login']))
  # User connected
  session[:current_user_App2] ||= params['login']
  # Here is your protected section, put your private code
  erb :protected
elsif !params['token'].nil? && !params['login'].nil?
  # Access refused
  'You cannot access to this section !' else
  redirect 'http://localhost:9090/App2/sessions/new?origin=' + request.path
end 
end

