module RMCCLib::Packets
  class Packet06SpawnPosition < Packet
    attr_reader :x, :y, :z
  
    def initialize x = 0, y = 0, z = 0
      super 0x06
      @x = x
      @y = y
      @z = z
    end
    
    def read socket
      @x = socket.read_int
      @y = socket.read_int
      @z = socket.read_int
    end
        
    def write socket
      socket.write_ubyte @id.chr
      @socket.write_int @x
      @socket.write_int @y
      @socket.write_int @z
    end
  end
end