class IO
  def read_string
    buffer = "."
    while buffer[-1].ord != 0x00 do
      buffer += self.read 1
    end
    return buffer[1 .. buffer.length - 2]
  end
end
