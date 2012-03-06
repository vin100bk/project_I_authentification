$: << File.join(File.dirname(__FILE__), '..')

require 'authentification'
require 'lib/application'
require 'lib/member'

describe Application do

	describe "Missing informations" do
	
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
	
	describe "Wrong informations" do
	
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
	
	describe "Check unicity informations" do
	
		it "Should not be valid with a no unique login" do
			a1 = Application.new
			a1.name = "my_app"
			a1.url = "http://www.google.fr"
			a1.member = Member.new
			
			# Have to save to check uncity
			app_id = a1.save
			
			a2 = Application.new
			a2.name = "my_app"
			a2.url = "http://www.yahoo.fr"
			a2.member = Member.new
			
			a1.valid?
			Application.delete(app_id)
			a1.errors.messages[:name].include?("has already been taken").should be_true
		end
		
	end
	
	describe "Application valid" do
		
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

end
