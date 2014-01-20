require 'pdf-reader'
require './monkey'
require './prices'

module Era
  FILE = 'D_006_0006806.pdf'
  
  class << self
    def deltas best_offer
      reader = PDF::Reader.new FILE

      p1 = reader.page 1
      p2 = reader.page 2

      text = p1.text + p2.text

      phonelines, rest = text.split /z tabletem \(/
      tablety, _ = rest.split /dedykowana/

      phones = parse(phonelines)

      monthly24 = [260, 200, 170, 130, 90, 70, 50]

      total24extra = monthly24.map {|x| x * 24 - best_offer * 24 }
      total36extra = monthly24.map {|x| (x-10) * 36 - best_offer * 36 }

      totalextra = (total24extra.zip total36extra).map(&:min)

      totalphones = phones.map do |name, prices|
        [name, prices.zip(totalextra).map(&:sum)]
      end

      deltas = totalphones.map do |name, prices|
        [Prices.get(name) - prices.min, name]
      end

      total36textra = monthly24.map {|x| (x+5) * 36 - best_offer * 36 }

      totaltablets = parse(tablety).map do |name, prices|
        [name, prices.zip(total36textra).map(&:sum)]
      end

      deltas += totaltablets.map do |name, prices|
        [Prices.get(name.gsub("+Tablet","")) - prices.min + 400, name]
      end
    end
    
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
  end
end
