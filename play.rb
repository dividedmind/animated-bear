require 'pdf-reader'
require './monkey'
require './prices'

module Play
  FILE = 'cennik-play-sklep.pdf'
  
  class << self
    def deltas best_offer
      reader = PDF::Reader.new FILE

      text = (1..4).map {|x| reader.page(x).text}.join
      
      prices = text.scan(/^(\S.*?)((\s+[0-9.]+){18})$/).map do |name, prices|
        [name, prices.split.map(&:to_i)]
      end
      
      monthly = [30, 50, 80, 50, 60, 70, 80, 90, 100, 110, 120, 100, 110, 120, 130, 140, 150, 180]
      extra = monthly.map {|x| x * 24 - best_offer * 24 }
      
      prices.map! do |name, price|
        [name, price.zip(extra).map(&:sum)[3..-1]]
      end
      
      deltas = prices.map do |name, prices|
        [Prices.get(name) - prices.min, name]
      end
    end
  end
end

