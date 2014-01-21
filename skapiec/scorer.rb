module Scorer
  class << self
    def score phone
      scores = self.methods.map do |t|
        next if t == :score
        sl = method(t).source_location
        next unless sl && sl.first == __FILE__
        [t, send(t, phone.send(t))]
      end.compact.to_h
      
      phone.scores = scores
      scores.values.compact.inject 0, :+
    end
      
    def screen_size size
      size * 2 - 7.28
    rescue
      nil
    end
    
    def ppi ppi
      Math.log2(ppi) * 3 - 22
    rescue
      nil
    end
    
    def memory mem
      return nil unless mem && mem > 0
      Math.log2(mem) - 6.5
    end

    def camera_resolution cr
      if cr && cr > 0
        (Math.log2(cr) - 2)*1.5
      else
        nil
      end
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
