$: << File.join(File.dirname(__FILE__), '..')

require 'authentification'
require 'rack/test'

set :sessions, true

describe 'The Authentification App' do

	include Rack::Test::Methods

	def app
		Sinatra::Application
	end
	
	describe "Check available get pages" do

		it "Index" do
			get '/'
			last_response.should be_ok
		end 
		
		it "Register form" do
			get '/register/new'
			last_response.should be_ok
		end
		
		it "Connexion form" do
			get '/session/new'
			last_response.should be_ok
		end
		
		it "Registration application form" do
			get '/application/new'
			last_response.should be_redirect
		end
		
		it "Connexion form should be redirected with a non existing application" do
			get '/Test/session/new'
			last_response.should be_redirect
			follow_redirect!
			last_request.path.should == '/session/new'
		end
		
		it "Connexion form should be displayed with an existing application" do
			Application.should_receive(:exists?).with('Test').and_return(true)
			get '/Test/session/new'
			last_response.should be_ok
		end
		
	end
	
	describe "post '/session/new'" do
	
		before do
			@params = {
				'login' => 'Vin100',
				'password' => 'Password'
			}
			
			@m = double(Member)
			@m.stub(:login).and_return('Vin100')
			@m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')
			@m.stub(:token=).and_return('random_token')
			@m.stub(:save)
		end
	
		it "Should call authenticate method" do
			Member.should_receive(:authenticate).at_least(1).with('Vin100', 'Password')
			post '/session/new', @params
		end
		
		it "Should not authenticate with success" do
			post '/session/new', @params
			last_response.should be_ok	# If there is not redirection, authenticate failed
		end
		
		it "Session should not exists" do
			post '/session/new', @params
			last_response.body.include?('The account with the username').should be_true
		end
		
		it "Session should exists but with a wrong password" do
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('14ca9f63103e4c9ac356797bb6d1c76a51e91071')	# Value : My_password
			
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(m)
			
			post '/session/new', @params
			last_response.body.include?('The password does not match with the username').should be_true
		end
		
		it "Should authenticate with success" do
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
			post '/session/new', @params
			
			# If redirect : authentification sucessful
			last_response.should be_redirect
			follow_redirect!
			last_request.path.should == '/'
		end
		
		it "Should register the login into session with a successful authentification" do
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
			post '/session/new', @params
			
			follow_redirect!
			last_request.env['rack.session']['current_user'].should == 'Vin100'
		end
		
		it "Should register a token into a cookie after a successful authentification" do
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
			Token.should_receive(:generate).and_return('random_token')
			post '/session/new', @params
			
			follow_redirect!
			last_request.cookies['token'].nil?.should be_false
			last_request.cookies['token'].should == 'random_token'
		end
		
		context "post '/App_name/session/new'" do
		
			before do
				@app = double(Application)
				@app.stub(:url).and_return('http://www.google.fr')
				@app.stub(:token).and_return('random_token')
				
				@params['origin'] = '/protected'
			end
			
			it "Should authenticate with success with an existing client application" do
				Application.should_receive(:exists?).with('Test').and_return(true)
				Application.should_receive(:find_by_name).with('Test').and_return(@app)
				
				Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
				
				u = double(Utilisation)
				u.stub(:application=)
				u.stub(:member=)
				u.stub(:save)
				Utilisation.should_receive(:new).and_return(u)
				
				post '/Test/session/new', @params
				# If redirect : authentification sucessful
				last_response.should be_redirect
				follow_redirect!
				last_request.path.should == @params['origin']
				last_request.params['login'].should == @params['login']
				last_request.params['token'].should == Digest::SHA1.hexdigest('random_tokenVin100')
			end
			
		end
	
	end
	
	describe "post '/register/new'" do
		
		before(:each) do
			@params = {
				'login' => 'Vin100',
				'password' => 'Password',
				'password_confirmation' => 'Password'
			}
		end
		
		# Delete the member saved if existing
		after(:each) do
			m = Member.find_by_login('Vin100')
			
			unless m.nil?
				Member.delete(m.id)
			end
		end
		
		it "Should not register with success (ugly login)" do
			@params['login'] = 'vin@@100'
			
			post '/register/new', @params
			last_response.should be_ok	# If there is not redirection, error while registring
		end
		
		it "Should not register with success (login too short)" do
			@params['login'] = 'a'
			
			post '/register/new', @params
			last_response.should be_ok	# If there is not redirection, error while registring
		end
		
		it "Should not register with success (password confirmation)" do
			@params['password_confirmation'] = 'other_password'
			
			post '/register/new', @params
			last_response.should be_ok	# If there is not redirection, error while registring
		end
		
		# Other tests available for validators in member_spec.rb ...
		
		it "Should register with success" do
			post '/register/new', @params
			
			# If redirect : authentification sucessful
			last_response.should be_redirect
			follow_redirect!
			last_request.path.should == '/'
		end
		
		it "Should register the login into session with a successful registration" do
			post '/register/new', @params
			
			follow_redirect!
			last_request.env['rack.session']['current_user'].should == 'Vin100'
		end
		
		it "Should register a token into a cookie after a successful registration" do
			Token.should_receive(:generate).and_return('random_token')
			post '/register/new', @params
			
			follow_redirect!
			last_request.cookies['token'].nil?.should be_false
			last_request.cookies['token'].should == 'random_token'
		end
		
	end
	
	describe "Check login by cookie" do
	
		before do
			clear_cookies
		end
	
		it "Should be connected with a cookie" do
			# Set cookie
			set_cookie 'token=random_token'
			
			m = double(Member)
			m.stub(:login).and_return('Name')
			
			Member.should_receive(:find_by_token).with('random_token').and_return(m)
			Token.should_receive(:generate).and_return('other_token')
			
			get '/'
			last_request.cookies['token'].should == 'random_token'
			last_request.env['rack.session']['current_user'].should == 'Name'
		end
		
		it "Should not be connected with a wrong cookie" do
			# Set cookie
			set_cookie 'token=random_token'
			
			Member.should_receive(:find_by_token).with('random_token').and_return(nil)
			
			get '/'
			last_request.env['rack.session']['current_user'].should be_nil
		end
	
	end
	
	describe "Tests as connected member" do
	
		before do
			# Execute an authentification (cannot create session in tests ...)
			params = {
				'login' => 'Vin100',
				'password' => 'Password'
			}
			m = double(Member)
			m.stub(:id).and_return(1)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')
			m.stub(:token=)
			m.stub(:save)
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(m)
			post '/session/new', params
			follow_redirect!
		end
		
		describe "get '/session/logout'" do
			
			it "Should not have session and cookie after logout" do
				get '/session/logout'
				last_response.should be_redirect
				follow_redirect!
				last_request.path.should == '/'
				last_request.env['rack.session']['current_user'].should be_nil
				last_request.cookies['token'].should be_nil
			end
			
		end
		
		describe "get '/session/destroy'" do
		
			it "Should delete the account of the current user" do
				Member.should_receive(:delete).with(1)
				get '/session/destroy'
				last_response.should be_redirect
				follow_redirect!
				last_request.path.should == '/'
				last_request.env['rack.session']['current_user'].should be_nil
				last_request.cookies['token'].should be_nil
			end
		
		end
		
		describe "post '/application/new'" do
		
			before do
				@params = {
					'name' => 'App1',
					'url' => 'http://www.app1.com'
				}
			end
			
			after(:each) do
				a = Application.find_by_name(@params['name'])
			
				unless a.nil?
					Application.delete(a.id)
				end
			end
		
			it "Registration application form" do
				get '/application/new'
				last_response.should be_ok
			end
			
			it "Should not add the application with success (ugly name)" do
				@params['name'] = 'my cute application'
			
				a = Application.new
				a.member = Member.new
				a.stub(:member=).and_return(Member.new)
				Application.should_receive(:new).and_return(a)
			
				post '/application/new', @params
				last_response.should be_ok	# If there is not redirection, error while adding
			end
		
			# Other tests available for validators in application_spec.rb ...
		
			it "Should not add the application with success (ugly name)" do
				a = Application.new
				a.member = Member.new
				a.stub(:member=).and_return(Member.new)
				Application.should_receive(:new).and_return(a)
			
				post '/application/new', @params
				last_response.should be_redirect
			end
			
		end
		
		describe "get '/application/destroy/10'" do
		
			it "Should delete the application" do
				Application.should_receive(:find_by_id).with(10, :conditions => {:member_id => 1}).and_return(double(Application))
				Application.should_receive(:delete).with(10)
				get '/application/destroy/10'
				last_response.body.include?('<p class="validation">The application has been deleted with success.</p>')
			end
			
			it "Should delete the application" do
				Application.should_receive(:find_by_id).with(10, :conditions => {:member_id => 1}).and_return(nil)
				get '/application/destroy/10'
				last_response.body.include?('<p class="error">The application you want to delete does not exist.</p>')
			end
		
		end
	
	end

end
