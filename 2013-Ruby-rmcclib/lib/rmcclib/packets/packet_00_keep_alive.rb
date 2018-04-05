module RMCCLib::Packets
  class Packet00KeepAlive < Packet
    attr_reader :random_id
  
    def initialize random_id = 0
      super 0x00
      @random_id = random_id
    end
    
    def read socket
      @random_id = socket.read_int
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @random_id
    end
  end
end