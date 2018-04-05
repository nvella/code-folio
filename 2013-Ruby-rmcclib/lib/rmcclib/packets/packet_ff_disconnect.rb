module RMCCLib::Packets
  class PacketFFDisconnect < Packet
    attr_reader :reason
    
    def initialize reason = ""
      super 0xFF
      @reason = reason
    end
    
    def read socket
      @reason = socket.read_string
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_string @reason
    end
  end
end
