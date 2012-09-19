#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'

data = Hash.new
data['movies.list'] = Hash.new

d = data['movies.list']
d['crc'] = 'mycrc'
d['name'] = 'movies.list'
d['date'] = Time.now
d['movies'] = Hash.new

movies = d['movies']


movies['The Terminator'] = Hash.new
movies['The Terminator']['year'] = 1989

movies['Star Wars'] = Hash.new
movies['Star Wars']['year'] = 1977

puts data.to_yaml


