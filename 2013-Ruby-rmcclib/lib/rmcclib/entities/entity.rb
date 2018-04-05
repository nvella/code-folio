module RMCCLib::Entities
  class Entity
    attr_accessor :world, :entity_id, :position, :yaw, :pitch, :head_pitch, :velocity, :health, :metadata
  
    def initialize world, entity_id, x = 0.0, y = 0.0, z = 0.0, yaw = 0, pitch = 0, head_pitch = 0, vel_x = 0, vel_y = 0, vel_z = 0, health = 0.0, metadata = RMCCLib::EntityMetadata.new
      @world = world
      @entity_id = entity_id
      @position = [x.to_f, y.to_f, z.to_f]
      @yaw = yaw
      @pitch = pitch
      @head_pitch = head_pitch
      @velocity = [vel_x, vel_y, vel_z]
      @metadata = metadata
      @health = health
    end
    
    def x
      @position[0]
    end
    
    def y
      @position[1]
    end
    
    def z
      @position[2]
    end  
    
    def x= x
      @position[0] = x
    end     
    
    def y= y
      @position[1] = y
    end     
    
    def z= z
      @position[2] = z
    end     
  end
end
