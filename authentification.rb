$: << File.dirname(__FILE__)

require 'sinatra'

# Libs
require 'lib/member'

# Database
config_file = File.join(File.dirname(__FILE__),"db", "config_database.yml")
ActiveRecord::Base.establish_connection(YAML.load(File.open(config_file))["authentification"])

# Specify public dir
set :public_folder, File.dirname(__FILE__) + '/www'

enable :sessions

helpers do 
  def current_user
    session[:current_user]
  end
	
  def disconnect
    session[:current_user] = nil
  end
end

# Index
get '/' do	
	if session[:current_user].nil?
		erb :"index/not_connected"
	else
		erb :"index/connected"
	end
end

# Register form
get '/register' do
	if current_user
		redirect '/'
	else
		erb :"register/form"
	end
end

# Authentification form
get '/session' do
	if current_user
		redirect '/'
	else
		erb :"session/form"
	end
end

# Register validation
post '/register/new' do
	if current_user
		redirect '/'
	else
		
	end
end

# Authentification validation
post '/session/new' do
	if current_user
		redirect '/'
	else
		m = Member.find_by_login(params['login'])
		
		if Member.authenticate(params['login'], params['password'])
			# Authentification succeded
			session[:current_user] = m.login
			redirect '/'
			# Il faut ajouter le cookie : token ?
		else
			# Authentification failed
			@login = params['login']
			
			if(m.nil?)
				@error_session_message = :session_not_exists
			else
				@error_session_message = :session_failed
			end
			
			erb :"session/form"
		end
	end
end
