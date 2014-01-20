#!/usr/bin/env ruby

require 'pp'

require './skapiec'

phones = Skapiec.phones
pp phones.sort_by(&:score)[-3..-1]

Skapiec.dump_collected_values