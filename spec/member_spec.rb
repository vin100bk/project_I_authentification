$: << File.join(File.dirname(__FILE__), '..')

require 'authentification'
require 'lib/member'

describe Member do

	describe "Missing informations" do
	
		it "An empty member should not be valid" do
			subject.valid?.should be_false
		end
		
		it "Should not be be valid with no login" do
			subject.valid?
			subject.errors.messages[:login].include?("can't be blank").should be_true
		end
		
		it "Should not be be valid with no password" do
			subject.valid?
			subject.errors.messages[:password].include?("can't be blank").should be_true
		end
		
		it "Should not be be valid with no password confirmation" do
			subject.valid?
			subject.errors.messages[:password_confirmation].include?("can't be blank").should be_true
		end
	
	end
	
	describe "Wrong informations" do
	
		subject do
			m = Member.new
			m.login = "vin%100" 		#% is forbidden
			m.password = "password"
			m
		end
		
		it "Should not be valid with wrong informations" do
			subject.valid?.should be_false
		end
		
		 it "Should not be valid with a wrong login" do
		 	subject.valid?
			subject.errors.messages[:login].include?("is invalid").should be_true
		 end
		 
		 it "Should not be valid with a too short login" do
		 	subject.login = "l"
		 	subject.valid?
			subject.errors.messages[:login].include?("is invalid").should be_true
		 end
	
	end
	
	describe "Check password" do
	
		subject do
			m = Member.new
			m.login = "vin100"
			m
		end
		
		it "Should call the encryption sha1" do
			Digest::SHA1.should_receive(:hexdigest).with("password").and_return("5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8")
			subject.password = "password"
		end
		
		it "Should have the password hash registered" do
			subject.password = "password"
			subject.password.should == "5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8"
		end
		
		it "Should not be valid with a wrong password confirmation" do
			subject.password = "pw1"
			subject.password_confirmation = "pw2"
			subject.valid?.should be_false
		end
		
		it "Should be valid with a right password confirmation" do
			subject.password = "pw1"
			subject.password_confirmation = "pw1"
			subject.valid?.should be_true
		end
	
	end
	
	describe "Member valid" do
		
		subject do
			m = Member.new
			m.login = "my__pseudo--"
			m.password = "pw"
			m.password_confirmation = "pw"
			m
		end
		
		it "Should be valid" do
			subject.valid?.should be_true
		end
		
		it "Should have the default value" do
			subject.is_super_user.should be_false
		end
		
	end

end
