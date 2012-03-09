require 'digest/sha1'

class Token

	def self.generate
		Digest::SHA1.hexdigest(rand(2**32).to_s).inspect[1..40]	# Debug
	end

end
