module Dualcraft
  class Block
    attr_accessor :world, :md, :light_level
    attr_reader :id, :light_emittance, :texture
  
    def initialize(world, id, md, texture, light_emittance = 0)
      @world = world
      @id = id
      @md = md
      @light_emittance = light_emittance #light emittance
      @light_level = 0
      @texture = texture
    end
    
    def update
    end
  end
end 
