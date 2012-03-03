class Utilisation < ActiveRecord::Base

	belongs_to :application
	belongs_to :member

end
