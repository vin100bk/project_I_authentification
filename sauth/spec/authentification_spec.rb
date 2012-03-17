$: << File.join(File.dirname(__FILE__), '..')

require 'spec/spec_helper'

describe 'The Authentification App' do

	include Rack::Test::Methods
	include Spec_methods

	def app
		Sinatra::Application
	end
	
	before do
		before
	end
	
	describe "Check available get pages" do

		it "Index" do
			get '/'
			last_response.should be_ok
		end 
		
		it "Register form" do
			get '/members/new'
			last_response.should be_ok
		end
		
		it "Connexion form" do
			get '/sessions/new'
			last_response.should be_ok
		end
		
		it "Registration application form" do
			get '/applications/new'
			last_response.should be_redirect
		end
		
		it "Connexion form should be redirected with a non existing application" do
			get '/Test/sessions/new'
			last_response.should be_redirect
			follow_redirect!
			last_request.path.should == '/'
		end
		
		it "Connexion form should be displayed with an existing application" do
			Application.should_receive(:find_by_name).with('Test').and_return(double(Application))
			get '/Test/sessions/new'
			last_response.should be_ok
		end
		
	end
	
	describe "post '/sessions'" do
	
		before do
			@params = {
				'login' => 'Vin100',
				'password' => 'Password'
			}
			
			@m = Member.new
			@m.stub(:login).and_return('Vin100')
			@m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')
			@m.stub(:token=).and_return('random_token')
		end
		
		context "With right authentification information" do
		
			before do
				Member.should_receive(:authenticate).with('Vin100', 'Password').and_return(@m)
			end
		
			it "Should authenticate with success" do
				post '/sessions', @params
			
				# If redirect : authentification sucessful
				last_response.should be_redirect
				follow_redirect!
				last_request.path.should == '/'
			end
		
			it "Should register the login into session" do
				post '/sessions', @params, 'rack.session' => @sessions
				follow_redirect!
				@sessions[:current_user].should == 'Vin100'
			end
		
			it "Should register a token into a cookie" do
				Token.should_receive(:generate).at_least(1).and_return('random_token')
				post '/sessions', @params, 'rack.session' => @sessions
			
				follow_redirect!
				last_request.cookies['token'].nil?.should be_false
				last_request.cookies['token'].should == 'random_token'
			end
			
		end
		
		context "With wrong authentification information" do
		
			before do
				Member.should_receive(:authenticate).with('Vin100', 'Password').and_return(nil)
			end
		
			it "Should not authenticate with success" do
				post '/sessions', @params
				last_response.should be_ok	# If there is not redirection, authenticate failed
			end
		
			it "Session should not exists" do
				post '/sessions', @params
				last_response.body.include?('The account with the username').should be_true
			end
		
			it "Session should exists but with a wrong password" do
				Member.should_receive(:find_by_login).with('Vin100').and_return(double(Member))
			
				post '/sessions', @params
				last_response.body.include?('The password does not match with the username').should be_true
			end
			
		end
		
		describe "post '/App_name/sessions' (with an client application)" do
		
			before do
				@app = Application.new
				@app.stub(:url).and_return('http://www.google.fr')
				@app.stub(:token).and_return('random_token')
				
				@params['origin'] = '/protected'
			end
			
			context "With an existing client application" do
				
				before do
					Application.should_receive(:find_by_name).with('App_name').and_return(@app)
					Member.should_receive(:authenticate).with('Vin100', 'Password').and_return(@m)
				end
				
				it "Should have login in get parameters" do
					post '/App_name/sessions', @params
					
					last_response.should be_redirect
					follow_redirect!
					last_request.params['login'].should == @params['login']
				end
				
				it "Should have the right token in get parameters" do
					post '/App_name/sessions', @params

					last_response.should be_redirect
					follow_redirect!
					last_request.params['token'].should == Digest::SHA1.hexdigest('random_tokenVin100')
				end
				
				it "Should be redirected to the origin url" do
					post '/App_name/sessions', @params
					last_response.should be_redirect
					follow_redirect!
					last_request.url.should == 'http://www.google.fr/protected?login=Vin100&token=' + Digest::SHA1.hexdigest('random_tokenVin100')
					last_request.path.should == '/protected'
				end
				
			end
			
			context "With a non existing client application" do
				
				before do
					Application.should_receive(:find_by_name).with('App_name').and_return(nil)
				end
			
				it "Should be redirected to '/'" do
					post '/App_name/sessions', @params
					last_response.should be_redirect
					follow_redirect!
					last_request.path.should == '/'
				end
				
				it "Should display an error message" do
					post '/App_name/sessions', @params, 'rack.session' => @sessions
					last_response.should be_redirect
					follow_redirect!
					@sessions[:flash].should == '<p class="error">The application which you want to access does not exist.</p>'
				end
				
			end
			
		end
	
	end
	
	describe "post '/members'" do
		
		before(:each) do
			@params = {
				'login' => 'Vin100',
				'password' => 'Password',
				'password_confirmation' => 'Password'
			}
		end
		
		it "Should register with success" do
			post '/members', @params
			
			# If redirect : authentification sucessful
			last_response.should be_redirect
			follow_redirect!
			last_request.path.should == '/'
		end
		
		it "Should register the login into session with a successful registration" do
			post '/members', @params, 'rack.session' => @sessions
			
			follow_redirect!
			@sessions[:current_user].should == 'Vin100'
		end
		
		it "Should register a token into a cookie after a successful registration" do
			Token.should_receive(:generate).at_least(1).and_return('random_token')
			post '/members', @params, 'rack.session' => @sessions
			
			follow_redirect!
			last_request.cookies['token'].nil?.should be_false
			last_request.cookies['token'].should == 'random_token'
		end
		
		it "Should not register with success (ugly login). Other tests available for validators in member_spec.rb" do
			@params['login'] = 'vin@@100'
			
			post '/members', @params
			last_response.should be_ok	# If there is not redirection, error while registring
		end
		
	end
	
	describe "Check login by cookie" do
	
		before do
			clear_cookies
		end
	
		it "Should be connected with a cookie" do
			# Set cookie
			set_cookie 'token=random_token'
			
			m = Member.new
			m.stub(:login).and_return('Name')
			
			Member.should_receive(:find_by_token).with('random_token').and_return(m)
			Token.should_receive(:generate).and_return('other_token')
			
			get '/', {}, 'rack.session' => @sessions
			last_request.cookies['token'].should == 'random_token'
			@sessions[:current_user].should == 'Name'
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
			@sessions[:current_user] = 'Vin100'
			@current_user = Member.new
			@current_user.stub(:id).and_return(1)
		end
		
		describe "get '/sessions/logout'" do
			
			it "Should not have session and cookie after logout" do
				get '/sessions/logout', {}, 'rack.session' => @sessions
				last_response.should be_redirect
				follow_redirect!
				last_request.path.should == '/'
				@sessions[:current_user].should be_nil
				last_request.cookies['token'].should be_nil
			end
			
		end
		
		describe "get '/sessions/destroy'" do
		
			it "Should delete the account of the current user" do
				Member.should_receive(:find_by_login).with('Vin100').and_return(@current_user)
				Member.should_receive(:delete).with(1)
				get '/sessions/destroy', {}, 'rack.session' => @sessions
				last_response.should be_redirect
				follow_redirect!
				last_request.path.should == '/'
				@sessions[:current_user].should be_nil
				last_request.cookies['token'].should be_nil
			end
		
		end
		
		describe "post '/applications'" do
		
			before do
				@params = {
					'name' => 'App1',
					'url' => 'http://www.app1.com'
				}
			end
		
			it "Registration application form" do
				get '/applications/new', {}, 'rack.session' => @sessions
				last_response.should be_ok
			end
			
			it "Should add the application with success" do
				Member.should_receive(:find_by_login).with('Vin100').and_return(@current_user)
				post '/applications', @params, 'rack.session' => @sessions
				last_response.should be_redirect
			end
			
			it "Should not add the application with success (ugly name). Other tests available for validators in application_spec.rb" do
				@params['name'] = 'my cute application'
			
				a = Application.new
				a.member = Member.new
				a.stub(:member=).and_return(Member.new)
				Application.should_receive(:new).and_return(a)
			
				post '/applications', @params, 'rack.session' => @sessions
				last_response.should be_ok	# If there is not redirection, error while adding
			end
			
		end
		
		describe "get '/applications/destroy/10'" do
		
			before do
				Member.should_receive(:find_by_login).with('Vin100').and_return(@current_user)
			end
		
			it "Should delete the application" do
				Application.should_receive(:find_by_id).with(10, :conditions => {:member_id => 1}).and_return(double(Application))
				Application.should_receive(:delete).with(10)
				get '/applications/destroy/10', {}, 'rack.session' => @sessions
				last_response.body.include?('<p class="validation">The application has been deleted with success.</p>')
			end
			
			it "Should not delete a non existing application" do
				Application.should_receive(:find_by_id).with(10, :conditions => {:member_id => 1}).and_return(nil)
				get '/applications/destroy/10', {}, 'rack.session' => @sessions
				last_response.body.include?('<p class="error">The application you want to delete does not exist.</p>')
			end
		
		end
	
	end

end
