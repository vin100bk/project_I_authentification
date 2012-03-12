require 'active_record'

class Application < ActiveRecord::Base

	has_many :utilisations
	has_many :members, :through => :utilisations
	belongs_to :member
	
	# Validators
	# Name
	validates :name, :presence => true
	validates :name, :uniqueness => true
	validates :name, :format => { :with => /^[a-z0-9_-]{2,}$/i, :on => :create }
	
	# Url
	validates :url, :presence => true
	validates :url, :format => { :with => /^https?:\/\/[a-z0-9._\/-]+/i, :on => :create }
	
	# Manager_id
	validates :member, :presence => true
	
	def name=(name)
		unless name.empty?
			self[:name] = name
		end
	end
	
	def self.get_applications(username)
		Application.find_all_by_member_id(Member.find_by_login(username))
	end
	
	def self.delete(app_id)
		super(app_id)
		Utilisation.delete_all 'application_id = ' + app_id.to_s
	end
	
	def self.exists?(app_name)
		!Application.find_by_name(app_name).nil?
	end

end
