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
	def is_connected
		!session[:current_user].nil?
	end
	
	def login(user)
		session[:current_user] = user.login
	end
end

# Index
get '/' do	
	if is_connected
		erb :"index/connected"
	else
		erb :"index/not_connected"
	end
end

# Register form
get '/register' do
	if is_connected
		redirect '/'
	else
		erb :"register/form"
	end
end

# Authentification form
get '/session' do
	if is_connected
		redirect '/'
	else
		erb :"session/form"
	end
end

# Register validation
post '/register/new' do
	if is_connected
		redirect '/'
	else
		m = Member.new
		m.login = params['login']
		m.password = params['password']
		m.password_confirmation = params['password_confirmation']
		
		if m.valid?
			# Le membre valide
			m.save
			login(m)
			redirect '/'
		else
			# Membre non valide
			@error_register = m.errors.messages
			erb :"register/form"
		end
	end
end

# Authentification validation
post '/session/new' do
	if is_connected
		redirect '/'
	else
		m = Member.find_by_login(params['login'])
		
		if Member.authenticate(params['login'], params['password'])
			# Authentification succeded
			login(m)
			redirect '/'
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
