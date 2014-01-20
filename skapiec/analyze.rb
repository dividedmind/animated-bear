#!/usr/bin/env ruby

require 'pp'
require 'histogram/array'
require 'ascii_charts'

require './skapiec'

phones = Skapiec.phones

bins, freqs = phones.map(&:score).histogram
puts AsciiCharts::Cartesian.new(
  bins.map{|x|x.round(2)}.zip(freqs), bar: true, hide_zero: true, max_y_vals: 10
).draw

pp phones.sort_by(&:score)[-3..-1]

Skapiec.dump_collected_values