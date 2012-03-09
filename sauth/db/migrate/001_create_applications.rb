class CreateApplications < ActiveRecord::Migration
	def up
		create_table :applications do |t|
			t.string	:name
			t.string	:url
			t.integer	:member_id
		end
	end

	def down
		drop_table :applications
	end
end
