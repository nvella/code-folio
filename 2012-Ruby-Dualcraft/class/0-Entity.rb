module Dualcraft
  class Entity
    attr_accessor :data
    def initialize(world, id)
      @world = world
      @data = {}
      @data["id"] = id
      @data["posX"] = 0.0
      @data["posY"] = 0.0
      @data["posZ"] = 0.0
      @data["velX"] = 0.0
      @data["velY"] = 0.0
      @effects = []
    end
    
    def do_effects
      @effects.each {|effect| effect.update}
    end

    def update
    end
    
    def texture
    end
  end
end
      
