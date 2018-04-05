module RMCCLib::Packets
  class Packet12Animation < Packet
    attr_reader :entity_id, :animation_id
  
    def initialize entity_id = 0, animation_id = 0
      super 0x12
      @entity_id = 0
      @animation_id = 0
    end
    
    def read socket
      @entity_id = socket.read_int
      @animation_id = socket.read_ubyte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_ubyte @animation_id
    end
  end
end