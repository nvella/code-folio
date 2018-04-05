module RMCCLib::Packets
  class Packet01LoginRequest < Packet
    attr_reader :entity_id, :level_type, :game_mode, :dimension, :difficulty, :max_players
  
    def initialize entity_id = 0, level_type = "default", game_mode = 0, dimension = 0, difficulty = 2, max_players = 0
      super 0x01
      @entity_id = entity_id
      @level_type = level_type
      @game_mode = game_mode
      @dimension = dimension
      @difficulty = difficulty
      @max_players = max_players
    end
    
    def read socket
      @entity_id = socket.read_int
      @level_type = socket.read_string
      @game_mode = socket.read_byte
      @dimension = socket.read_byte
      @difficulty = socket.read_byte
      socket.read_byte
      @max_players = socket.read_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_string @level_type
      socket.write_byte @game_mode
      socket.write_byte @dimension
      socket.write_byte @difficulty
      socket.write_byte 0
      socket.write_byte @max_players
    end
  end
end
