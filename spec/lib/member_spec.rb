$: << File.join(File.dirname(__FILE__), '..', '..')

require 'authentification'
require 'lib/member'

describe Member do

	describe "Check a member with missing informations" do
	
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
	
	end
	
	describe "Chech member with empty informations" do
	
		subject do
			m = Member.new
			m.login = ''
			m.password = ''
			m.password_confirmation = ''
			m
		end
	
		it "A member with empty information should not be valid" do
			subject.valid?.should be_false
		end
		
		it "Should not be be valid with an empty login" do
			subject.valid?
			subject.errors.messages[:login].include?("can't be blank").should be_true
		end
		
		it "Should not be be valid with an empty password" do
			subject.valid?
			subject.errors.messages[:password].include?("can't be blank").should be_true
		end
	
	end
	
	describe "Check member with wrong informations (format no valid)" do
	
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
	
	describe "Check member with no unique login" do
	
		it "Should not be valid with a no unique login" do
			m1 = Member.new
			m1.login = "pseudo"
			m1.password = "pw"
			m1.password_confirmation = "pw"
			
			# Have to save to check uncity
			m1.save!
			user_id = m1.id
			
			m1 = Member.new
			m1.login = "pseudo"
			m1.password = "pw"
			m1.password_confirmation = "pw"
			
			m1.valid?
			Member.delete(user_id)
			m1.errors.messages[:login].include?("has already been taken").should be_true
		end
	
	end
	
	describe "Check password" do
	
		subject do
			m = Member.new
			m.login = "vin100"
			m
		end
		
		it "Should return the rigth hash" do
			Member.encrypt_password('password') == Digest::SHA1.hexdigest('password')
		end
		
		it "Should call the encryption sha1" do
			Digest::SHA1.should_receive(:hexdigest).with("password").and_return('5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8')
			subject.password = "password"
			subject.password.should == '5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8'
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
	
	describe "Check authentication" do
	
		before do
			@m = double(Member)
			@m.stub(:login).and_return('Vin100')
			@m.stub(:password).and_return('8be3c943b1609fffbfc51aad666d0a04adf83c9d')	# Password
		end
	
		it "Should not authenticate with success" do
			Member.stub(:find_by_login).with('Vin100').and_return(@m)
			Member.authenticate('Vin100', 'password').should be_false
		end
		
		it "Should authenticate with success" do
			Member.stub(:find_by_login).with('Vin100').and_return(@m)
			Member.authenticate('Vin100', 'Password').should be_true
		end
	
	end
	
	describe "Check a member valid" do
		
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
		
	end

end
