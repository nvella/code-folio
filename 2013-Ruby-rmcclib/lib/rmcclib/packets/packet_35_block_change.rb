module RMCCLib::Packets
  class Packet35BlockChange < Packet
    attr_reader :x, :y, :z, :id, :metadata
  
    def initialize x = 0, y = 0, z = 0, id = 0, metadata = 0
      super 0x35
      @x = x
      @y = y
      @z = z
      @id = id
      @metadata = metadata
    end
    
    def read socket
      @x = socket.read_int
      @y = socket.read_ubyte
      @z = socket.read_int
      
      @id = socket.read_short
      @metadata = socket.read_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @x
      socket.write_ubyte @y
      socket.write_int @z
      
      socket.write_short @id
      socket.write_byte @metadata
    end
  end
end