module RMCCLib::Packets
  class Packet1CEntityVelocity < Packet
    attr_reader :entity_id, :vel_x, :vel_y, :vel_z
    
    def initialize entity_id = 0, vel_x = 0, vel_y = 0, vel_z = 0
      super 0x1C
      @entity_id = entity_id
      @vel_x = vel_x
      @vel_y = vel_y
      @vel_z = vel_z
    end
    
    def read socket
      @entity_id = socket.read_int
      @vel_x = socket.read_short
      @vel_y = socket.read_short
      @vel_z = socket.read_short
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_short @vel_x
      socket.write_short @vel_y
      socket.write_short @vel_z
    end
  end
end
