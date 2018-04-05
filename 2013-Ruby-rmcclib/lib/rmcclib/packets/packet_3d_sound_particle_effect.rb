module RMCCLib::Packets
  class Packet3DSoundParticleEffect < Packet
    attr_reader :effect_id, :x, :y, :z, :data, :disable_relative_volume
  
    def initialize effect_id = 0, x = 0, y = 0, z = 0, data = 0, disable_relative_volume = false
      super 0x3D
      @effect_id = effect_id
      @x = x
      @y = y
      @z = z
      @data = data
      @disable_relative_volume = disable_relative_volume
    end
    
    def read socket
      @effect_id = socket.read_int
      @x = socket.read_int
      @y = socket.read_ubyte
      @z = socket.read_int
      @data = socket.read_int
      @disable_relative_volume = socket.read_bool
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @effect_id
      socket.write_int @x
      socket.write_ubyte @y
      socket.write_int @z
      socket.write_int @data
      socket.write_bool @disable_relative_volume
    end
  end
end