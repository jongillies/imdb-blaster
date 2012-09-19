#!/usr/bin/env ruby

#<COMMENT>
# This script returns database parameters from config/database.yml for use in bash scripts
# STATUS: utility
# USED: command-line, webtools
#</COMMENT>


require 'rubygems'
require 'mysql'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'yaml'

class OptParse

  def self.parse(name, args)
    @name = name
    options = OpenStruct.new
    options.key = ""
    options.debug = false
    options.testing = false
    options.verbose = false

    opts = OptionParser.new do |opts|

      opts.banner = "Usage: #{@name} [options] -k key"

      # Boolean switch.
      opts.on("-v", "Run verbosely") do |v|
        options.verbose = v
      end

      # Boolean switch.
      opts.on("-d", "Run in debug mode") do |v|
        options.debug = v
      end

      # Key
      opts.on("-k key", Array, "Specify the key to retrieve (database,host,port,user,password)") do |list|
        options.key = list
      end

      # No argument, shows at tail. This will print an options
      # summary. Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opts.parse!(args)

    if options.key.length < 1
      puts "You must specify a key to retrieve."
      puts opts
      exit
    end

    options

  end

  # PARSE

  def help
    opts.help
  end

end # class OptParse

# Get command line options
options = OptParse.parse(File::basename($0), ARGV)

file_handle = YAML.load(File.new(File.expand_path(File.dirname(__FILE__)) + "/config/database.yml"))
config = file_handle.each { |value| value.inspect }

if ENV['RAILS_ENV'] == nil || ENV['RAILS_ENV'] == ''
  tier = 'production'
else
  tier = ENV['RAILS_ENV']
end

puts config[tier][options.key[0]]
