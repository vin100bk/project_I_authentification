ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'authentification'

module Spec_methods

	def before
		Application.destroy_all
		Member.destroy_all
		Utilisation.destroy_all
		
		@sessions = {}
	end
	
end

