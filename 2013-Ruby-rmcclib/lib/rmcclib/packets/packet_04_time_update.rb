module RMCCLib::Packets
  class Packet04TimeUpdate < Packet
    attr_reader :age, :time
    
    def initialize age = 0, time = 0
      super 0x04
      @age = age
      @time = time
    end
    
    def read socket
      @age = socket.read_long
      @time = socket.read_long
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_long @age
      socket.write_long @time
    end
  end
end