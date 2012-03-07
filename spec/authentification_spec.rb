$: << File.join(File.dirname(__FILE__), '..')

require 'authentification'
require 'rack/test'

enable :sessions

describe 'The Authentification App' do

	include Rack::Test::Methods

	def app
		Sinatra::Application
	end
	
	describe "Available get pages" do

		it "Index" do
			get '/'
			last_response.should be_ok
		end 
		
		it "Register form" do
			get '/register'
			last_response.should be_ok
		end
		
		it "Connexion form" do
			get '/session'
			last_response.should be_ok
		end
		
	end
	
	describe "Authentification" do
	
		before(:each) do
			@params = {
				'login' => 'Vin100',
				'password' => 'Password'
			}
		end
	
		it "Should call authenticate method" do
			Member.should_receive(:authenticate).with('Vin100', 'Password').and_return(false)
			post '/session/new', @params
		end
		
		it "Should not authenticate with success" do
			post '/session/new', @params
			last_response.should be_ok
		end
		
		it "Session should not exists" do
			post '/session/new', @params
			last_response.body.include?('Le compte avec l\'identifiant').should be_true
		end
		
		it "Session should exists but with a wrong password" do
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('14ca9f63103e4c9ac356797bb6d1c76a51e91071')	# Value : My_password
			
			Member.stub(:find_by_login).with('Vin100').and_return(m)
			
			post '/session/new', @params
			last_response.body.include?('Le mot de passe ne correspond pas &agrave; l\'identifiant').should be_true
		end
		
		it "Should authenticate with success" do
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')
			
			Member.stub(:find_by_login).with('Vin100').and_return(m)
			post '/session/new', @params
			
			# If redirect : authentification sucessful
			last_response.should be_redirect
			follow_redirect!
		end
		
		it "Should register the login into session with a successful authentification" do
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')
			
			Member.stub(:find_by_login).with('Vin100').and_return(m)
			post '/session/new', @params
			
			follow_redirect!
			last_request.env['rack.session']['current_user'].should == 'Vin100'
		end
	
	end
	
	describe "Registration" do
		
		before(:each) do
			@params = {
				'login' => 'Vin100',
				'password' => 'Password'
			}
		end
	
		it "Should call authenticate method" do
			Member.should_receive(:authenticate).with('Vin100', 'Password').and_return(false)
			post '/session/new', @params
		end
		
		it "Should not authenticate with success" do
			post '/session/new', @params
			last_response.should be_ok
		end
		
		it "Session should not exists" do
			post '/session/new', @params
			last_response.body.include?('Le compte avec l\'identifiant').should be_true
		end
		
		it "Session should exists but with a wrong password" do
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('14ca9f63103e4c9ac356797bb6d1c76a51e91071')	# Value : My_password
			
			Member.stub(:find_by_login).with('Vin100').and_return(m)
			
			post '/session/new', @params
			last_response.body.include?('Le mot de passe ne correspond pas &agrave; l\'identifiant').should be_true
		end
		
		it "Should authenticate with success" do
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')
			
			Member.stub(:find_by_login).with('Vin100').and_return(m)
			post '/session/new', @params
			
			# If redirect : authentification sucessful
			last_response.should be_redirect
			follow_redirect!
		end
		
		it "Should register the login into session with a successful authentification" do
			m = double(Member)
			m.stub(:login).and_return('Vin100')
			m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')
			
			Member.stub(:find_by_login).with('Vin100').and_return(m)
			post '/session/new', @params
			
			follow_redirect!
			last_request.env['rack.session']['current_user'].should == 'Vin100'
		end
		
	end

end
