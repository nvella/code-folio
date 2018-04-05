module RMCCLib::Packets
  class Packet0DPlayerPositionLook < Packet
    attr_reader :x, :y, :z, :stance, :yaw, :pitch, :on_ground
    
    def initialize x = 0.0, y = 0.0, z = 0.0, stance = 0.0, yaw = 0.0, pitch = 0.0, on_ground = true
      @id = 0x0D
      @x = x.to_f
      @y = y.to_f
      @z = z.to_f
      @stance = stance.to_f
      @yaw = yaw.to_f
      @pitch = pitch.to_f
      @on_ground = on_ground
    end
    
    def read socket
      @x = socket.read_double
      @y = socket.read_double
      @stance = socket.read_double
      @z = socket.read_double
      @yaw = socket.read_float #+ 8
      @pitch = socket.read_float #+ 8
      @on_ground = socket.read_bool
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_double @x
      socket.write_double @y
      socket.write_double @stance
      socket.write_double @z
      socket.write_float @yaw
      socket.write_float @pitch
      socket.write_bool @on_ground
    end
  end
end
