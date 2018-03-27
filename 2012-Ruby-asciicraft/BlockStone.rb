class BlockStone < Block
    def initialize(ac,x,y,id=0,md=0)
        super(ac,x,y,1,0)
    end

    def getPixel
        return Pixel.new(" ", 243, 0)
    end
end
