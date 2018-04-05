module RMCCLib::Entities
  class OtherPlayer < Entity
    attr_accessor :name, :current_item
    
    def initialize world, entity_id, x = 0.0, y = 0.0, z = 0.0, yaw = 0, pitch = 0, head_pitch = 0, metadata = EntityMetadata.new, name = "", held_item = 0
      super world, entity_id, x, y, z, yaw, pitch, head_pitch, metadata
      @name = name
      @current_item = current_item
    end
  end
end
