require_relative 'authentification'

ActiveRecord::Migration.verbose = true
ActiveRecord::Migrator.migrate "db/migrate"

