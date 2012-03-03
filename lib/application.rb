class Application < ActiveRecord::Base

	has_many :utilisations
	has_many :members, :through => :utilisations
	
	# Validators
	# Name
	validates :name, :presence => true
	validates :name, :uniqueness => true
	validates :name, :format => { :with => /[a-z0-9_-]{2,}/i, :on => :create }
	
	# Url
	validates :url, :presence => true
	validates :url, :format => { :with => /^http\\:\/\/[a-z0-9._\/-]+\.[a-z]{2,3}/i, :on => :create }

end
