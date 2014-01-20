require 'memoist'
require 'nokogiri'
require 'ostruct'

module Skapiec
  class << self
    extend Memoist
    
    FILE = '200-telefony-gsm.html'
    
    def page_text
      File.read FILE
    end
    
    def html
      Nokogiri::HTML page_text, nil, 'latin2'
    end
    
    def phones
      html.css('.complex').map do |entry|
        name = entry.css('.entry-title a').text.strip
        price = entry.css('.zl').text.to_i
        
        datatable = entry.css('.datatable div:first div').map do |row|
          tag = row.xpath('span').text.chomp(':')
          value = row.xpath('strong').text
          next if tag.empty?
          [tag, value]
        end.compact.to_h

        {
          name: name, 
          price: price, 
          specs: datatable
        }
      end
    end
  end
end
