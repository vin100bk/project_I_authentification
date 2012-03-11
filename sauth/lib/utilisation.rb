require 'active_record'

class Utilisation < ActiveRecord::Base
	
	belongs_to :application
	belongs_to :member
	
	validates_uniqueness_of :application_id, :scope => :member_id
	
	def self.get_utilisations(username)
		Utilisation.find_all_by_member_id(Member.find_by_login(username))
	end

end
