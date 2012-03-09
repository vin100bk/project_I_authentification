$: << File.dirname(__FILE__)

require 'sinatra'
require 'digest/sha1'

# Specify public dir
set :public_folder, File.dirname(__FILE__) + '/www'
# Specify the port application
set :port, 9191

enable :sessions

# Index
get '/' do
	erb :index
end

# Protected section
get '/protected/?' do
	if !session[:current_user_app_1].nil? || (!params['token'].nil? && !params['login'].nil? && params['token'] == Digest::SHA1.hexdigest('0d438478f41655f34356f7564006e0589f194610' + params['login']))
		# User connected
		session[:current_user_app_1] ||= params['login']
		erb :protected
	else
		redirect 'http://localhost:9090/App_1/session/new?origin=/protected'
	end
	
end

