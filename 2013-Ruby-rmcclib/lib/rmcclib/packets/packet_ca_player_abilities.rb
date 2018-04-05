module RMCCLib::Packets
  class PacketCAPlayerAbilities < Packet
    attr_reader :god_mode, :can_fly, :flying, :creative, :flying_speed, :walking_speed
  
    def initialize god_mode = false, can_fly = false, flying = false, creative = false, flying_speed = 0.0, walking_speed = 0.0
      super 0xCA
      @god_mode = god_mode
      @can_fly = can_fly
      @flying = flying
      @creative = creative
      @flying_speed = flying_speed
      @walking_speed = walking_speed
    end
    
    def read socket
      flags = socket.read_byte
      @god_mode = flags[3] == 1
      @flying = flags[2] == 1
      @can_fly = flags[1] == 1
      @creative = flags[0] == 1
      @flying_speed = socket.read_float
      @walking_speed = socket.read_float
    end
        
    def write socket
      flags = 0
      if @creative then flags |= 1 end
      if @can_fly then flags |= 2 end
      if @flying then flags |= 4 end
      if @god_mode then flags |= 8 end
      
      socket.write_ubyte @id.chr      
      @socket.write_byte flags
      @socket.write_float @flying_speed
      @socket.write_float @walking_speed
    end
  end
end