require 'pdf-reader'

file = 'D_006_0006808.pdf'
reader = PDF::Reader.new file

p1 = reader.page 1

entries = p1.text.scan(/^\s*((\S+\s+){6,7}\S+)\s*$/).map(&:first)
entries.map! {|l| l.gsub %r{\d+/(\d+)\*}, '\1' }
entries.select! {|l| l =~ /^\S+\s+(\d+\s+){5,6}\d+/ }

phones = entries.map do |line|
  name, *prices = line.split
  
  name.gsub! 'iPhone', 'IPhone'
  name.gsub! /^(\p{Lu}+)(\p{Lu})/, '\1 \2'
  name.gsub! /(((?<=\p{Ll})(\p{Lu}|\d))|\()/, ' \1'
  
  prices.unshift 1 if prices.size == 6
  [name] + prices.map(&:to_i)
end

p phones
