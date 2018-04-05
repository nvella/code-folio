module RMCCLib::Packets
  class Packet09Respawn < Packet
    attr_reader :dimension, :difficulty, :game_mode, :world_height, :level_type
  
    def initialize dimension = 0, difficulty = 0, game_mode = 0, world_height = 256, level_type = "DEFAULT"
      super 0x09
      @dimension = dimension
      @difficulty = difficulty
      @game_mode = game_mode
      @world_height = world_height
      @level_type = level_type
    end
    
    def read socket
      @dimension = socket.read_int
      @difficulty = socket.read_byte
      @game_mode = socket.read_byte
      @world_height = socket.read_short
      @level_type = socket.read_string
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @dimension
      socket.write_byte @difficulty
      socket.write_byte @game_mode
      socket.write_short @world_height
      socket.write_string @level_type
    end
  end
end
