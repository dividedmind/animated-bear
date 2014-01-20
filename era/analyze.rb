#!/usr/bin/env ruby

require 'pdf-reader'
require 'pp'

file = 'D_006_0006806.pdf'
reader = PDF::Reader.new file

p1 = reader.page 1
p2 = reader.page 2

text = p1.text + p2.text

phonelines, rest = text.split /z tabletem \(/
tablety, _ = rest.split /dedykowana/

def parse lines
  entries = lines.scan(/^\s*((\S+\s+){6,7}\S+)\s*$/).map(&:first)
  entries.map! {|l| l.gsub %r{\d+/(\d+)\*}, '\1' }
  entries.select! {|l| l =~ /^\S+\s+(\d+\s+){5,6}\d+/ }

  phones = entries.map do |line|
    name, *prices = line.split
    
    name.gsub! 'iPhone', 'IPhone'
    name.gsub! /^(\p{Lu}+)(\p{Lu})/, '\1 \2'
    name.gsub! /(((?<=\p{Ll})(\p{Lu}|\d))|\()/, ' \1'
    
    prices.unshift 1 if prices.size == 6
    [name, prices.map(&:to_i)]
  end
end

phones = parse(phonelines)

monthly24 = [260, 200, 170, 130, 90, 70, 50]

total24extra = monthly24.map {|x| x * 24 - 40 * 24 }
total36extra = monthly24.map {|x| (x-10) * 36 - 40 * 36 }

pp [total24extra, total36extra]

totalextra = (total24extra.zip total36extra).map(&:min)
p totalextra

class Array
  def sum
    inject(:+)
  end
  def rsorted?
    self == sort.reverse
  end
end

totalphones = phones.map do |name, prices|
  [name, prices.zip(totalextra).map(&:sum)]
end

pp totalphones
totalphones.each do |name, prices|
  puts name unless prices.rsorted?
end
