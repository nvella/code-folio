module RMCCLib::Packets
  class Packet46ChangeGameState < Packet
    attr_reader :reason, :game_mode
    
    def initialize reason = 0, game_mode = 0
      super 0x46
      @reason = reason
      @game_mode = game_mode
    end
    
    def read socket
      @reason = socket.read_byte
      @game_mode = socket.read_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_byte @reason
      socket.write_byte @game_mode
    end
  end
end