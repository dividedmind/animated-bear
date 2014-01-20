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
    MANUFACTURERS = %w(
      Qualcomm 
      MediaTek 
      TI 
      ST-Ericsson 
      Samsung 
      Marvell 
      Intel 
      Apple
      Broadcom
      Hisilicon
      NVIDIA
      Tavor
      Boxchip
      Freescale
    )
    
    def self.interpret description
      specs = {}

      if description.gsub!(/\s*(\d+) MHz$/, '')
        specs[:clock] = $1.to_i
      end
      
      if description =~ /^Snapdragon/
        description = "Qualcomm " + description
      end

      if description =~ /^(\S+)(?: (.*))?$/ && MANUFACTURERS.include?($1)
        specs.merge! manufacturer: $1, model: $2
      elsif !description.empty?
        case description
        when 'Cortex'
          specs.merge! core: "Cortex"
        when "GT-B7350 Omnia Pro", "ARM11"
          # spurious or non-informative
        when 'SC6530'
          specs.merge! model: description
        when /^(ARM|ARM).* (.*)$/
          specs.merge! model: $1
        when /Cortex/
          if description =~ /Dual[ -]Core/i
            specs.merge! core_count: 2
          elsif description =~ /Quad[ -]Core/i
            specs.merge! core_count: 4
          end
          core = "Cortex"
          core += " A-#{$1}" if description =~ /A[ -]?(\d+)/
          specs.merge! core: core
        else
          warn "unrecognized processor: #{description}"
          specs.merge! description: description
        end
      end
      
      new specs
    end
  end
end
