module RMCCLib::Packets
  class Packet28EntityMetadata < Packet
    attr_reader :entity_id, :metadata
    
    def initialize entity_id = 0, metadata = RMCCLib::EntityMetadata.new
      super 0x28
      @entity_id = entity_id
      @metadata = metadata
    end
    
    def read socket
      @entity_id = socket.read_int
      @metadata = RMCCLib::EntityMetadata.new
      @metadata.read socket
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      @metadata.write socket
    end
  end
end
