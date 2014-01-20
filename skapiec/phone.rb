class Phone < OpenStruct
  def initialize name, price
    super()
    self.name = name
    self.price = price
  end
  
  def cpu= value
    if value.is_a? String
      cpu = CPU.interpret value
    end
    super(cpu)
  end

  class CPU < OpenStruct
    MANUFACTURERS = %w(Qualcomm MediaTek TI ST-Ericsson Samsung)
    
    def self.interpret description
      specs = {}

      if description.gsub!(/\s+(\d+) MHz$/, '')
        specs[:clock] = $1.to_i
      end

      case description
      when /^Dual Core Cortex[- ](.*)$/
        specs.merge! core: "Cortex #{$1}", core_count: 2
      when /^Quad Core Cortex[- ](.*)$/
        specs.merge! core: "Cortex #{$1}", core_count: 4
      when /^(\S+)( (.*))?$/
        mfg, name = $1, $3
        warn "unrecognized CPU manufacturer: #{mfg}" unless MANUFACTURERS.include? mfg
        specs.merge! manufacturer: mfg, model: name
      else
        warn "unrecognized processor: #{description}"
        specs.merge! description: description
      end
      
      new specs
    end
  end
end
