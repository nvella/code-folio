class BlockBedrock < Block
    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,4,0)
    end

    def getPixel
        return Pixel.new("~", 0, 7)
    end

	def canBreak?
		return false
	end
end
