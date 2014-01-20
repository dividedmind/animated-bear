require 'watir-webdriver'
require 'addressable/template'
require 'json'

module Prices
  class << self
    def browser
      @browser ||= Watir::Browser.new
    end
    
    ALLEGRO = Addressable::Template.new 'http://allegro.pl/telefony-komorkowe-165?string={query}&buyNew=1&order=d&offerTypeBuyNow=1'

    def phoneprices
      @phoneprices ||= JSON.load(File.read('prices.json')) rescue {}
    end
    
    def get name
      price = phoneprices[name]
      unless price
        browser.goto ALLEGRO.expand(query: name).to_s
        readline
        price = browser.element(css: '.price .dist').text.gsub(' ', '').scan(/\d+/).first.to_i
        puts "Got price: #{price}"
        phoneprices[name] = price
        File.write 'prices.json', JSON.dump(phoneprices)
      end
      price
    end
  end
end
