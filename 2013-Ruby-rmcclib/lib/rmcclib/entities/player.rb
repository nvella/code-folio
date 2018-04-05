module RMCCLib::Entities
  class Player < Entity # This class is only for the player controlled by this lib
    attr_accessor :stance, :game_mode, :on_ground, :started, :food, :food_saturation, :experience, :levels
  
    def initialize server, world, entity_id, x, y, z, yaw, pitch, head_pitch, vel_x, vel_y, vel_z, on_ground, game_mode, stance, food = 0, food_saturation = 0.0, experience = 0, levels = 0
      super world, entity_id, x, y, z, yaw, pitch, head_pitch, vel_x, vel_y, vel_z
      @server = server
      @game_mode = game_mode
      @on_ground = on_ground
      @stance = stance
      @food = food
      @food_saturation = food_saturation
          
      @experience = 0
      @levels = 0
      
      @started = false
    end
    
    def say message
      @server.connection.send_packet RMCCLib::Packets::Packet03ChatMessage.new message
    end
    
    def respawn
      if @health <= 0.0 then
        @server.connection.send_packet RMCCLib::Packets::PacketCDClientStatuses.new RMCCLib::Packets::CLIENT_STATUS_RESPAWN
      else
        raise "cannot respawn when not dead"
      end
    end
    
    def break_block x, y, z
      say 'digging'
      @server.connection.send_packet RMCCLib::Packets::Packet0EPlayerDigging.new(0, x, y, z, 1)
      @server.connection.send_packet RMCCLib::Packets::Packet12Animation.new(@entity_id, 1)
      @server.connection.send_packet RMCCLib::Packets::Packet0EPlayerDigging.new(2, x, y, z, 1)
    end
    
    def drop_item
      @server.connection.send_packet RMCCLib::Packets::Packet0EPlayerDigging.new(4, 0, 0, 0, 0)
    end
    
    def update
      b = @world.get_block(@position[0].floor, @position[1].floor, @position[2].floor)
      if b != nil and b.id == 0 then
        @on_ground = false
      else
        @on_ground = true
      end
      
      if not @on_ground then
        @position[1] -= 0.2
      end
      
      @stance = @position[1] + 1.62
    end
  end
end
