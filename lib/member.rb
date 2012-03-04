require 'digest/sha1'

class Member < ActiveRecord::Base

	has_many :utilisations
	has_many :applications, :through => :utilisations
	
	# Validators
	# Login
	validates :login, :presence => true
	validates :login, :uniqueness => true
	validates :login, :format => { :with => /^[a-z0-9_-]{2,}$/i, :on => :create }
	
	# Password
	validates :password, :presence => true
	validates :password, :confirmation => true
	
	validates :password_confirmation, :presence => true
	
	# Redefine password and password_confirmation because of sha1 encryption
	def password=(password)
		@password = Digest::SHA1.hexdigest(password);
	end
	
	def password
		@password
	end
	
	def password_confirmation=(password)
		@password_confirmation = Digest::SHA1.hexdigest(password);
	end
	
	def password_confirmation
		@password_confirmation
	end

end
