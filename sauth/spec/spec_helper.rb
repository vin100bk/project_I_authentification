ENV['RACK_ENV'] = 'test'

require 'authentification'
require 'rack/test'

module Spec_methods

	def before
		Application.destroy_all
		Member.destroy_all
		Utilisation.destroy_all
	end
	
end

