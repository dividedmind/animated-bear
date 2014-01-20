#!/usr/bin/env ruby

require 'pp'
require './era'

BEST_OFFER = 30 # play unlimited smartfon

pp Era.deltas(BEST_OFFER).sort
