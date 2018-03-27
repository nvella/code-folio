class Block
    attr_reader :id, :x, :y, :metadata, :mass

    def initialize(world,x,y,id,md)
        @x = x
        @y = y
        @id = id
        @world = world
        @metadata = md
        @mass = 0
    end
    
    def setPosition(x,y)
        @x = x
        @y = y
    end
    
    def setMetadata(meta)
        @metadata = meta
    end
    
    def noclip?
        return false
    end

    def getDrop
        return self
    end
    
    def tick
        
    end

    def canBreak?
        return true
    end

    def canBeUsed?
        return false
    end
    
    def getAreaMass
        aMass = 0
        16.times do |x|
            16.times do |y|
                
            end
        end       
        
        return aMass
    end
    
    def distanceFrom(block)
        dis = 0
        if block.x - @x >= 0 then
            
        else
            
        end
    end
end
