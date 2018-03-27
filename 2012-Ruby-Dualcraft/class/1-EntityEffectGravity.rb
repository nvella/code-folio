module Dualcraft
  class EntityEffectGravity < EntityEffect
    def initalize(world, entity)
      super(world, entity)
    end

    def update
      if @world.get_block(@entity.data["posX"].floor, @entity.data["posY"].floor, 0) == nil then
        if @entity.data["velY"] <= 0 then
          @entity.data["velY"] -= 0.016
        else
          @entity.data["velY"] -= @entity.data["velY"] * 1.5
        end
      else
        @entity.data["velY"] = 0
      end
    end
  end
end
