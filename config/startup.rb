require 'rubygems'
require 'active_record'
require 'yaml'
require 'logger'
require 'pentabarf'
require 'time'

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
  config.logging :level => :debug
  config.enable_asterisk
  voicebarf_cfg = File.open('components/voicebarf/ami.yml') { |f| YAML::load(f) }
  config.asterisk.enable_ami :host     => voicebarf_cfg['ami']['host'],
                             :username => voicebarf_cfg['ami']['username'],
                             :password => voicebarf_cfg['ami']['password'],
                             :events   => true
end
Adhearsion::Initializer.start_from_init_file(__FILE__, File.dirname(__FILE__) + "/..")
