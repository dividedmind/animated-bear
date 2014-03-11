module Scorer
  def self.normal m, s
    lambda { |x| (x - m) / s rescue nil }
  end

  class << self
    def score phone
      scores = self.methods.map do |t|
        next if %i(score normal from_bool).include? t
        sl = method(t).source_location
        next unless sl && sl.first == __FILE__
        [t, send(t, phone.send(t))]
      end.compact.to_h

      leftover_keys = phone.to_h.keys - scores.keys -
          %i(name price model_number)
      unless leftover_keys.empty? || @warned
        warn "Left over keys: #{leftover_keys}"
        @warned = true
      end
      phone.scores = scores
      scores.values.compact.inject 0, :+
    end

    define_method :screen_size, Scorer.normal(15.12, 1.41)
    define_method :ppi, Scorer.normal(118, 25)
    define_method :hdd, Scorer.normal(600, 271)
    define_method :ram, Scorer.normal(6816, 4644)
    def screen_resolution sr
      normal(1401292, 677179.2256205147)[sr.inject(:*)]
    rescue
      nil
    end

    def from_bool v
      case v
      when true
        5
      when false
        -5
      else
        0
      end
    end

    def odd v
      case v
      when :bdd
        5
      when :dvd
        1
      when false
        -5
      end
    end

    def wifi w
      w ? 5 : -5
    end

    %i(touchscreen bluetooth hdmi matte umts).each do |i|
      alias_method i, :from_bool
    end

    def gpu g
      0 # fuck knows how to score it
    end

    def weight w
      -(normal(2.30, 0.55)[w])
    rescue
      nil
    end

    def ssd o
      return -5 unless o
      normal(175, 196)[o]
    end

    def cpu cpu
      normal(2137, 418)[cpu.clock]
    end

    def os os
      kind, ver = os
      case kind
      when false
        5
      when :linux
        4
      when :darwin
        3
      when :chrome
        2
      when :android
        1
      when :windows
        case ver
        when /8/
          -1
        when /7/
          -2
        when /Vista/
          -3
        when /XP/
          -5
        else
          warn "unknown windows: #{os}" unless @warned
        end
      else
        warn "unknown os: #{os}" unless @warned
        nil
      end
    end
  end
end
