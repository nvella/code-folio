module RMCCLib::Packets
  CLIENT_STATUS_SPAWN = 0
  CLIENT_STATUS_RESPAWN = 1

  class PacketCDClientStatuses < Packet
    def initialize payload = 0
      super 0xCD
      @payload = payload
    end
    
    def read socket
      @payload = socket.read_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_byte @payload
    end
  end
end
