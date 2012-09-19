#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'ostruct'

class OptParse

  def self.parse(name, args)
    @name = name # My script name
    options = OpenStruct.new # Structure to hold the command line options

    options.folder = []
    options.search = []
    options.debug = false # Show debug information

    opts = OptionParser.new do |opts|

      opts.banner = "Usage: #{@name} [options]"

      # Debug boolean switch.
      opts.on("-d", "Run in debug mode") do |v|
        options.debug = v
      end

      opts.on("-F folder", Array, "Path to the imdb.list files") do |list|
        options.folder = list
      end

      # No argument, shows at tail. This will print an options
      # summary. Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opts.parse!(args)

    options.search = args

    if options.folder.length == 0
      puts "ERROR: Must include the path to the imdb list files with -F"
      puts opts
      exit 0
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

file_name = File.join options.folder[0], "movies.list.txt"

File.open(file_name) do |f|
  f.grep(/#{options.search[0]}/i) do |l|
    puts l
  end
end