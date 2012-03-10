class CreateUtilisations < ActiveRecord::Migration
	
	def up
		create_table :utilisations do |t|
			t.integer  :application_id
			t.integer  :member_id
		end
	end

	def down
		drop_table :utilisations
	end
end
