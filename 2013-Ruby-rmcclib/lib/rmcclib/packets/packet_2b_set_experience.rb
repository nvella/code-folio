module RMCCLib::Packets
  class Packet2BSetExperience < Packet
    attr_reader :experience_bar, :levels, :experience
  
    def initialize experience_bar = 0.0, levels = 0, experience = 0
      super 0x2B
      @experience_bar = experience_bar
      @levels = levels
      @experience = experience
    end
    
    def read socket
      @experience_bar = socket.read_float
      @levels = socket.read_short
      @experience = socket.read_short
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_float @experience_bar
      socket.write_short @levels
      socket.write_short @experience
    end
  end
end
