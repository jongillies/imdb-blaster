#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'ostruct'

class OptParse

  def self.parse(name, args)
    @name = name # My script name
    options = OpenStruct.new # Structure to hold the command line options

    options.folder = []
    options.key = []
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

    options.key = args

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

def find_line key, file
  File.open(file) do |f|
    f.grep(/^#{key}/) do |l|
      return l.chomp
    end
  end
end

def find_lines key, file
  results = Array.new
  File.open(file) do |f|
    f.grep(/^#{key}/) do |l|
      results << l.chomp
    end
  end
  return results
end

def get_three_col_data key, file, mode = nil

  lines = find_lines key, file

  values = Array.new

  if lines.count == 0
    $stderr.puts "Unable to locate runtime for key #{key}"
  else
    if lines.count > 1
      $stderr.puts "WARNING: Key is not unique #{key}"
      $stderr.puts lines
    end

    lines.each do |line|
      key, title, data = line.split "\t"
      values << data
    end

  end

  case mode
    when :average
      sum = 0
      values.each { |b| sum += b.to_i }
      $stderr.puts "Averaging values (#{values.join(", ")})."
      return (sum / values.length).to_i
    else
      return values[0]

  end

  return nil

end

# Get command line options
options = OptParse.parse(File::basename($0), ARGV)

folder = options.folder[0]

$stderr.puts "Searching for #{options.key[0]}"

lines = find_lines options.key[0], File.join(folder, "movies.list.txt")

if lines.count == 0
  puts "Unable to locate key #{options.key[0]}"
  exit 1
end

if lines.count > 1
  puts "Key is not unique #{options.key[0]}"
  puts lines
  exit 1
end
data = Hash.new
data['imdb'] = Hash.new
movie = data['imdb']


movie['checksum'], movie['title'], movie['type'], movie['year'], movie['episode_title'], movie['season_number'], movie['episode_number'] = lines[0].split "\t"

movie['runtime'] = get_three_col_data options.key[0], File.join(folder, "running-times.list.txt"), :average
movie['language'] = get_three_col_data options.key[0], File.join(folder, "language.list.txt")
movie['country'] = get_three_col_data options.key[0], File.join(folder, "countries.list.txt")
movie['plot'] = get_three_col_data options.key[0], File.join(folder, "plot.list.txt")

#movie['release_date'] = get_three_col_data options.key[0], File.join(folder,"release-dates.list.txt")
#movie['location'] = get_three_col_data options.key[0], File.join(folder,"locations.list.txt")

puts data.to_yaml

OTHER_FILES="actors.list actresses.list directors.list genres.list mpaa-ratings-reasons.list plot.list"
