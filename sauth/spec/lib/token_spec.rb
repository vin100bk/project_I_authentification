$: << File.join(File.dirname(__FILE__), '..', '..')

require 'authentification'

describe Token do

	describe "Token::generate" do
		
		it "Should return the right token" do
			Digest::SHA1.should_receive(:hexdigest).and_return('da39a3ee5e6b4b0d3255bfef95601890afd80709')
			Token::generate.should == 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
		end
	
	end

end
