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
      scores.values.inject :+
    end
      
    def screen_size size
      (size || 0) * 2 - 5
    end
    
    def ppi ppi
      (ppi || 0) / 50 - 5
    end
    
    def os os
      kind, ver = os
      case kind
      when :proprietary
        -5
      when :nokia
        -4
      else
        0
      end
    end
  end
end
