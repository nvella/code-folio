class Array
  def avg
    if self.length < 1 then return 0 end
    out = 0
    self.each {|n| out += n}
    return out / self.length
  end
end
