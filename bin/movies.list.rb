#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'digest/sha1'

#require 'ruby-prof'
$line_number = 0 # Global variable

def isNumeric(s)
  Float(s) != nil rescue false
end

class ParseTitle

  # tools/unix/moviedb-3.8/docs/ADDS-GUIDE
  # "xxxxx"        = a television series, e.g. "Twin Peaks" (1990)
  # "xxxxx" (mini) = a television mini-series, e.g. "Lonesome Dove" (1989) (mini) << I can't find a (mini) in the data
  # (TV)           = TV movie, or made for cable movie, e.g. Duel (1971) (TV)
  # (V)            = made for video movie, e.g. Steve Martin Live (1986) (V)

  # Class Variables
  attr_accessor :key, :title, :parts, :type

  def initialize(line, hash)
    @type = :movie

    @parts = line.split "\t"

    @title = parts[0]

    hash == true ? @key = Digest::SHA1.hexdigest(@title) : @key = @title

    if @title.nil? || @title.empty?
      raise "FATAL: Title is nil or empty on line #{$line_number}!"
    end

    if @title.match(/^"/)

      @type = :tv_series
      @title.gsub!("\"", "").strip!

      if @title.match(/\{/)
        @type = :tv_series_episode
      end
    else
      if @title.match(/\(TV\)$/)
        @type = :tv
        @title.gsub!(/\(TV\)$/, "").strip!
      end

      if @title.match(/\(V\)$/)
        @type = :video
        @title.gsub!(/\(V\)$/, "").strip!
      end
    end

  end
end


class OptParse

  def self.parse(name, args)
    @name = name # My script name
    options = OpenStruct.new # Structure to hold the command line options

    options.file = [] # Path to .list file
    options.debug = false # Show debug information
    options.output_hash_as_key = false # Output hash as key instead of name
    options.mode = nil

    opts = OptionParser.new do |opts|

      opts.banner = "Usage: #{@name} [options]"

      # Debug boolean switch.
      opts.on("-d", "Run in debug mode") do |v|
        options.debug = v
      end

      opts.on("-f imdb.list-file", Array, "Path to the imdb.list file") do |list|
        options.file = list
      end

      opts.on("-c", "Output hash as key instead of name") do |v|
        options.output_hash_as_key = v
      end

      # No argument, shows at tail. This will print an options
      # summary. Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opts.parse!(args)

    if options.file.length == 0
      puts "ERROR: Must include the path to the imdb list file with -f"
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

# Profile the code
#RubyProf.start
file_name = options.file[0]
total_lines = open(file_name).read.count("\n")

f = File.open(file_name, 'r')

section = false # Did we find the right section to parse?
parsing = false # Real data now available

object_name = String.new

while line = f.gets
  line.chomp!
  $line_number += 1

  $stderr.puts "#{file_name} at line #{$line_number}/#{total_lines}" if ($line_number % 10000) == 0 || $line_number == total_lines

  # CRC: 0xC0B50136  File: taglines.list  Date: Thu Dec 16 16:00:00 2010
  if $line_number.eql? 1

    if line.match(/^CRC: /)

      junk, crc_in_hex, the_rest = line.split " ", 3
      crc = crc_in_hex.hex

      if crc <= 0
        puts "FATAL: CRC converts to 0 (crc_in_hex)"
        exit 1
      end

      junk, filename, the_rest = the_rest.split " ", 3

      if filename != "movies.list"
        puts "FATAL: This utility only parses the movies.list file"
        exit 1
      end
      junk, date = the_rest.split " ", 2
      begin
        date = Date.parse date
      rescue ArgumentError
        puts "FATAL: Invalid date one line 1 (#{date})"
        exit 1
      end

      object_name = filename.gsub(".list", "")

      #puts "#{filename}\t#{crc}\t#{date}"

    else
      puts "FATAL: Line 1 does not begin with CRC:"
      exit 1
    end
    next
  end

  if !section && line.match(/MOVIES LIST/)
    section = true
    next
  end

  if section
    if !parsing
      # Ignore the lines before the data starts
      next if line.match(/^=/)
      next if line.strip.empty?
      parsing = true
    end
  end

  if parsing

    next if line.match(/^-/) # The very last line is filled with -'s

    entry = ParseTitle.new(line, options.output_hash_as_key)

    season_number = 0
    episode_number = 0
    run_dates = ""
    episode_title = ""

    # The year should be the last parameter
    year = entry.parts[entry.parts.count - 1]

    if year.match(/\(/)
      # This looks like a comment, it begins with a (
      # Although, some a-holes will add a year like this: (2004) so we won't get that line
      year = entry.parts[entry.parts.count - 2]
      comment = entry.parts[entry.parts.count - 1]
    end

    year.gsub!(/-.*/, "") # Some years look like 2005-????
    year.gsub!(/<\/?[^>]*>/, "") # Remove any HTML tags that my be there

    if year.strip.empty?
      #$stderr.puts "WARNING: Year value is empty #{$line_number}"
    end

    if !isNumeric(year)
      #$stderr.puts "WARNING: Year value is not numeric #{$line_number}"
      year = 0
    end

    last_on_line = entry.parts[entry.parts.count-1]

    if entry.type == :tv_series

      run_dates = entry.parts[entry.parts.count-1]

      if run_dates.match(/\(/)
        # This looks like a comment, it begins with a (
        run_dates = entry.parts[entry.parts.count - 2]
        comment = entry.parts[entry.parts.count - 1]
      end

      x = run_dates.split "-", 2
      year = x[0]

    elsif entry.type == :tv_series_episode
      begin

        # Split the title on the {, left is the show name, right is the episode name and season/episode
        x = entry.title.split "{", 2
        entry.title = x[0]

        # Reverse the string and take the last set of ()'s
        y = x[1].reverse.split("#(", 2)

        # Retrieve the season.episode and reverse it back
        season_dot_episode = y[0].gsub("})", "").reverse

        # Retrieve the episode title and reverse it back
        episode_title = y[1].reverse
        season_number, episode_number = season_dot_episode.split "."
      rescue
        # Some entries have ????? for the season.episode
        # Some entries are missing a year an the above code will fail
        #raise "WARNING: Year value is not numeric #{$line_number}"

        season_number = 0
        episode_number = 0
      end

    end

    if entry.type == :movie || entry.type == :tv || entry.type == :video

      # Process Movies, Videos and TV Movies
      type = "1"

    elsif entry.type == :tv_series

      # Process TV Series
      type = "2"

    elsif entry.type == :tv_series_episode

      # Process TV Series Episodes
      type = "3"
    end
    #     1              2               3        4        5                 6                 7
    puts "#{entry.key}\t#{entry.title}\t#{type}\t#{year}\t#{episode_title}\t#{season_number}\t#{episode_number}"

  end
end

#result = RubyProf.stop
#printer = RubyProf::FlatPrinter.new(result)
#printer.print(STDOUT, 0)
