$: << File.dirname(__FILE__)

require 'sinatra'
require 'digest/sha1'

# Libs
require 'lib/member'
require 'lib/application'
require 'lib/utilisation'
require 'lib/token'

# Database
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => File.join(File.dirname(__FILE__), 'db', 'authentification.sqlite3'))

# Specify public dir
set :public_folder, File.dirname(__FILE__) + '/www'
# Specify the port application
set :port, 9090

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
	
	def current_user
		Member.find_by_login(current_username)
	end
	
	def current_username
		session[:current_user]
	end
	
	def flash
		flash = session[:flash]
		session[:flash] = nil
		flash
	end
	
	def login(user)
		session[:current_user] = user.login
		
		token = Token.generate
		# Update token in database
		user.token = token
		user.save
		# Cookie available for 1 week
		response.set_cookie('token', {:value => token, :expires => Time.parse(Date.today.next_day(7).to_s), :path => '/'})
	end
	
	def logout
		session[:current_user] = nil
		response.set_cookie('token', {:value => '', :expires => Time.at(0), :path => '/'})
	end
	
	def get_redirect_url
		if !params['app_name'].nil?
			app = Application.find_by_name(params['app_name'])
		
			# App exists (tested before)
			redirect_url = app.url + params['origin'] + '?login=' + current_username + '&token=' + Digest::SHA1.hexdigest(app.token + current_username)
			# Save the utilisation
			u = Utilisation.new
			u.application = app
			u.member = current_user
			u.save
		else
			redirect_url = '/'
		end
		
		redirect_url
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
		@flash = flash
		@user_utilisations = Utilisation.get_utilisations(current_username)
		@user_applications = Application.get_applications(current_username)
		erb :"index/connected"
	else
		erb :"index/not_connected"
	end
end

# Register form
get '/register/new/?' do
	if is_connected
		redirect '/'
	else
		erb :"register/form"
	end
end

# Register validation
post '/register/new/?' do
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
get '/?:app_name?/session/new/?' do
	if !params['app_name'].nil? && !Application.exists?(params['app_name'])
		redirect '/session/new'
	elsif is_connected
		redirect get_redirect_url
	else
		erb :"session/form"
	end
end

# Authentification validation
post '/?:app_name?/session/new/?' do
	if !params['app_name'].nil? && !Application.exists?(params['app_name'])
		redirect '/session/new'
	elsif is_connected
		redirect get_redirect_url
	else
		m = Member.find_by_login(params['login'])
		
		if Member.authenticate(params['login'], params['password'])
			# Authentification succeded
			login(m)
			redirect get_redirect_url
		else
			# Authentification failed			
			if(m.nil?)
				@error_session_message = :session_not_exists
			else
				@error_session_message = :session_failed
			end
			
			erb :"session/form"
		end
	end
end

# Register application form
get '/application/new/?' do
	if !is_connected
		redirect '/'
	else
		erb :"application/form"
	end
end

# Register an application
post '/application/new/?' do
	if !is_connected
		redirect '/'
	else
		a = Application.new
		a.name = params['name']
		a.url = params['url']
		a.token = Token.generate
		a.member = current_user
		
		if a.valid?
			# Valid application
			a.save
			session[:flash] = '<p class="validation">Your application has been added with succes.</p>'
			redirect '/'
		else
			# No valid application
			@error_registration_application = a.errors.messages
			erb :"application/form"
		end
	end
end

# Delete an application
get '/application/destroy/:app_id/?' do
	if !is_connected
		redirect '/'
	else
		a = Application.find_by_id(params[:app_id].to_i, :conditions => {:member_id => current_user.id})
		
		if !a.nil?
			Application.delete(params[:app_id].to_i)
			session[:flash] = '<p class="validation">The application has been deleted with success.</p>'
			redirect '/'
		else
			# Unknown application
			session[:flash] = '<p class="error">The application you want to delete does not exist.</p>'
			redirect '/'
		end
	end
end

# Logout
get '/session/logout/?' do
	logout
	redirect '/'
end

# Destroy his account
get '/session/destroy/?' do
	Member.delete(current_user.id)
	logout
	redirect '/'
end
