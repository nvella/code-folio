class BlockMissingblo
	def getPixel
		return Pixel.new(" ", 0, 7)
	end

	def x
		return 0
	end

	def y
		return 0
	end
    
	def id
		return 0
	end

    def noclip?
        return true
    end

	def canBreak?
		return false
	end

	def tick

	end

	def setPosition(x,y)

	end
end
