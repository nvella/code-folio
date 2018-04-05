module RMCCLib::Packets
  class Packet1FEntityRelativeMove < Packet
    attr_reader :entity_id, :x, :y, :z
    
    def initialize entity_id = 0, x = 0, y = 0, z = 0
      super 0x1F
      @entity_id = entity_id
      @x = x
      @y = y
      @z = z
    end
    
    def read socket
      @entity_id = socket.read_int
      @x = socket.read_abs_byte
      @y = socket.read_abs_byte
      @z = socket.read_abs_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_abs_byte @x
      socket.write_abs_byte @y
      socket.write_abs_byte @z
    end
  end
end
