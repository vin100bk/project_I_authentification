require_relative 'authentification'

ActiveRecord::Migration.verbose = true
ActiveRecord::Migrator.migrate "db/migrate"

# sqlite3 db/devlopment.sqlite3
#
# .databases
# .tables
# .schema
# select * from schema_migrations
