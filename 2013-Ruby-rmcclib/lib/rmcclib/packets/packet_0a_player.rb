module RMCCLib::Packets
  class Packet0APlayer < Packet
    attr_reader :on_ground
  
    def initialize on_ground = false
      super 0x0A
      @on_ground = on_ground
    end
    
    def read socket
      @on_ground = socket.read_bool
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_bool @on_ground
    end
  end
end
