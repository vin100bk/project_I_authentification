$: << File.join(File.dirname(__FILE__), '..', '..')

require 'authentification'

describe Application do

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
	
	describe "Check application with missing informations" do
	
		subject do
			a = Application.new
			a.name = ''
			# Url is tested after with the format
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
	
	describe "Check the member applications list" do
	
		it "Should return an empty list" do
			Application.get_applications('toto').empty?.should be_true
		end
		
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
	
	describe "Check method exists?(app_name)" do
	
		it "Should return true for an existing application" do
			Application.should_receive(:find_by_name).with('My_app').and_return(double(Application))
			Application.exists?('My_app').should be_true
		end
		
		it "Should return true for a non existing application" do
			Application.should_receive(:find_by_name).with('My_app').and_return(nil)
			Application.exists?('My_app').should be_false
		end
	
	end

end
