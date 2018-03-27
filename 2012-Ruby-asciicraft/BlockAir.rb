class BlockAir < Block
    def initialize(world,x,y,id=0,md=0)
		super(world,x,y,0,md)
    end

    def getPixel
		if @world.time > 5400 and @metadata == 1 then 		
			return Pixel.new("*", @world.getForegroundColour, 7)
		else
			return Pixel.new(" ", @world.getForegroundColour, 0)
		end
    end
    
    def noclip?
        return true
    end
end
