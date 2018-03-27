class EntityPig < Entity
	def initialize(ac)
		super(ac)
	end
	
	def tick
	
	end
	
	def getPixel
		return Pixel.new("p", 207, 7)
    end
end
