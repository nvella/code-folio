module RMCCLib::Packets
  class Packet37BlockBreakAnimaiton < Packet
    attr_reader :entity_id, :x, :y, :z, :stage
  
    def initialize entity_id = 0, x = 0, y = 0, z = 0, stage = 0
      super 0x37
      @entity_id = entity_id
      @x = x
      @y = y
      @z = z
      @stage = stage
    end
    
    def read socket
      @entity_id = socket.read_int
      @x = socket.read_int
      @y = socket.read_int
      @z = socket.read_int
      @stage = socket.read_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_int @x
      socket.write_int @y
      socket.write_int @z
      socket.write_byte @stage
    end
  end
end
