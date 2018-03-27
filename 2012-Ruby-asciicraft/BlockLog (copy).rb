class BlockLog < Block
    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,5,0)
    end

    def getPixel
        return Pixel.new("#", 52, 124)
    end
end
