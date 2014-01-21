#!/usr/bin/env ruby

require 'pp'
require 'histogram/array'
require 'ascii_charts'

require './skapiec'
require './scorer'

Phone.scorer = Scorer

phones = Skapiec.phones

def normalize phones, floor: 0, ceil: 100
  scores = phones.map(&:score)
  min, max = scores.minmax
  delta = max - min
  tdelta = ceil - floor
  phones.each do |ph|
    ph.score = floor + (ph.score - min)/delta * tdelta
  end
end

#normalize phones
scores = phones.map(&:score)

def draw_hist bins, freqs
  puts AsciiCharts::Cartesian.new(
    bins.map{|x|x.round(2)}.zip(freqs), bar: true, hide_zero: true, max_y_vals: 10
  ).draw
end

draw_hist *scores.histogram
draw_hist *phones.map {|p| 
  p.scores[:color_bits]
}.compact.histogram

phones = phones.sort_by{|p|p.scores[:color_bits]|| 0}
pp phones[-1]

Skapiec.dump_collected_values
