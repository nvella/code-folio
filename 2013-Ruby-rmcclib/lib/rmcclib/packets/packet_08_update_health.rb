module RMCCLib::Packets
  class Packet08UpdateHealth < Packet
    attr_reader :health, :food, :food_saturation
  
    def initialize health = 0.0, food = 0, food_saturation = 0.0
      super 0x08
      @health = health
      @food = food
      @food_saturation = food_saturation
    end
    
    def read socket
      @health = socket.read_float
      @food = socket.read_short
      @food_saturation = socket.read_float
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_float @health
      socket.write_short @food
      socket.write_float @food_saturation
    end
  end
end
