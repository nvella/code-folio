class BlockLeaves < Block
    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,6,80 + rand(40))
    end

    def getPixel
        return Pixel.new("#", @world.getForegroundColour, 28)
    end

	def tick
		gotWood = false
		startX = @x-4
		startY = @y-4
		9.times do |x|
			9.times do |y|
				if @world.getBlock(x + startX, y + startY).class == BlockLog then gotWood = true end
			end
		end
		if not gotWood then
			@metadata -= 1
			if @metadata < 1 then @world.setBlock(@x,@y,BlockAir.new(@world, @x, @y)) end
		end
	end

	def getDrop 
	end
end
