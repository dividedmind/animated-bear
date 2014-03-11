class String
  def to_fl
    sub(',','.').to_f
  end
end

class Array
  def mean_sd
    m = mean
    variance = inject(0) { |variance, x| variance += (x - m) ** 2 }
    return m, Math.sqrt(variance/(size-1))
  end

  def mean
    inject(:+) / length
  end
end
