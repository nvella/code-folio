class Block
    attr_reader :id, :x, :y, :metadata

    def initialize(world,x,y,id,md)
        @x = x
        @y = y
        @id = id
        @world = world
        @metadata = md
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
end
