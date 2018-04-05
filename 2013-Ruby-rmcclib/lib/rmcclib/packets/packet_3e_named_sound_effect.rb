module RMCCLib::Packets
  class Packet3ENamedSoundEffect < Packet
    attr_reader :sound_name, :x, :y, :z, :volume, :pitch
    
    def initialize sound_name = "", x = 0.0, y = 0.0, z = 0.0, volume = 0.0, pitch = 0
      super 0x1F
      @sound_name = sound_name
      @x = x
      @y = y
      @z = z
      @volume = volume
      @pitch = pitch
    end
    
    def read socket
      @sound_name = socket.read_string
      @x = socket.read_int / 8.0
      @y = socket.read_int / 8.0
      @z = socket.read_int / 8.0
      @volume = socket.read_float
      @pitch = socket.read_byte
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_string @sound_name
      socket.write_int(@x * 8)
      socket.write_int(@x * 8)
      socket.write_int(@x * 8)
      socket.write_float @volume
      socket.write_byte @pitch
    end
  end
end
