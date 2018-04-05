module RMCCLib::Packets
  class Packet14SpawnNamedEntity < Packet
    attr_reader :entity_id, :entity_name, :x, :y, :z, :yaw, :pitch, :current_item, :metadata
  
    def initialize entity_id = 0, entity_name = "", x = 0.0, y = 0.0, z = 0.0, yaw = 0, pitch = 0, current_item = 0, metadata = RMCCLib::EntityMetadata.new
      super 0x14
      @entity_id = entity_id
      @entity_name = entity_name
      @x = x
      @y = y
      @z = z
      @yaw = yaw
      @pitch = pitch
      @current_item = current_item
      @metadata = metadata
    end
    
    def read socket
      @entity_id = socket.read_int
      @entity_name = socket.read_string
      @x = socket.read_abs_int
      @y = socket.read_abs_int
      @z = socket.read_abs_int
      @yaw = socket.read_byte
      @pitch = socket.read_byte
      @current_item = socket.read_short
      @metadata = RMCCLib::EntityMetadata.new
      
      @metadata.read socket
    end
    
    # TODO: implement writing after EntityMetadata#write is implemented.
  end
end