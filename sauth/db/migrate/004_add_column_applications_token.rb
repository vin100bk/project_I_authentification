class AddColumnApplicationsToken < ActiveRecord::Migration
	def up
		add_column :applications, :token, :string
	end

	def down
		remove_column :applications, :token
	end
end
