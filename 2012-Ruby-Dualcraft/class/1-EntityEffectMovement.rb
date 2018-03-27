module Dualcraft
  class EntityEffectMovement < EntityEffect
    def initialize(world, entity)
      super(world, entity)
    end

    def update
      @entity.data["posX"] += @entity.data["velX"]
      @entity.data["posY"] += @entity.data["velY"]
    end
  end
end
