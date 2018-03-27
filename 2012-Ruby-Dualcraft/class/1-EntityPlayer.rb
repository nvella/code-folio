module Dualcraft
  class EntityPlayer < Entity
    def initialize(world)
      super(world, 0)
      @effects.push(EntityEffectMovement.new(@world, self), EntityEffectGravity.new(@world, self))
    end
    
    def update
      256.times do |y|
        if @world.get_block(@data["posX"], y, 0) != nil then 
          @data["posY"] = y  
        end
      end      
    end
  end
end

$dualcraft_entities[0] = Dualcraft::EntityPlayer
