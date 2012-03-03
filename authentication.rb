$: << File.join(File.dirname(__FILE__),"middleware")

require 'sinatra'
require 'my_middleware'

# use RackCookieSession
use RackSession

# Specify public dir
set :public_folder, File.dirname(__FILE__) + '/www'

helpers do 
  def username
    session["username"]
  end
	
  def disconnect
    session["username"] = nil
  end
end

get '/' do
	if username
		erb :"index/connected"
	else
		erb :"index/not_connected"
	end
end

get '/register' do
	erb :register
end

get '/session/new' do
	erb :register
end

get '/sessions/destroy' do
disconnect
redirect '/'
end

post '/sessions' do
if params[:login] == "toto"
session["current_user"] = params[:login]
redirect "/protected"
else
redirect "/sessions/new"
end
end

before '/protected' do
redirect 'sessions/new' unless current_user
end

get '/protected' do
"well played #{current_user}. Now you can <a href=\"/sessions/destroy\">disconnect</a>."
end
