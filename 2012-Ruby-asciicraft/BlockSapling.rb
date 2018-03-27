class BlockSapling < Block
    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,8,80 + rand(40))
    end

    def getPixel
        return Pixel.new("$", @world.getForegroundColour, 94)
    end

	def tick
		@metadata -= 1
		if @metadata < 1 then
			if not LandscapeGenPieceTree.new(@world, @x - 4, @y).print then @metadata = 80 + rand(40) end
		end
	end
end
