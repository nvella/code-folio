module RMCCLib::Packets
  class Packet17SpawnObjectVehicle < Packet
    attr_reader :entity_id, :type, :x, :y, :z, :pitch, :yaw
    
    def initialize entity_id = 0, type = 0, x = 0.0, y = 0.0, z = 0.0, pitch = 0, yaw = 0, object_data = RMCCLib::ObjectData.new
      super 0x17
      @entity_id = entity_id
      @type = type
      @x = x
      @y = y
      @z = z
      @pitch = pitch
      @yaw = yaw
      @object_data = object_data
    end
    
    def read socket
      @entity_id = socket.read_int
      @type = socket.read_byte
      @x = socket.read_abs_int
      @y = socket.read_abs_int
      @z = socket.read_abs_int
      @pitch = socket.read_byte
      @yaw = socket.read_byte
      
      @object_data = RMCCLib::ObjectData.new
      @object_data.read socket
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_byte @type
      socket.write_abs_int @x
      socket.write_abs_int @y
      socket.write_abs_int @z
      socket.write_byte @pitch
      socket.write_byte @yaw
      
      @object_data.write socket
    end
  end
end
