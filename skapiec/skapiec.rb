require 'memoist'
require 'nokogiri'
require 'ostruct'
require 'methadone'

require './monkey'
require './phone'

module Skapiec
  class << self
    extend Memoist
    include Methadone::CLILogging
    
    FILE = '200-telefony-gsm.html'
    
    def page_text
      File.read FILE
    end
    
    def html
      Nokogiri::HTML page_text, nil, 'latin2'
    end
    
    def phones
      phones = html.css('.complex').map do |entry|
        name = entry.css('.entry-title a').text.strip
        price = entry.css('.zl').text.to_i
        
        phone = Phone.new name, price
        
        datatable = entry.css('.datatable div:first div').map do |row|
          tag = row.xpath('span').text.chomp(':')
          value = row.xpath('strong').text
          next if tag.empty?
          interpret_tag phone, tag, value
          [tag, value]
        end
        
        phone
      end
      
      phones
    end
    
    def interpret_tag phone, tag, value
      case tag
      when 'Sieć'
        phone.frequencies = value.scan(/\d+/).map(&:to_i)
      when 'Aparat cyfrowy'
        phone.camera_resolution = value.to_fl
      when 'Ekran'
        _, diam, w, h = value.match(/^(.*)" (\d+)x(\d+)$/).to_a
        phone.screen_size = diam.to_fl
        phone.screen_resolution = [w.to_i, h.to_i]
      when 'Kolory'
        if value =~ /16 mln/
          phone.color_bits = 24
        else
          fatal "unknown colors: #{value}"
        end
      when 'Wymiary'
        phone.size = value.scan(/\d+/).map(&:to_i)
      when 'Waga'
        phone.weight = value.to_i
      when 'Wbudowana pamięć'
        phone.memory = value.to_i
      when 'Komunikacja', 'Karta pamięci', 'Funkcje głosowe', 'Rodzaj'
        # too unreliable or irrelevant
      when 'System operacyjny'
        if value =~ /Android (\d\S+)/
          phone.os = [:android, $1]
        elsif value =~ /Windows.*(\d+)/
          phone.os = [:windows, $1]
        else
          fatal "Unrecognized OS: #{value}"
        end
      when 'Procesor'
        phone.cpu = value
      when 'Pamięć RAM'
        ct, unit = value.split
        ct = ct.to_i
        ct *= 1024 if unit == 'GB'
        phone.memory = ct
      when 'Pojemność akumulatora'
        phone.battery_mAh = value.to_i
      when 'Czas czuwania'
        phone.battery_standby_days = value.to_fl
      when 'Czas rozmowy'
        phone.battery_talk_hours = value.to_fl
      else
        warn "Unknown tag #{tag}, collecting values..." unless collecting?
        collect_tag tag, value
      end
    end
    
    def collecting?
      !@collected_tag.nil?
    end
    
    def collect_tag tag, value
      return if (@collected_tag ||= tag) != tag
      (@collected_values ||= []) << value
    end
    
    def dump_collected_values
      return unless collecting?
      info "Values of unknown tag #{@collected_tag}:"
      info @collected_values.sort.uniq.pretty_print_inspect
    end
  end
end
