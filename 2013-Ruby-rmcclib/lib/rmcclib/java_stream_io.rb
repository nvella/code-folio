module RMCCLib::JavaStreamIO
  def write_ubyte ubyte
    write ubyte.chr
  end
    
  def write_byte byte
    write [byte].pack 'c'
  end
  
  def write_abs_byte byte
    write [byte * 32].pack 'c'
  end
    
  def write_short short
    write [short].pack 's>'
  end
    
  def write_ushort ushort
    write [ushort].pack 'S>'
  end
    
  def write_int int
    write [int].pack 'l>'
  end
  
  def write_uint uint
    write [uint].pack 'L>'
  end
  
  def write_abs_int int
    write [int.floor * 32].pack 'l>'
  end
    
  def write_long long
    write [long].pack 'q>'
  end
    
  def write_float float
    write [float].pack 'g'
  end
    
  def write_double double
    write [double].pack 'G'
  end
    
  def write_bool bool
    if bool then
      write_ubyte 1
    else
      write_ubyte 0
    end
  end
    
  def write_string string
    write_ushort string.length
    write string.encode('UCS-2BE').force_encoding 'BINARY'
  end
    
  def write_byte_array byte_array
    write_ushort byte_array.length
    write byte_array.force_encoding 'BINARY'
  end
   
  def read_ubyte
    read(1).ord
  end
    
  def read_byte
    read(1).unpack('c')[0]
  end
  
  def read_abs_byte
    read(1).unpack('c')[0] / 32.0
  end
    
  def read_short
    read(2).unpack('s>')[0]
  end
    
  def read_ushort
    read(2).unpack('S>')[0]
  end
   
  def read_int
    read(4).unpack('l>')[0]
  end
  
  def read_uint
    read(4).unpack('L>')[0]
  end
  
  def read_abs_int
    read(4).unpack('l>')[0] / 32.0
  end
    
  def read_long
    read(8).unpack('q>')[0]
  end
    
  def read_float
    read(4).unpack('g')[0]
  end
    
  def read_double
    read(8).unpack('G')[0]
  end
  
  def read_nibbles
    data = read(1).ord
    nibbles = [0, 0]
    
    2.times do |offset|
      4.times do |i|
        nibbles[offset] += 2 ** (data[(offset * 4) + i] - 1)
      end
    end
    
    return nibbles[0], nibbles[1]
  end
    
  def read_bool
    if read_ubyte == 1 then
      true
    else
      false
    end
  end
    
  def read_string
    length = read_ushort
    read(length * 2).force_encoding('UCS-2BE').encode('UTF-8')
  end
  
  def read_byte_array
    length = read_ushort
    read(length)
  end
end