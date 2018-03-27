class BlockWater < Block
    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,7,5)
    end

    def getPixel
        return Pixel.new(" ", 39, 0)
    end

	def noclip?
		return true
	end

	def tick
		@metadata -= 1

		if @metadata < 1 then
			@metadata = 5
			if @world.getBlock(@x-1,@y).class == BlockAir then
				@world.setBlock(@x-1, @y, BlockWater.new(@world, @x-1, @y))
			elsif @world.getBlock(@x+1,@y).class == BlockAir then
				@world.setBlock(@x+1, @y, BlockWater.new(@world, @x+1, @y))
			elsif @world.getBlock(@x,@y+1).class == BlockAir then
				@world.setBlock(@x, @y+1, BlockWater.new(@world, @x, @y+1))
			end
		end
	end
end
