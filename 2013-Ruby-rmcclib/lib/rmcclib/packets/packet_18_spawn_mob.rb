module RMCCLib::Packets
  class Packet18SpawnMob < Packet
    attr_reader :entity_id, :type, :x, :y, :z, :pitch, :head_pitch, :yaw, :vel_x, :vel_y, :vel_z, :metadata
    
    def initialize entity_id = 0, type = 0, x = 0.0, y = 0.0, z = 0.0, pitch = 0, head_pitch = 0, yaw = 0, vel_x = 0, vel_y = 0, vel_z = 0, metadata = RMCCLib::EntityMetadata.new
      super 0x18
      @entity_id = entity_id
      @type = type
      @x = x
      @y = y
      @z = z
      @pitch = pitch
      @head_pitch = head_pitch
      @yaw = yaw
      @vel_x = vel_x
      @vel_y = vel_y
      @vel_z = vel_z
      @metadata = metadata
    end
    
    def read socket
      @entity_id = socket.read_int
      @type = socket.read_byte
      @x = socket.read_abs_int
      @y = socket.read_abs_int
      @z = socket.read_abs_int
      @pitch = socket.read_byte
      @head_pitch = socket.read_byte
      @yaw = socket.read_byte
      @vel_x = socket.read_short
      @vel_y = socket.read_short
      @vel_z = socket.read_short
      
      @metadata = RMCCLib::EntityMetadata.new
      @metadata.read socket
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_byte @type
      socket.write_abs_int @x
      socket.write_abs_int @y
      socket.write_abs_int @z
      socket.write_byte @pitch
      socket.write_byte @head_pitch
      socket.write_byte @yaw
      socket.write_short @vel_x
      socket.write_short @vel_y
      socket.write_short @vel_z
      
      @metadata.write socket
    end
  end
end