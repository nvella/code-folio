module RMCCLib::Packets
  class Packet23EntityHeadLook < Packet
    attr_reader :entity_id, :head_yaw
    
    def initialize entity_id = 0, head_yaw = 0
      super 0x23
      @entity_id = entity_id
      @head_yaw = head_yaw
    end
    
    def read socket
      @entity_id = socket.read_int
      @head_yaw = socket.read_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_byte @head_yaw
    end
  end
end
