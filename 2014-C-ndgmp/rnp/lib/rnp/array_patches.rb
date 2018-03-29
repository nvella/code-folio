class Array
  def avg
    numbs = 0.0
    self.each {|i| numbs += i}
    if self.length != 0 and numbs != 0 then
      return numbs / self.length
    else
      return 0
    end
  end
end
