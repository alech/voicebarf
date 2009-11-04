require 'rubygems'
require 'active_record'
require 'yaml'
require 'logger'

unless defined? Adhearsion
  if File.exists? File.dirname(__FILE__) + "/../adhearsion/lib/adhearsion.rb"
    require File.dirname(__FILE__) + "/../adhearsion/lib/adhearsion.rb"
  else  
    require 'rubygems'
    gem 'adhearsion', '>= 0.7.999'
    require 'adhearsion'
  end
end

Adhearsion::Configuration.configure do |config|
  config.logging :level => :info
  config.enable_asterisk
end

Adhearsion::Initializer.start_from_init_file(__FILE__, File.dirname(__FILE__) + "/..")
db_config = File.open('database.cfg') { |f| YAML::load(f) }

ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Base.logger = Logger.new(STDERR)

class Reminder < ActiveRecord::Base
end
