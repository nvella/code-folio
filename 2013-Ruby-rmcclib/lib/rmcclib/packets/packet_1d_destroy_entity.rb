module RMCCLib::Packets
  class Packet1DDestroyEntity < Packet
    attr_reader :entity_ids
  
    def initialize entity_ids = []
      super 0x1D
      @entity_ids = entity_ids
    end
    
    def read socket
      @entity_ids = []
      socket.read_byte.times do
        @entity_ids.push socket.read_int
      end
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_ubyte @entity_ids.length
      @entity_ids.length do |id|
        socket.write_int id
      end
    end
  end
end