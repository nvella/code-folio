class BlockSpacetimeSnapshot < Block
	include BlockList

    def initialize(world,x,y,id=0,md=0)
        super(world,x,y,9,0)
    end
	
	def use(player)
		if @metadata == 0 then
			@metadata = StringToInteger.encode(@world.dataStore.length.to_s)
			@world.dataStore[StringToInteger.decode(@metadata).to_i] = [false]
		end

		blockState = @world.dataStore[StringToInteger.decode(@metadata).to_i]
		if blockState[0] then
			@world.time = blockState[2]
			@world.blockTable = restoreBlockTable(blockState[1])
		else
			blockState[0] = true
			blockState[1] = convertBlockTable(@world.blockTable)
			blockState[2] = @world.time
			@world.dataStore[StringToInteger.decode(@metadata).to_i] = blockState
		end	
	end

	def canBeUsed?
		return true
	end

	def convertBlockTable(table)
		out = []
		@world.width.times do |x|
			out[x] = []
			@world.height.times do |y|
				out[x][y] = []
				out[x][y][0] = table[x][y].id
				out[x][y][1] = table[x][y].metadata
			end
		end
		return out
	end

	def restoreBlockTable(table)
		out = []
		@world.width.times do |x|
			out[x] = []
			@world.height.times do |y|
				out[x][y] = getBlockForID(table[x][y][0]).new(@world, x, y)
				out[x][y].setMetadata(table[x][y][1])
			end
		end
		return out
	end

    def getPixel
        return Pixel.new("!", 15, 196)
    end
end
