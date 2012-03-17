$: << File.join(File.dirname(__FILE__), '..', '..')

require_relative '../spec_helper'

describe Utilisation do

	include Spec_methods
	
	before do
		before
	end

	describe "Utilisation::get_utilisations(username)" do
	
		context "Without utilisations" do
			it "Should return an empty list" do
				Utilisation.get_utilisations('toto').empty?.should be_true
			end
		end
		
		context "With utilisations" do
			it "Should return utlisations associated to the member" do
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
			
				u1 = Utilisation.new
				u1.application = a1
				u1.member = m
				u1.save!
			
				u2 = Utilisation.new
				u2.application = a2
				u2.member = m
				u2.save!
			
				Utilisation.get_utilisations('User').length.should == 2
			end
		end	
	end

end
