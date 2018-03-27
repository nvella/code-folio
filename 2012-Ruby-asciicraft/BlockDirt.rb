class BlockDirt < Block
    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,3,0)
    end

    def getPixel
        return Pixel.new(" ", 94, 0)
    end
end
