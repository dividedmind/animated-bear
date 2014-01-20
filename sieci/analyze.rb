#!/usr/bin/env ruby

require 'pp'
require './era'
require './play'

BEST_OFFER = 30 # play unlimited smartfon

deltas = Play.deltas(BEST_OFFER).map{|l|l.push(:play)}
deltas += Era.deltas(BEST_OFFER).map{|l|l.push(:era)}
pp deltas.sort
