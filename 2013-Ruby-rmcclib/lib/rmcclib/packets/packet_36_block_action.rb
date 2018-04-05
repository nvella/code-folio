module RMCCLib::Packets
  class Packet36BlockAction < Packet
    attr_reader :x, :y, :z, :value_1, :value_2, :block_id
  
    def initialize x = 0, y = 0, z = 0, value_1 = 0, value_2 = 0, block_id = 0
      super 0x36
      @x = x
      @y = y
      @z = z
      @value_1 = value_1
      @value_2 = value_2
      @block_id = block_id
    end
    
    def read socket
      @x = socket.read_int
      @y = socket.read_short
      @z = socket.read_int
      @value_1 = socket.read_byte
      @value_2 = socket.read_byte
      @block_id = socket.read_short            
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @x
      socket.write_short @y
      socket.write_int @z
      socket.write_byte @value_1      
      socket.write_byte @value_2
      socket.write_short @block_id            
    end
  end
end
