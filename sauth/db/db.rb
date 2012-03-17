config_file = File.join(File.dirname(__FILE__), 'database.yml')
ActiveRecord::Base.establish_connection(YAML.load(File.open(config_file))[ENV['RACK_ENV']])
