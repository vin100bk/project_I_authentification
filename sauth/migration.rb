$: << File.dirname(__FILE__)

require 'active_record'

databases = YAML.load_file('db/database.yml')
databases.each do |db_name, db_config|
	ENV['RACK_ENV'] = db_name
	
	load 'db/db.rb'	# Must use load instead of require : need to reload this file
	ActiveRecord::Migration.verbose = true
	ActiveRecord::Migrator.migrate "db/migrate"
end

