module RMCCLib::Packets
  class Packet20EntityLook < Packet
    attr_reader :entity_id, :yaw, :pitch
    
    def initialize entity_id = 0, yaw = 0.0, pitch = 0.0
      super 0x20
      @entity_id = entity_id
      @yaw = yaw
      @pitch = pitch
    end
    
    def read socket
      @entity_id = socket.read_int
      @yaw = (socket.read_byte * (1 / 256.0)) * 360
      @pitch = (socket.read_byte * (1 / 256.0)) * 360
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_byte ((@yaw * (1 / 360.0)) * 256).floor
      socket.write_byte ((@pitch * (1 / 360.0)) * 256).floor
    end
  end
end
