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
	validates :url, :format => { :with => /^https?:\/\/[a-z0-9._\/-]+\.[a-z]{2,3}/i, :on => :create }
	
	# Manager_id
	validates :member, :presence => true

end
