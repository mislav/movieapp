class Array
  # select unique items that occur n times in the array
  def select_occurring(n)
    histogram.map { |item, num| item if num == n }.compact
  end
  
  # return a hash counting occurrences of unique items in array
  def histogram
    each_with_object(Hash.new(0)) do |item, hash|
      hash[item] += 1
    end
  end
end