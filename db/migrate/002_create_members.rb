class CreateMembers < ActiveRecord::Migration
	def up
		create_table :members do |t|
			t.string  :login
			t.string  :password
			t.boolean  :is_super_user
		end
	end

	def down
		drop_table :members
	end
end
