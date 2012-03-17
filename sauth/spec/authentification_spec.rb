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
		
		it "Should authenticate with success" do
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
			post '/sessions', @params
			
			# If redirect : authentification sucessful
			last_response.should be_redirect
			follow_redirect!
			last_request.path.should == '/'
		end
		
		it "Should register the login into session with a successful authentification" do
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
			post '/sessions', @params
			
			follow_redirect!
			last_request.env['rack.session']['current_user'].should == 'Vin100'
		end
		
		it "Should register a token into a cookie after a successful authentification" do
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
			Token.should_receive(:generate).and_return('random_token')
			post '/sessions', @params
			
			follow_redirect!
			last_request.cookies['token'].nil?.should be_false
			last_request.cookies['token'].should == 'random_token'
		end
	
		it "Should call authenticate method" do
			Member.should_receive(:authenticate?).at_least(1).with('Vin100', 'Password')
			post '/sessions', @params
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
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('14ca9f63103e4c9ac356797bb6d1c76a51e91071')	# Value : My_password
			
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(m)
			
			post '/sessions', @params
			last_response.body.include?('The password does not match with the username').should be_true
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
				
					Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
				end
			
				it "Should be redirected to the origin url" do
					post '/App_name/sessions', @params
					last_response.should be_redirect
					follow_redirect!
					last_request.path.should == @params['origin']
				end
				
				it "Should have to login in get parameters" do
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
					post '/App_name/sessions', @params
					last_response.should be_redirect
					follow_redirect!
					last_response.body.include?('<p class="error">The application which you want to access does not exist.</p>').should be_true
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
			post '/members', @params
			
			follow_redirect!
			last_request.env['rack.session']['current_user'].should == 'Vin100'
		end
		
		it "Should register a token into a cookie after a successful registration" do
			Token.should_receive(:generate).and_return('random_token')
			post '/members', @params
			
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
			m = Member.new
			m.stub(:id).and_return(1)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')
			m.stub(:token=)
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(m)
			post '/sessions', params
			follow_redirect!
		end
		
		describe "get '/sessions/logout'" do
			
			it "Should not have session and cookie after logout" do
				get '/sessions/logout'
				last_response.should be_redirect
				follow_redirect!
				last_request.path.should == '/'
				last_request.env['rack.session']['current_user'].should be_nil
				last_request.cookies['token'].should be_nil
			end
			
		end
		
		describe "get '/sessions/destroy'" do
		
			it "Should delete the account of the current user" do
				Member.should_receive(:delete).with(1)
				get '/sessions/destroy'
				last_response.should be_redirect
				follow_redirect!
				last_request.path.should == '/'
				last_request.env['rack.session']['current_user'].should be_nil
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
				get '/applications/new'
				last_response.should be_ok
			end
			
			it "Should add the application with success" do
				a = Application.new
				a.member = Member.new
				a.stub(:member=).and_return(Member.new)
				Application.should_receive(:new).and_return(a)
			
				post '/applications', @params
				last_response.should be_redirect
			end
			
			it "Should not add the application with success (ugly name). Other tests available for validators in application_spec.rb" do
				@params['name'] = 'my cute application'
			
				a = Application.new
				a.member = Member.new
				a.stub(:member=).and_return(Member.new)
				Application.should_receive(:new).and_return(a)
			
				post '/applications', @params
				last_response.should be_ok	# If there is not redirection, error while adding
			end
			
		end
		
		describe "get '/applications/destroy/10'" do
		
			it "Should delete the application" do
				Application.should_receive(:find_by_id).with(10, :conditions => {:member_id => 1}).and_return(double(Application))
				Application.should_receive(:delete).with(10)
				get '/applications/destroy/10'
				last_response.body.include?('<p class="validation">The application has been deleted with success.</p>')
			end
			
			it "Should not delete a non existing application" do
				Application.should_receive(:find_by_id).with(10, :conditions => {:member_id => 1}).and_return(nil)
				get '/applications/destroy/10'
				last_response.body.include?('<p class="error">The application you want to delete does not exist.</p>')
			end
		
		end
	
	end

end
