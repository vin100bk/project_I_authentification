class Member < ActiveRecord::Base

	has_many :utilisations
	has_many :applications, :through => :utilisations
	
	# Validators
	# Login
	validates :login, :presence => true
	validates :login, :uniqueness => true
	validates :login, :format => { :with => /[a-z0-9_-]{2,}/i, :on => :create }
	
	# Password
	validates :password, :confirmation => true

end
