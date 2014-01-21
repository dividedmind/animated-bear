class String
  def to_fl
    sub(',','.').to_f
  end
end

class Array
  def mean
    inject(:+) / length
  end
end
