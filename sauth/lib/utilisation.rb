require 'active_record'

class Utilisation < ActiveRecord::Base
	
	belongs_to :application
	belongs_to :member
	
	validates_uniqueness_of :application_id, :scope => :member_id

end
