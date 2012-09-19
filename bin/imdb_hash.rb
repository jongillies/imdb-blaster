#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'

movie = Hash.new


movie['key'] = ""
movie['title'] = ""
movie['year'] = ""
movie['plot'] = ""
movie['mpaa_rating'] = ""
movie['mpaa_reason'] = ""
movie['runtime'] = 120
movie['genres'] = Array.new
movie['genres'] << "Family"
movie['genres'] << "Adventure"
movie['country'] = ""
movie['release_date'] = ""

movie['directors'] = Array.new
movie['directors'] << "Foobar"
movie['actors'] = Array.new
movie['actors'] << "Foobar"

puts movie.to_yaml

