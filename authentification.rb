$: << File.join(File.dirname(__FILE__),"middleware")

require 'sinatra'
require 'active_record'
require 'my_middleware'

# use RackCookieSession
use RackSession

# Database
config_file = File.join(File.dirname(__FILE__),"db","config_database.yml")
ActiveRecord::Base.establish_connection(YAML.load(File.open(config_file))["development"])

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

# Index
get '/' do
	if username
		erb :"index/connected"
	else
		erb :"index/not_connected"
	end
end

# Register form
get '/register' do
	if username
		redirect '/'
	else
		erb :"register/index"
	end
end

# Authentification form
get '/session' do
	if username
		redirect '/'
	else
		erb :"session/index"
	end
end

# Register validation
get '/register/new' do
	if username
		redirect '/'
	else
		
	end
end
