module RMCCLib::Packets
  class Packet0EPlayerDigging < Packet
    attr_reader :status, :x, :y, :z, :face
  
    def initialize status = 0, x = 0, y = 0, z = 0, face = 0
      super 0x0E
      @status = status
      @x = x
      @y = y
      @z = z
      @face = face
    end
    
    def read socket
      @status = socket.read_byte
      @x = socket.read_int
      @y = socket.read_ubyte
      @z = socket.read_int
      @face = socket.read_ubyte
    end
    
    def write socket
      puts "dig"
      socket.write_ubyte @id
      socket.write_byte @status
      socket.write_int @x
      socket.write_ubyte @y
      socket.write_int @z
      socket.write_ubyte @face
    end
  end
end
