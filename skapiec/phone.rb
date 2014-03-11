class Phone < OpenStruct
  include Memoist
  include Methadone::CLILogging

  class << self
    attr_accessor :scorer
  end
  
  def initialize name, price
    super()
    self.name = name
    self.price = price
  end
  
  def score
    super || (self.score = calculate_score)
  end
  
  def bfb
    super || (self.bfb = score / price)
  end
  
  def ppi
    super || self.ppi = calculate_ppi
  end

  def pretty_print *a
    to_h.pretty_print *a
  end
  
  def calculate_ppi
    Math.sqrt(screen_resolution.map{|x|x*x}.inject(:+))/screen_size
  rescue
    nil
  end
  
  def scorer
    Phone.scorer
  end
  
  def calculate_score
    score = rand
    score += scorer.score self if scorer
  end
  
  def cpu= value
    if value.is_a? String
      cpu = CPU.interpret value
    end
    super(cpu)
  end

  class CPU < OpenStruct
    MANUFACTURERS = %w(
      Intel
      AMD
      ARM
    )
    
    def self.interpret description
      specs = {}

      odes = description.dup

      if description.gsub!(/\s*([0-9,]+)$/, '')
        res = $1.to_fl
        specs[:clock] = res * 1000 if res < 5
      end
      
      if description =~ /^(\S+)(?: (.*))?$/ && MANUFACTURERS.include?($1)
        specs.merge! manufacturer: $1, model: $2
      elsif !description.empty?
        case description
        when /Core/, /Pentium/, /Celeron/, /Atom/
          specs.merge! manufacturer: 'Intel', model: description
        when /Athlon/, /Turion/, /Phenom/
          specs.merge! manufacturer: 'AMD', model: description
        else
          warn "unrecognized processor: #{description}"
          specs.merge! description: description
        end
      end
      
      new specs
    end
  end
end
