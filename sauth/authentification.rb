$: << File.dirname(__FILE__)

require 'sinatra'
require 'digest/sha1'

# Libs
require 'lib/member'
require 'lib/application'
require 'lib/utilisation'
require 'lib/token'

ENV['RACK_ENV'] ||= 'development'

# Database
require 'db/db'

# Specify public dir
set :public_folder, File.dirname(__FILE__) + '/www'
# Specify the port application
set :port, 9090

unless ENV['RACK_ENV'] == 'test'
	use Rack::Session::Cookie,
		:key => 'rack.session',
		:path => '/',
		:expire_after => 600	# 10 minutes
end	

helpers do
	
	def current_user
		Member.find_by_login(current_username)
	end
	
	def current_username
		session[:current_user]
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
	
	def connected?
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
	
	def flash
		flash = session[:flash]
		session[:flash] = nil
		flash
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
	@flash = flash
	
	if connected?
		@user_utilisations = Utilisation.get_utilisations(current_username)
		@user_applications = Application.get_applications(current_username)
		erb :"index/connected"
	else
		erb :"index/not_connected"
	end
end

# Register form
get '/members/new/?' do
	if connected?
		redirect '/'
	else
		erb :"members/new"
	end
end

# Register validation
post '/members/?' do
	if connected?
		redirect '/'
	else
		m = Member.new
		m.login = params['login']
		m.password = params['password']
		m.password_confirmation = params['password_confirmation']
		
		if m.valid?
			m.save
			login(m)
			redirect '/'
		else
			@error_register = m.errors.messages
			erb :"members/new"
		end
	end
end

# Authentification form
get '/?:app_name?/sessions/new/?' do
	app = Application.find_by_name(params['app_name'])
	if !params['app_name'].nil? && app.nil?
		session[:flash] = '<p class="error">The application which you want to access does not exist.</p>'
		redirect '/'
	elsif connected?
		redirect Application.get_redirect_url(app, params['origin'], current_user)
	else
		erb :"sessions/new"
	end
end

# Authentification validation
post '/?:app_name?/sessions/?' do
	app = Application.find_by_name(params['app_name'])
	if !params['app_name'].nil? && app.nil?
		session[:flash] = '<p class="error">The application which you want to access does not exist.</p>'
		redirect '/'
	elsif connected?
		redirect Application.get_redirect_url(app, params['origin'], current_user)
	else
		m = Member.find_by_login(params['login'])
		
		if Member.authenticate?(params['login'], params['password'])
			# Authentification succeded
			login(m)
			redirect Application.get_redirect_url(app, params['origin'], current_user)
		else
			# Authentification failed			
			if(m.nil?)
				@error_session_message = :session_not_exists
			else
				@error_session_message = :session_failed
			end
			
			erb :"sessions/new"
		end
	end
end

# Register application form
get '/applications/new/?' do
	if !connected?
		redirect '/'
	else
		erb :"applications/new"
	end
end

# Register an application
post '/applications/?' do
	if !connected?
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
			erb :"applications/new"
		end
	end
end

# Delete an application
get '/applications/destroy/:app_id/?' do
	if !connected?
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
get '/sessions/logout/?' do
	logout
	redirect '/'
end

# Destroy his account
get '/sessions/destroy/?' do
	Member.delete(current_user.id)
	logout
	redirect '/'
end
