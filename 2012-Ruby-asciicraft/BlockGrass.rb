class BlockGrass < Block
    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,2,300 + rand(300))
    end

	def tick
		@metadata -= 1
		if not @world.getBlock(@x,@y - 1).noclip? then @world.setBlock(@x,@y, BlockDirt.new(@world,@x,@y)) end
		if @metadata < 1 then
			@metadata = 300 + rand(300)
			tryToSpread(@x - 1, @y)
			tryToSpread(@x + 1, @y)
			tryToSpread(@x - 1, @y + 1)
			tryToSpread(@x + 1, @y + 1)
			tryToSpread(@x - 1, @y - 1)
			tryToSpread(@x + 1, @y - 1)
			tryToSpread(@x, @y + 2)
		end
	end

	def tryToSpread(x,y)
		if @world.getBlock(x,y - 1).noclip? and @world.getBlock(x,y).class == BlockDirt then
			@world.setBlock(x,y,BlockGrass.new(@world,x,y))
		end
	end

    def getPixel
        return Pixel.new("=", 2, 7)
    end

	def getDrop
		return BlockDirt.new(@world, 0,0)
	end
end
