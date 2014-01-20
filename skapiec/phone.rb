class Phone < OpenStruct
  def initialize name, price
    super()
    self.name = name
    self.price = price
  end
end
