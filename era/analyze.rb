#!/usr/bin/env ruby

require 'pdf-reader'
require 'pp'
require 'watir-webdriver'
require 'addressable/template'
require 'json'

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


def getprice name
  phoneprices ||= JSON.load(File.read('prices.json')) rescue {}

  def browser
    @browser ||= Watir::Browser.new
  end

  allegro = Addressable::Template.new 'http://allegro.pl/telefony-komorkowe-165?string={query}&buyNew=1&order=qd&offerTypeBuyNow=1'

  price = phoneprices[name]
  unless price
    browser.goto allegro.expand(query: name).to_s
    readline
    price = browser.element(css: '.price .dist').text.gsub(' ', '').scan(/\d+/).first.to_i
    puts "Got price: #{price}"
    phoneprices[name] = price
    File.write 'prices.json', JSON.dump(phoneprices)
  end
  price
end

deltas = totalphones.map do |name, prices|
  [getprice(name) - prices.min, name]
end

pp deltas.sort

total36textra = monthly24.map {|x| (x+5) * 36 - 40 * 36 }

totaltablets = parse(tablety).map do |name, prices|
  [name, prices.zip(total36textra).map(&:sum)]
end

deltas += totaltablets.map do |name, prices|
  [getprice(name.gsub("+Tablet","")) - prices.min + 400, name]
end

pp deltas.sort
