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
    
    FILE = '17-notebooki.html'
    
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
      when 'Matryca'
        phone.matte = !!(value =~ /mat/i)
      when 'Ekran'
        _, diam, w, h, ts = value.match(/^(.*")?\s*(?:(\d+)x(\d+))?\s*(?i:touchscreen)?$/).to_a
        phone.screen_size = diam.to_fl if diam
        phone.screen_resolution = [w.to_i, h.to_i] if w
        phone.touchscreen = !!ts
      when 'System operacyjny'
        case value
        when /Brak/
          phone.os = false
        when /Android(?:\s+(\d\S+))?/
          phone.os = [:android, $1]
        when /Chrome OS/
          phone.os = [:chrome]
        when /Linux/
          phone.os = [:linux]
        when /Mac OS X/
          phone.os = [:darwin]
        when /Vista/
          phone.os = [:windows, value]
        when /Windows (.*)/
          phone.os = [:windows, $1]
        else
          fatal "Unrecognized OS: #{value}"
          phone.os = value
        end
      when 'Sieć bezprzewodowa WLAN'
        phone.wifi = (value == 'Tak' ? true : value)
      when 'Bluetooth'
        phone.bluetooth = (value == 'Tak')
      when 'HDMI'
        phone.hdmi = (value == 'tak')
      when 'Waga'
        phone.weight = value.tr(?,,?.).to_f
      when 'Nr producenta'
        phone.model_number = value
      when 'Procesor'
        phone.cpu = value
      when 'Dysk SSD'
        phone.ssd = value.to_i
      when 'Dysk HDD'
        phone.hdd = value.to_i
      when 'Dysk SSHD'
        _, hdd, ssd = value.match(/(\d+)GB HDD \+ (\d+)GB SSD/).to_a
        phone.hdd = hdd.to_i
        phone.ssd = ssd.to_i
      when 'Modem 3G'
        phone.umts = (value == 'Tak')
      when 'Pamięć RAM'
        _, ct, unit = value.match(/(\d+)([MG]B)/).to_a
        ct = ct.to_i
        ct *= 1024 if unit == 'GB'
        phone.ram = ct
      when 'Karta graficzna'
        phone.gpu = value
      when 'Napęd optyczny'
        phone.odd = {
          'BLU-RAY' => :bdd,
          'Brak' => false,
          'DVD-RW' => :dvd
        }[value]
      when 'Seria'
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
      URL = 'http://www.skapiec.pl/cat/17-notebooki.html'
      
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
