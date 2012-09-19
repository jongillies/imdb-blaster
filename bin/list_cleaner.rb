#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'digest/sha1'

$line_number = 0 # Global variable for line number

# Global variable for identifying the start of data in the list
$start = Hash.new
$start['actors.list'] = "THE ACTORS LIST"
$start['actresses.list'] = "THE ACTRESSES LIST"
$start['aka-names.list'] = "AKA NAMES LIST"
$start['aka-titles.list'] = "AKA TITLES LIST"
$start['alternate-versions.list'] = "ALTERNATE VERSIONS LIST"
$start['biographies.list'] = "BIOGRAPHY LIST"
$start['business.list'] = "BUSINESS LIST"
$start['certificates.list'] = "CERTIFICATES LIST"
$start['cinematographers.list'] = "THE CINEMATOGRAPHERS LIST"
$start['color-info.list'] = "COLOR INFO LIST"
$start['complete-cast.list'] = "CAST COVERAGE TRACKING LIST"
$start['complete-crew.list'] = "CREW COVERAGE TRACKING LIST"
$start['composers.list'] = "THE COMPOSERS LIST"
$start['costume-designers.list'] = "THE COSTUME DESIGNERS LIST"
$start['countries.list'] = "COUNTRIES LIST"
$start['crazy-credits.list'] = "CRAZY CREDITS"
$start['directors.list'] = "THE DIRECTORS LIST"
$start['distributors.list'] = "DISTRIBUTORS LIST"
$start['editors.list'] = "THE EDITORS LIST"
$start['genres.list'] = "THE GENRES LIST"
$start['german-aka-titles.lis'] = "AKA TITLES LIST GERMAN"
$start['goofs.list'] = "GOOFS LIST"
$start['iso-aka-titles.list'] = "AKA TITLES LIST ISO"
$start['italian-aka-titles.list'] =" AKA TITLES LIST ITALIAN"
$start['keywords.list:'] = "THE KEYWORDS LIST"
$start['language.list'] = "LANGUAGE LIST"
$start['laserdisc.list'] = "LASERDISC LIST"
$start['literature.list'] = "LITERATURE LIST"
$start['locations.list'] = "LOCATIONS LIST"
$start['miscellaneous-companies.list'] = "MISCELLANEOUS COMPANY LIST"
$start['miscellaneous.list'] = "THE MISCELLANEOUS FILMOGRAPHY LIST"
$start['movie-links.list'] = "MOVIE LINKS LIST"
$start['movies.list'] = "MOVIES LIST"
$start['mpaa-ratings-reasons.list'] = "MPAA RATINGS REASONS LIST"
$start['plot.list'] = "PLOT SUMMARIES LIST"
$start['producers.list'] = "THE PRODUCERS LIST"
$start['production-companies.list'] = "PRODUCTION COMPANIES LIST"
$start['production-designers.list'] = "THE PRODUCTION DESIGNERS LIST"
$start['quotes.list'] = "QUOTES LIST"
$start['ratings.list'] = "MOVIE RATINGS REPORT"
$start['release-dates.list'] = "RELEASE DATES LIST"
$start['running-times.list'] = "RUNNING TIMES LIST"
$start['sound-mix.list'] = "SOUND-MIX LIST"
$start['soundtracks.list'] = "SOUNDTRACKS LIST"
$start['special-effects-companies.list'] = "SFXCO COMPANIES LIST"
$start['taglines.list'] = "TAG LINES LIST"
$start['technical.list'] = "TECHNICAL LIST"
$start['trivia.list'] = "FILM TRIVIA"
$start['writers.list'] = "THE WRITERS LIST"

def isNumeric(s)
  Float(s) != nil rescue false
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

file_name = options.file[0]
total_lines = open(file_name).read.count("\n")
f = File.open(file_name, 'r')

section = false # Did we find the right section to parse?
parsing = false # Real data now available

# These variables are used when parsing a multi-line entry
current_person = nil
current_movie_name = nil
current_movie_key = nil
mpaa_reason = nil
plot = nil

