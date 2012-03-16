$: << File.join(File.dirname(__FILE__), '..', '..')

require 'authentification'

describe Application do

	describe "Check an application valid" do
		
		subject do
			a = Application.new
			a.name = "vin100_to-test"
			a.url = "http://www.google.fr"
			a.member = Member.new
			a
		end
		
		it "Should be valid" do
			subject.valid?.should be_true
		end
		
		it "Should be valid with a https url" do
			subject.url = "https://viveruby.com"
			subject.valid?.should be_true
		end
		
	end

	describe "Check application with missing informations" do
	
		it "An empty application should not be valid" do
			subject.valid?.should be_false
		end
		
		it "Should not be be valid with no name" do
			subject.valid?
			subject.errors.messages[:name].include?("can't be blank").should be_true
		end
		
		it "Should not be be valid with no url" do
			subject.valid?
			subject.errors.messages[:url].include?("can't be blank").should be_true
		end
		
		it "Should not be valid with no member associated" do
			subject.valid?
			subject.errors.messages[:member].include?("can't be blank").should be_true
		end
	
	end
	
	describe "Check application with empty informations" do
	
		subject do
			a = Application.new
			a.name = ''
			a
		end
	
		it "An application with empty informations should not be valid" do
			subject.valid?.should be_false
		end
		
		it "Should not be be valid with an empty name" do
			subject.valid?
			subject.errors.messages[:name].include?("can't be blank").should be_true
		end
	
	end
	
	describe "Check application with wrong informations" do

		subject do
			a = Application.new
			a.name = "titi toto" 		#Blank space is forbidden
			a.url = "www.google.fr"		#http:// is missing
			a.member = Member.new
			a
		end
		
		it "Should not be valid with wrong informations" do
			subject.valid?.should be_false
		end
		
		 it "Should not be valid with a wrong name" do
		 	subject.valid?
			subject.errors.messages[:name].include?("is invalid").should be_true
		 end
		 
		 it "Should not be valid with a too short name" do
		 	subject.name = "t"
		 	subject.valid?
			subject.errors.messages[:name].include?("is invalid").should be_true
		 end
		 
		 it "Should not be valid with a wrong url" do
		 	subject.valid?
			subject.errors.messages[:url].include?("is invalid").should be_true
		 end
	
	end
	
	describe "Check application with no unique name" do
	
		it "Should not be valid with a no unique name" do
			a1 = Application.new
			a1.name = "my_app"
			a1.url = "http://www.google.fr"
			a1.member = Member.new
			
			# Have to save to check uncity
			a1.save!
			
			a2 = Application.new
			a2.name = "my_app"
			a2.url = "http://www.yahoo.fr"
			a2.member = Member.new
			
			a2.valid?
			Application.delete(a1.id)
			a2.errors.messages[:name].include?("has already been taken").should be_true
		end
		
	end
	
	describe "Application::get_applications(app_name)" do
	
		context "Without application" do
			it "Should return an empty list" do
				Application.get_applications('toto').empty?.should be_true
			end
		end
		
		context "With application" do
			it "Should return applications associated to the member" do
				m = Member.new
				m.login = 'User'
				m.password = "pw"
				m.password_confirmation = "pw"
				m.save!
			
				a1 = Application.new
				a1.name = "My_app1"
				a1.url = "http://www.app1.fr"
				a1.member = m
				a1.save!
			
				a2 = Application.new
				a2.name = "My_app2"
				a2.url = "http://www.app2.fr"
				a2.member = m
				a2.save!
			
				Application.get_applications('User').length.should == 2
			
				# Delete records saved
				Member.delete(m.id)
				Application.delete(a1.id)
				Application.delete(a2.id)
			end
		end
	end
	
	describe "Application::delete(app_id)" do
	
		before do
			@m1 = Member.new
			@m1.login = 'User1'
			@m1.password = "pw"
			@m1.password_confirmation = "pw"
			@m1.save!
			
			@m2 = Member.new
			@m2.login = 'User2'
			@m2.password = "pw"
			@m2.password_confirmation = "pw"
			@m2.save!
			
			@a = Application.new
			@a.name = "My_app1"
			@a.url = "http://www.app1.fr"
			@a.member = @m1
			@a.save!
			
			@u1 = Utilisation.new
			@u1.application = @a
			@u1.member = @m1
			@u1.save!
			
			@u2 = Utilisation.new
			@u2.application = @a
			@u2.member = @m2
			@u2.save!
		end
		
		after do
			Member.delete(@m1.id)
			Member.delete(@m2.id)
			Application.delete(@a.id)
			Utilisation.delete(@u1.id)
			Utilisation.delete(@u2.id)
		end
	
		it "Should delete the application" do
			Application.delete(Application.find_by_name('My_app1').id)
			Application.find_by_name('My_app1').should be_nil
		end
		
		it "Should delete the utilisations associated to the application" do
			Application.delete(Application.find_by_name('My_app1').id)
			Utilisation.find_all_by_application_id(Application.find_by_name('My_app1')).should be_empty
		end
	
	end
	
	describe "Application::get_redirect_url(app, origin, user)" do
	
		before do
			@app = Application.new
			@app.stub(:url).and_return('http://www.my_site.com')
			@app.stub(:token).and_return('my_token')
			
			@user = Member.new
			@user.stub(:login).and_return('my_pseudo')
		end
		
		after do
			Utilisation.delete(Utilisation.find_by_application_id_and_member_id(@app.id, @user.id))
		end
	
		it "Should return the private section url of the client application with the right get parameters" do
			Digest::SHA1.should_receive(:hexdigest).with('my_tokenmy_pseudo').and_return('token_to_send_in_parameters')			
			Application.get_redirect_url(@app, '/protected', @user).should == 'http://www.my_site.com/protected?login=my_pseudo&token=token_to_send_in_parameters'
		end
		
		it "Should have an utilisation in database with this application and this member" do
			u = double(Utilisation)
			u.should_receive(:application=).with(@app)
			u.should_receive(:member=).with(@user)
			u.should_receive(:save)
			
			Utilisation.should_receive(:new).and_return(u)
			Application.get_redirect_url(@app, '/protected', @user)
		end
		
		it "Should return '/' with an non existing client application" do
			Application.get_redirect_url(nil, '/protected', @user).should == '/'
		end
	
	end

end
