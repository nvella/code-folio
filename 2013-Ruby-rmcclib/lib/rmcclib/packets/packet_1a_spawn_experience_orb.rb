module RMCCLib::Packets
  class Packet1ASpawnExperienceOrb < Packet
    attr_reader :entity_id, :x, :y, :z, :count
  
    def initialize entity_id = 0, x = 0.0, y = 0.0, z = 0.0, count = 0
      super 0x1A
      @entity_id = entity_id
      @x = x
      @y = y
      @z = z
      @count = count
    end
    
    def read socket
      @entity_id = socket.read_int
      @x = socket.read_abs_int
      @y = socket.read_abs_int
      @z = socket.read_abs_int
      @count = socket.read_short
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_abs_int @x
      socket.write_abs_int @y
      socket.write_abs_int @z
      socket.write_short @count
    end
  end
end
