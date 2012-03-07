class CreateMembers < ActiveRecord::Migration
	def up
		create_table :members do |t|
			t.string  :login
			t.string  :password
		end
	end

	def down
		drop_table :members
	end
end
