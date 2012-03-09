require 'digest/sha1'
require 'active_record'

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
	
	def login=(login)
		unless login.empty?
			self[:login] = login
		end
	end
	
	# Redefine password and password_confirmation because of sha1 encryption
	def password=(password)
		unless password.empty?
			self[:password] = Member.encrypt_password(password)
		end
	end
	
	def password_confirmation=(password)
		unless password.empty?
			@password_confirmation = Member.encrypt_password(password)
		end
	end
	
	def password_confirmation
		@password_confirmation
	end
	
	def self.encrypt_password(password)
		Digest::SHA1.hexdigest(password).inspect[1..40]
	end
	
	def self.authenticate(login, password)
		m = Member.find_by_login(login)
		!m.nil? && m.password == Member.encrypt_password(password)
	end

end
