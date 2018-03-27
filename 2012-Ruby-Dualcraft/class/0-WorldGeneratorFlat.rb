module Dualcraft
  class WorldGeneratorFlat
    def initialize(world)
      @world = world
      @oddeven = true
    end
    
    def generate(x)
      c = Chunk.new(@world)
      @oddeven = not(@oddeven)
      c.width.times do |x|
        c.blocks[x][0][0] = $dualcraft_blocks[rand(2) + 1].new(@world)
        c.blocks[x][1][0] = $dualcraft_blocks[rand(2) + 1].new(@world)
      end
      return c
    end
  end
end
