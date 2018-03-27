class LandscapeGenFlat
    def initialize(world)
		@world = world
    end
    
    def generate
        @world.width.times do |x|
			@world.setBlock(x, @world.height - 3, BlockGrass.new(@world, x, @world.height - 2))
			@world.setBlock(x, @world.height - 2, BlockStone.new(@world, x, @world.height - 2))
            @world.setBlock(x, @world.height - 1, BlockBedrock.new(@world, x, @world.height - 1))
        end

		@world.setSpawn(@world.rng.rand(@world.width), 124)
    end
end
