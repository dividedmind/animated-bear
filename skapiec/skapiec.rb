require 'memoist'
require 'nokogiri'
require 'ostruct'
require 'methadone'
require 'json'

require './monkey'
require './phone'

module Skapiec
  class << self
    extend Memoist
    include Methadone::CLILogging
    
    FILE = '200-telefony-gsm.html'
    
    def page_text
      if File.exists? FILE
        File.read FILE
      else
        text = Fetcher.fetch
        File.write FILE, text
        text
      end
    end
    
    def html
      Nokogiri::HTML page_text
    end
    
    SPECS_FILE = 'specs.json'
    
    def override phone
      @overrides ||= (JSON.load File.read(SPECS_FILE) rescue {})
      @overrides[phone] || {}
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
        
        override(name).each do |k, v|
          phone[k.to_sym] = v
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
        _, diam, w, h = value.match(/^(.*")?\s*(?:(\d+)x(\d+))?$/).to_a
        phone.screen_size = diam.to_fl if diam
        phone.screen_resolution = [w.to_i, h.to_i] if w
      when 'Kolory'
        case value
        when /16(,\d)? mln/
          phone.color_bits = 24
        when /6[45] tys/
          phone.color_bits = 16
        when /256 tys/, /262 tys/, /160 tys/, /156 tys/
          phone.color_bits = 18
        when /mono/, '2'
          phone.color_bits = 1
        when /4 tys/
          phone.color_bits = 12
        else
          fatal "unknown colors: #{value}"
        end
      when 'Wymiary'
        size = value.scan(/^([0-9,.]+)\s*x\s*([0-9,.]+)\s*x\s*([0-9,.]+)(?: mm)?/i).first.map(&:to_fl)
        if size.any? {|x| x < 4 }
          # probably centimeters
          size.map! { |x| x * 10 }
        end
        phone.size = size
      when 'Waga'
        phone.weight = value.to_i
      when 'Wbudowana pamięć'
        phone.memory = value.to_i
      when 'Komunikacja', 'Karta pamięci', 'Funkcje głosowe', 'Rodzaj'
        # too unreliable or irrelevant
      when 'System operacyjny'
        case value
        when /Android(?:\s+(\d\S+))?/
          phone.os = [:android, $1]
        when /Windows(?:\s+(\d\S+))?/
          phone.os = [:windows, $1]
        when /i(?:Phone )?OS(?:\s+(\d\S+))?/
          phone.os = [:ios, $1]
        when /BlackBerry(?: OS)?(?:\s*(\d+))?/
          phone.os = [:blackberry, $1]
        when "producenta", "PROPRIET/REX", "S-Class 3D"
          phone.os = [:proprietary]
        when /Nokia/, "Series 30"
          phone.os = [:nokia]
        when /Bada(?:\s+(\d\S+))?/
          phone.os = [:bada, $1]
        when /Symbian(?:\s+(\d\S+))?/
          phone.os = [:symbian, $1]
        when "ST-E RTKE"
          phone.os = value
        when /Maemo(?:\s+(\d\S+))?/
          phone.os = [:maemo, $1]
        when /MeeGo(?:\s+(\d\S+))?/
          phone.os = [:maemo, $1]
        else
          fatal "Unrecognized OS: #{value}"
          phone.os = value
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
    rescue
      fatal "Error #{$!} interpreting tag #{tag}: '#{value}'"
      exit
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
  
  module Fetcher
    class << self
      include Methadone::CLILogging
      URL = 'http://www.skapiec.pl/cat/200-telefony-gsm.html'
      
      def fetch
        require 'watir-webdriver'
        text = ""
        
        b = Watir::Browser.new
        b.goto URL
        
        throttle
        
        b.div(class: 'pageLimitSelector').as.last.click
        
        while true
          text += b.html
          next_page = b.a(class: 'next')
          break unless next_page.exists?
          throttle
          next_page.click
        end
        
        text
      end
      
      THROTTLE = 10
      def throttle
        time = rand THROTTLE
        info "Sleeping for #{time}"
        sleep time
      end
    end
  end
end
