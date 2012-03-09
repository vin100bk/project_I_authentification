$: << File.join(File.dirname(__FILE__), '..')

require 'authentification'
require 'rack/test'

enable :sessions

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
		
	end
	
	describe "Check authentification" do
	
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
			last_response.body.include?('Le compte avec l\'identifiant').should be_true
		end
		
		it "Session should exists but with a wrong password" do
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('14ca9f63103e4c9ac356797bb6d1c76a51e91071')	# Value : My_password
			
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(m)
			
			post '/session/new', @params
			last_response.body.include?('Le mot de passe ne correspond pas &agrave; l\'identifiant').should be_true
		end
		
		it "Should authenticate with success" do
			Member.should_receive(:find_by_login).at_least(1).with('Vin100').and_return(@m)
			post '/session/new', @params
			
			# If redirect : authentification sucessful
			myFile = File.open("test.html", "w")
			myFile.write (last_response.body)
			myFile.close

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
	
	end
	
	describe "Check registration" do
		
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

end
