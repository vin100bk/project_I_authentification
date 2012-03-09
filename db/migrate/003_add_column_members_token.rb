class AddColumnMembersToken < ActiveRecord::Migration
	def up
		add_column :members, :token, :string
	end

	def down
		remove_column :members, :token
	end
end
