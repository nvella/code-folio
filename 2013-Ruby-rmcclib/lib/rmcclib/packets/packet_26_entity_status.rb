module RMCCLib::Packets
  class Packet26EntityStatus < Packet
    attr_reader :entity_id, :entity_status
  
    def initialize entity_id = 0, entity_status = 0
      super 0x26
      @entity_id = entity_id
      @entity_status = entity_status
    end
    
    def read socket
      @entity_id = socket.read_int
      @entity_status = socket.read_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_status @entity_status
    end
  end
end