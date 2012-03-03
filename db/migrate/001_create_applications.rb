class CreateApplications < ActiveRecord::Migration
	def up
		create_table :applications do |t|
			t.string  :name
			t.string  :url
		end
	end

	def down
		drop_table :applications
	end
end