# Start reading the file
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

      junk, date = the_rest.split " ", 2
      begin
        date = Date.parse date
      rescue ArgumentError
        puts "FATAL: Invalid date one line 1 (#{date})"
        exit 1
      end

    else
      puts "FATAL: Line 1 does not begin with CRC:"
      exit 1
    end
    next

  end

  if !section && line.match(/#{$start[filename]}/)
    section = true
    next
  end

  if section
    if !parsing
      case filename

        when "countries.list", "genres.list", "language.list", "locations.list",
            "mpaa-ratings-reasons.list", "plot.list", "release-dates.list", "running-times.list"
          # Ignore the lines before the data starts
          next if line.match(/^=/)
          next if line.strip.empty?
          parsing = true

        when "directors.list", "actors.list", "actresses.list"
          # Ignore the lines before the data starts
          next if line.match(/^=/)
          next if line.strip.empty?
          next if line.match(/^Name/)
          next if line.match(/^-/)
          parsing = true

        else
          puts "FATAL: I don't know how to parse #{filename}"
          exit 1
      end

    end
  end

  if parsing

    case filename

      when 'plot.list'

        parts = line.split ": "

        if parts[0] == "MV"
          current_movie_name = parts[1]
          options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name
          plot = ""
          next
        end

        if parts[0] == "PL"
          plot += " " + parts[1].strip
          next
        end

        if parts[0] == "BY"
          plot += " (BY: " + parts[1].strip + ")"
          next
        end

        next if line.empty?

        # Dashed line is the delimiter
        if line.match(/^-/) && !plot.nil?

          puts "#{current_movie_key}\t#{current_movie_name}\t#{plot.strip}"

        end


      when 'mpaa-ratings-reasons.list'
        parts = line.split ": "

        if parts[0] == "MV"
          current_movie_name = parts[1]
          options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name
          mpaa_reason = ""
          next
        end

        if parts[0] == "RE"
          mpaa_reason += " " + parts[1].strip
          next
        end

        next if line.empty?

        # Dashed line is the delimiter
        if line.match(/^-/) && !mpaa_reason.nil?

          rating, reason = mpaa_reason.strip.split " for ", 2

          puts "#{current_movie_key}\t#{current_movie_name}\t#{rating}\t#{reason}"

        end

      when 'running-times.list'

        next if line.match(/^-/) # skip lines is filled with -'s

        parts = line.split "\t"

        current_movie_name = parts[0]
        options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name

        last = parts[parts.count - 1]
        if last.match(/\(/) && !last.match(/\(None/) # Sometimes the country is (None):30
                                                     # Must be a comment
          last = parts[parts.count - 2]
        end

        x = last.split ":", 2
        if x.count == 1
          length = x[0]
        else
          length = x[1]
        end

        # Ignore anything that is not integer
        if isNumeric length
          puts "#{current_movie_key}\t#{current_movie_name}\t#{length.to_i}"
        end

      when 'genres.list'

        next if line.match(/^-/) # skip lines is filled with -'s

        parts = line.split "\t"

        current_movie_name = parts[0]
        options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name

        genre = parts[parts.count - 1]

        puts "#{current_movie_key}\t#{current_movie_name}\t#{genre}"

      when 'countries.list'

        next if line.match(/^-/) # skip lines is filled with -'s

        parts = line.split "\t"
        current_movie_name = parts[0]
        options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name

        country = parts[parts.count - 1]

        if country.match(/\(/)
          # This looks like a comment, it begins with a (
          country = parts[parts.count - 2]
          comment = parts[parts.count - 1]
        end

        if country.strip.empty?
          $stderr.puts "WARNING: Country value is empty for this line: #{$line_number}: #{line}"
        end

        puts "#{current_movie_key}\t#{current_movie_name}\t#{country}"

      when 'release-dates.list'

        next if line.match(/^-/) # skip lines is filled with -'s

        parts = line.split "\t"
        current_movie_name = parts[0]
        options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name

        release_date = parts[parts.count - 1]

        if release_date.match(/^\(/)
          # This looks like a comment, it begins with a (
          release_date = parts[parts.count - 2]
          comment = parts[parts.count - 1]
        end

        if release_date.strip.empty?
          $stderr.puts "WARNING: release_date value is empty for this line: #{$line_number}: #{line}"
        end

        country, date = release_date.split ":"
        begin
          parsed_date = Date.parse(date).strftime("%Y/%m/%d")
        rescue
          parsed_date = ""
        end


        puts "#{current_movie_key}\t#{current_movie_name}\t#{country}\t#{date}\t#{parsed_date}"

      when 'locations.list'

        next if line.match(/^-/) # skip lines is filled with -'s

        parts = line.split "\t"
        current_movie_name = parts[0]

        next if current_movie_name.nil?

        options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name

        location = parts[parts.count - 1]

        if location.match(/^\(/)
          # This looks like a comment, it begins with a (
          location = parts[parts.count - 2]
          comment = parts[parts.count - 1]
        end

        if location.strip.empty?
          $stderr.puts "WARNING: location value is empty for this line: #{$line_number}: #{line}"
        end

        puts "#{current_movie_key}\t#{current_movie_name}\t#{location}"


      when 'language.list'

        next if line.match(/^-/) # skip lines is filled with -'s

        parts = line.split "\t"
        current_movie_name = parts[0]
        options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name

        language = parts[parts.count - 1]

        if language.match(/^\(/)
          # This looks like a comment, it begins with a (
          language = parts[parts.count - 2]
          comment = parts[parts.count - 1]
        end

        if language.strip.empty?
          $stderr.puts "WARNING: Language value is empty for this line: #{$line_number}: #{line}"
        end

        puts "#{current_movie_key}\t#{current_movie_name}\t#{language}"

      when 'directors.list'

        break if line.match(/^-/) # Last line is -'s

        parts = line.split "\t"

        if current_person.nil? && parts.count > 1

          current_person = parts[0]

          current_movie_name = parts[parts.length - 1]
          options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name
          options.output_hash_as_key == true ? current_person_key = Digest::SHA1.hexdigest(current_person) : current_person_key = current_person

          puts "#{current_movie_key}\t#{current_movie_name}\t#{current_person_key}\t#{current_person}"

          next
        end

        if line.strip.empty?
          next if current_person.nil?

          current_person = nil

        end

      when 'actors.list', 'actresses.list'

        break if line.match(/^--------------------/) # Last line is -'s, note that some lines to begin with a -, in the actors name

        parts = line.split "\t"

        if current_person.nil? && parts.count > 1

          current_person = parts[0]

          # Looks like the line is delimited by <space><space> where
          # movie_name  character  some_shit
          current_movie_name, character = parts[parts.length - 1].split "  ", 2
          if character.nil?
            character = "[]"
          end


          options.output_hash_as_key == true ? current_movie_key = Digest::SHA1.hexdigest(current_movie_name) : current_movie_key = current_movie_name
          options.output_hash_as_key == true ? current_person_key = Digest::SHA1.hexdigest(current_person) : current_person_key = current_person

          puts "#{current_movie_key}\t#{current_movie_name}\t#{current_person_key}\t#{current_person}\t#{character}"

          next
        end

        if line.strip.empty?
          next if current_person.nil?

          current_person = nil

        end


    end # case filename

  end
end

#result = RubyProf.stop
#printer = RubyProf::FlatPrinter.new(result)
#printer.print(STDOUT, 0)
