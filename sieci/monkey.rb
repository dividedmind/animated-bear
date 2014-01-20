class Array
  def sum
    inject(:+)
  end
  def rsorted?
    self == sort.reverse
  end
end
