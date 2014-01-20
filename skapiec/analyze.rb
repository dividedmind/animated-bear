#!/usr/bin/env ruby

require 'pp'
require 'histogram/array'
require 'ascii_charts'

require './skapiec'

phones = Skapiec.phones

def normalize phones, floor: 0, ceil: 10
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

bins, freqs = scores.histogram(10)
puts AsciiCharts::Cartesian.new(
  bins.map{|x|x.round(2)}.zip(freqs), bar: true, hide_zero: true, max_y_vals: 10
).draw

pp phones.sort_by(&:bfb)[-3..-1]

Skapiec.dump_collected_values