class Set
  def deep_clone
    new_set = Set.new
    self.each do |obj|
      new_set.add [obj[0], obj[1]]
    end
    return new_set
  end
  
  def my_equals other
    self.each {|obj| if not other.include? obj then return false end }
    other.each {|obj| if not self.include? obj then return false end }
    return true
  end
end
