$: << File.dirname(__FILE__)

require 'sinatra'
require 'digest/sha1'

# Libs
require 'lib/member'
require 'lib/token'

# Database
config_file = File.join(File.dirname(__FILE__),"db", "config_database.yml")
ActiveRecord::Base.establish_connection(YAML.load(File.open(config_file))["authentification"])

# Specify public dir
set :public_folder, File.dirname(__FILE__) + '/www'

enable :sessions

helpers do
	def is_connected
		if session[:current_user].nil? && !request.cookies['token'].nil?
			user = Member.find_by_token(request.cookies['token'])
			
			if !user.nil?
				# Token available
				login(user)
			else
				# Wrong token
				logout
			end
		end
		
		!session[:current_user].nil?
	end
	
	def login(user)
		session[:current_user] = {
			:login => user.login
		}
		
		token = Token.generate
		# Update token in database
		current_user = Member.find_by_login(user.login)
		current_user.token = token
		current_user.save
		# Cookie available 1 week
		response.set_cookie('token', {:value => token, :expires => Time.parse(Date.today.next_day(7).to_s), :path => '/'})
	end
	
	def logout
		session[:current_user] = nil
		response.set_cookie('token', {:value => '', :expires => Time.at(0), :path => '/'})
	end
	
	# Views helpers
	def get_field_value(field_name)
		if !params[field_name].nil?
			params[field_name]
		end
	end
	
	def is_field_error(error_messages, field_name)
		if !error_messages.nil? && !error_messages[field_name].nil?
			' field_error'
		end
	end
	
	def get_field_error_message(error_messages, field_name)
		if !error_messages.nil? && !error_messages[field_name].nil?
			error_msg = '<div class="error_messages"><p>Errors appears in ' + field_name.to_s + ' :</p><ul>'
				error_messages[field_name].each do |msg|
					error_msg += '<li>' + msg + '</li>'
				end
			error_msg += '</ul></div>'
			
			error_msg
		end
	end

end

# Index
get '/' do
	if is_connected
		erb :"index/connected"
	else
		erb :"index/not_connected"
	end
	
	#puts "\n\n" + request.cookies['token'].inspect + "\n\n"
end

# Register form
get '/register' do
	if is_connected
		redirect '/'
	else
		erb :"register/form"
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

# Authentification form
get '/session' do
	if is_connected
		redirect '/'
	else
		erb :"session/form"
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

get '/session/destroy' do
	logout
	redirect '/'
end
