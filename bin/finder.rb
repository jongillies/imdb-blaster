#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'

local_cache = YAML::load(File.open('index.yaml'))

local_cache_by_checksum = Hash.new
local_cache.each do |key, value|
  local_cache_by_checksum[value['checksum']] = value
end

local_cache_by_checksum.each do |key, cache|

  #puts cache['checksum']
  title = File.basename(cache['basename'], File.extname(cache['basename']))
  puts
  puts
  puts "#{cache['checksum']}\t\t#{title}"
  data = `./find.rb -F data \"#{title}"`
  data.each do |line|
    puts "#{cache['checksum']}\t0\t#{line}"
  end


end

