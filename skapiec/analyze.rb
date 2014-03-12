#!/usr/bin/env ruby

require 'pp'
require 'histogram/array'
require 'ascii_charts'

require './skapiec'
require './scorer'

Phone.scorer = Scorer

phones = Skapiec.phones.select { |p| p.price <= 1800 }
puts "Total: #{phones.length} notebooks"

def normalize phones, floor: 0, ceil: 1000
  scores = phones.map(&:score)
  min, max = scores.minmax
  delta = max - min
  tdelta = ceil - floor
  phones.each do |ph|
    ph.score = floor + (ph.score - min)/delta * tdelta
  end
end

normalize phones
scores = phones.map(&:score)

def draw_hist bins, freqs
  puts AsciiCharts::Cartesian.new(
    bins.map{|x|x.round(2)}.zip(freqs), bar: true, hide_zero: true, max_y_vals: 10
  ).draw
end

def stats vals
  draw_hist *vals.compact.histogram(10)
  p vals.compact.mean_sd
end

Skapiec.dump_collected_values
# stats phones.map { |x| x.ssd }

#pp phones.map(&:os).uniq

phones = phones.sort_by &:bfb #{|p|p.scores[:ram]||-1}
pp phones[-3..-1]

