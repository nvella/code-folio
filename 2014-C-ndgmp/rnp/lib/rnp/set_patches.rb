class Set
  def deep_clone
    new_set = Set.new
    self.each do |obj|
      new_set.add obj.dup
    end
    return new_set
  end
end
