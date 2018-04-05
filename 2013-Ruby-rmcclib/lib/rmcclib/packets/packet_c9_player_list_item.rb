module RMCCLib::Packets
  class PacketC9PlayerListItem < Packet
    attr_reader :player_name, :online, :ping
    
    def initialize player_name = "", online = false, ping = 0
      super 0xC9
      @player_name = player_name
      @online = online
      @ping = ping
    end
    
    def read socket
      @player_name = socket.read_string
      @online = socket.read_bool
      @ping = socket.read_short
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_string @player_name
      socket.write_bool @online
      socket.write_short @ping
    end
  end
end