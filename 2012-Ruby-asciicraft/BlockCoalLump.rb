class BlockCoalLump < Block
    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,3,0)
    end

    def getPixel
        return Pixel.new("*", 0, 255)
    end
end
