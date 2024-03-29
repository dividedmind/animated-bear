module Scorer
  class << self
    def score phone
      scores = self.methods.map do |t|
        next if t == :score
        sl = method(t).source_location
        next unless sl && sl.first == __FILE__
        [t, send(t, phone.send(t))]
      end.compact.to_h

      leftover_keys = phone.to_h.keys - scores.keys - 
          %i(name price frequencies)
      # warn "Left over keys: #{leftover_keys}" if leftover_keys
      phone.scores = scores
      scores.values.compact.inject 0, :+
    end
      
    def screen_size size
      size * 2 - 7.28
    rescue
      nil
    end
    
    def ram v
      Math.log2(v) ** 2 / 10 - 7
    rescue
      nil
    end
    
    def ppi ppi
      Math.log2(ppi) * 3 - 22
    rescue
      nil
    end
    
    def memory mem
      Math.log2(mem) / 1.5 - 5 if mem > 0
    rescue
      nil
    end

    def camera_resolution cr
      if cr && cr > 0
        (Math.log2(cr) - 2)*1.5
      else
        nil
      end
    end
    
    def weight v
      - Math.log2(Math.sqrt(v)) * 9 + 31
    rescue
      nil
    end
    
    def color_bits cb
      cb / 2 - 6
    rescue
      nil
    end
    
    def screen_resolution sr
      Math.log2(Math.sqrt(sr.inject(:*))) * 2.5 - 21
    rescue
      nil
    end
    
    def size sz
      5000/Math.log2(sz.inject(:*))**2 - 19
    rescue
      nil
    end
    
    def battery_standby_days v
      Math.sqrt(v) * 2 - 9
    rescue 
      nil
    end
    
    def battery_talk_hours v
      Math.sqrt(Math.log2(v)) * 6 - 10
    rescue 
      nil
    end
    
    def os os
      kind, ver = os
      case kind
      when :proprietary, 'ST-E RTKE'
        -5
      when :nokia
        -4
      when :android
        return nil unless ver
        if ver > "4"
          4 + ("0." + ver.gsub('.','')).to_f
        elsif ver > "2"
          -1 + ("0." + ver.gsub('.','')).to_f
        elsif ver > "1"
          -2 + ("0." + ver.gsub('.','')).to_f
        else
          warn "unknown android: #{os}"
          nil
        end
      when :blackberry
        0.5
      when :windows
        1
      when :bada
        3
      when :maemo
        2.5
      when :ios
        2
      when :symbian
        -2
      when nil
        nil
      else
        warn "unknown os: #{os}"
        nil
      end
    end
  end
end
