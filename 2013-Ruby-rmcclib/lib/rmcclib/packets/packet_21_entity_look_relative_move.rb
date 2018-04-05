module RMCCLib::Packets
  class Packet21EntityLookRelativeMove < Packet
    attr_reader :entity_id, :x, :y, :z, :yaw, :pitch
    
    def initialize entity_id = 0, x = 0, y = 0, z = 0, yaw = 0.0, pitch = 0.0
      super 0x21
      @entity_id = entity_id
      @x = x
      @y = y
      @z = z
      @yaw = yaw
      @pitch = pitch
    end
    
    def read socket
      @entity_id = socket.read_int
      @x = socket.read_abs_byte
      @y = socket.read_abs_byte
      @z = socket.read_abs_byte
      @yaw = (socket.read_byte * (1 / 256.0)) * 360
      @pitch = (socket.read_byte * (1 / 256.0)) * 360
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_abs_byte @x
      socket.write_abs_byte @y
      socket.write_abs_byte @z
      socket.write_byte ((@yaw * (1 / 360.0)) * 256).floor
      socket.write_byte ((@pitch * (1 / 360.0)) * 256).floor
    end
  end
end
