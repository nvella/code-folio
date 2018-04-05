module RMCCLib::Packets
  class Packet10HeldItemChange < Packet
    attr_reader :slot_id
    
    def initialize slot_id = 0
      super 0x10
      @slot_id = slot_id
    end
    
    def read socket
      @slot_id = socket.read_short
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_short @slot_id
    end
  end
end